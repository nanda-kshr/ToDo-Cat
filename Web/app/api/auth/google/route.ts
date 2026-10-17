import { NextResponse } from "next/server";

export async function GET(request: Request) {
  const clientId = process.env.OAUTH_CLIENT_ID || process.env.GOOGLE_CLIENT_ID;
  if (!clientId) {
    return NextResponse.json(
      { message: "Google OAuth is not configured: missing OAUTH_CLIENT_ID" },
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
