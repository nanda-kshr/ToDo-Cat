import { NextResponse } from "next/server";
import { connectDB } from "@/lib/mongodb";
import { User } from "@/models/User";
import { generateTokens, setRefreshTokenCookie } from "@/lib/auth";

export async function GET(request: Request) {
  const clientId = process.env.GOOGLE_CLIENT_ID;
  if (!clientId) {
    return NextResponse.json(
      { message: "Google OAuth is not configured: missing GOOGLE_CLIENT_ID" },
      { status: 500 }
    );
  }

  const { origin } = new URL(request.url);
  const redirectUri =
    process.env.OAUTH_REDIRECT_URI || `${origin}/api/auth/callback/google`;

  const params = new URLSearchParams({
    client_id: clientId,
    redirect_uri: redirectUri,
    response_type: "code",
    scope: "openid email profile",
    access_type: "offline",
    prompt: "consent",
  });

  const googleAuthUrl = `https://accounts.google.com/o/oauth2/v2/auth?${params.toString()}`;
  return NextResponse.redirect(googleAuthUrl);
}

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const {
      idToken,
      email: fallbackEmail,
      name: fallbackName,
      googleId: fallbackGoogleId,
      avatar: fallbackAvatar,
    } = body;

    let email = fallbackEmail;
    let name = fallbackName;
    let googleId = fallbackGoogleId;
    let avatar = fallbackAvatar;

    if (idToken) {
      try {
        const verifyRes = await fetch(
          `https://oauth2.googleapis.com/tokeninfo?id_token=${idToken}`
        );
        if (verifyRes.ok) {
          const payload = await verifyRes.json();
          email = payload.email || email;
          name = payload.name || name;
          googleId = payload.sub || googleId;
          avatar = payload.picture || avatar;
        }
      } catch (err) {
        console.error("Tokeninfo verification error:", err);
      }
    }

    if (!email) {
      return NextResponse.json(
        { message: "Invalid or missing Google credentials" },
        { status: 400 }
      );
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
      if (!user.googleId && googleId) user.googleId = googleId;
      if (!user.avatar && avatar) user.avatar = avatar;
      if (!user.name && name) user.name = name;
    }

    const { accessToken, refreshToken } = generateTokens(user._id.toString());
    user.refreshTokens = [...(user.refreshTokens || []).slice(-9), refreshToken];
    await user.save();

    await setRefreshTokenCookie(refreshToken);

    return NextResponse.json({
      accessToken,
      refreshToken,
      user: {
        id: user._id.toString(),
        email: user.email,
        name: user.name,
        avatar: user.avatar,
      },
    });
  } catch (error: unknown) {
    if ((error as { digest?: string })?.digest?.startsWith("NEXT_")) {
      throw error;
    }
    console.error("Google mobile auth error:", error);
    return NextResponse.json({ message: "Internal server error" }, { status: 500 });
  }
}
