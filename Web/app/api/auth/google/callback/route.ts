import { NextResponse } from "next/server";
import { connectDB } from "@/lib/mongodb";
import { User } from "@/models/User";
import { generateTokens, setRefreshTokenCookie } from "@/lib/auth";

function getDesktopCallbackUrl(stateParam: string | null): string | null {
  if (!stateParam) return null;
  try {
    const decoded = Buffer.from(stateParam, "base64url").toString("utf-8");
    const parsed = JSON.parse(decoded);
    const port = Number(parsed.port);
    if (Number.isInteger(port) && port >= 1024 && port <= 65535) {
      return `http://127.0.0.1:${port}/auth-callback`;
    }
  } catch (_) {}
  return null;
}

export async function GET(request: Request) {
  const url = new URL(request.url);
  const code = url.searchParams.get("code");
  const error = url.searchParams.get("error");
  const desktopCallback = getDesktopCallbackUrl(url.searchParams.get("state"));

  if (error || !code) {
    if (desktopCallback) {
      return NextResponse.redirect(
        new URL(`${desktopCallback}?error=${encodeURIComponent(error || "access_denied")}`)
      );
    }
    return NextResponse.redirect(
      new URL(`/auth?error=${encodeURIComponent(error || "access_denied")}`, url.origin)
    );
  }

  const clientId = process.env.OAUTH_CLIENT_ID || process.env.GOOGLE_CLIENT_ID;
  const clientSecret =
    process.env.OAUTH_CLIENT_SECRET ||
    process.env.GOOGLE_CLIENT_SECRET ||
    process.env.OAUTH_SECRET;

  if (!clientId || !clientSecret) {
    console.error("OAuth configuration missing:", {
      hasClientId: Boolean(clientId),
      hasClientSecret: Boolean(clientSecret),
    });
    if (desktopCallback) {
      return NextResponse.redirect(
        new URL(`${desktopCallback}?error=oauth_not_configured`)
      );
    }
    return NextResponse.redirect(new URL("/auth?error=oauth_not_configured", url.origin));
  }

  const redirectUri =
    process.env.OAUTH_REDIRECT_URI || `${url.origin}${url.pathname}`;

  try {
    const tokenRes = await fetch("https://oauth2.googleapis.com/token", {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({
        code,
        client_id: clientId,
        client_secret: clientSecret,
        redirect_uri: redirectUri,
        grant_type: "authorization_code",
      }),
    });

    if (!tokenRes.ok) {
      const errData = await tokenRes.text();
      console.error("Google token exchange error:", errData);
      if (desktopCallback) {
        return NextResponse.redirect(
          new URL(`${desktopCallback}?error=token_exchange_failed`)
        );
      }
      return NextResponse.redirect(new URL("/auth?error=token_exchange_failed", url.origin));
    }

    const tokenData = await tokenRes.json();
    const googleAccessToken = tokenData.access_token;

    const profileRes = await fetch("https://www.googleapis.com/oauth2/v3/userinfo", {
      headers: { Authorization: `Bearer ${googleAccessToken}` },
    });

    if (!profileRes.ok) {
      if (desktopCallback) {
        return NextResponse.redirect(
          new URL(`${desktopCallback}?error=profile_fetch_failed`)
        );
      }
      return NextResponse.redirect(new URL("/auth?error=profile_fetch_failed", url.origin));
    }

    const profile = await profileRes.json();
    const { sub: googleId, email, name, picture: avatar } = profile;

    if (!email) {
      if (desktopCallback) {
        return NextResponse.redirect(
          new URL(`${desktopCallback}?error=email_not_provided`)
        );
      }
      return NextResponse.redirect(new URL("/auth?error=email_not_provided", url.origin));
    }

    await connectDB();

    const normalizedEmail = email.toLowerCase().trim();
    let user = await User.findOne({
      $or: [{ googleId }, { email: normalizedEmail }],
    });

    if (!user) {
      user = new User({
        email: normalizedEmail,
        name,
        googleId,
        avatar,
      });
    } else {
      if (googleId) user.googleId = googleId;
      if (avatar) user.avatar = avatar;
      if (name && !user.name) user.name = name;
    }

    const { accessToken, refreshToken } = generateTokens(user._id.toString());
    user.refreshTokens = [...(user.refreshTokens || []).slice(-9), refreshToken];
    await user.save();

    await setRefreshTokenCookie(refreshToken);

    if (desktopCallback) {
      return NextResponse.redirect(
        new URL(`${desktopCallback}?token=${accessToken}&refreshToken=${refreshToken}`)
      );
    }

    return NextResponse.redirect(new URL(`/dashboard?token=${accessToken}`, url.origin));
  } catch (err) {
    console.error("Google callback error:", err);
    if (desktopCallback) {
      return NextResponse.redirect(
        new URL(`${desktopCallback}?error=internal_error`)
      );
    }
    return NextResponse.redirect(new URL("/auth?error=internal_error", url.origin));
  }
}
