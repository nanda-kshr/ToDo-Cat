import { NextResponse } from "next/server";
import { connectDB } from "@/lib/mongodb";
import { User } from "@/models/User";
import {
  verifyRefreshToken,
  generateTokens,
  getRefreshToken,
  setRefreshTokenCookie,
} from "@/lib/auth";

export async function POST(request: Request) {
  try {
    let fallbackToken: string | undefined;
    try {
      const body = await request.json();
      fallbackToken = body?.refreshToken;
    } catch {
      // Body is optional if cookie is sent
    }

    const token = await getRefreshToken(fallbackToken);
    if (!token) {
      return NextResponse.json(
        { message: "Refresh token is required" },
        { status: 401 }
      );
    }

    const payload = verifyRefreshToken(token);
    if (!payload?.userId) {
      return NextResponse.json(
        { message: "Invalid or expired refresh token" },
        { status: 401 }
      );
    }

    await connectDB();
    const user = await User.findById(payload.userId);
    if (!user) {
      return NextResponse.json({ message: "User not found" }, { status: 401 });
    }

    const tokenIndex = (user.refreshTokens || []).indexOf(token);
    if (tokenIndex === -1) {
      // RFC 6819 §5.2.2.3: Check grace window for recently rotated tokens
      // Allows parallel/in-flight requests from the same client to succeed without revoking the session
      const now = Date.now();
      const GRACE_PERIOD_MS = 60 * 1000; // 60 seconds grace window

      const graceMatch = (user.rotatedTokens || []).find(
        (rt: { token: string; rotatedAt: Date; newAccessToken: string; newRefreshToken: string }) =>
          rt.token === token && now - new Date(rt.rotatedAt).getTime() < GRACE_PERIOD_MS
      );

      if (graceMatch) {
        return NextResponse.json({
          message: "Token refreshed successfully (grace window)",
          accessToken: graceMatch.newAccessToken,
          refreshToken: graceMatch.newRefreshToken,
        });
      }

      return NextResponse.json(
        { message: "Refresh token is invalid or has been revoked" },
        { status: 403 }
      );
    }

    const { accessToken, refreshToken: newRefreshToken } = generateTokens(user._id.toString());

    // Record rotation in grace window (retaining only items from last 5 minutes, max 20)
    const now = Date.now();
    const activeRotated = (user.rotatedTokens || []).filter(
      (rt: { rotatedAt: Date }) => now - new Date(rt.rotatedAt).getTime() < 5 * 60 * 1000
    );
    activeRotated.push({
      token,
      newAccessToken: accessToken,
      newRefreshToken,
      rotatedAt: new Date(),
    });
    user.rotatedTokens = activeRotated.slice(-20);

    user.refreshTokens[tokenIndex] = newRefreshToken;
    await user.save();

    await setRefreshTokenCookie(newRefreshToken);

    return NextResponse.json({
      message: "Token refreshed successfully",
      accessToken,
      refreshToken: newRefreshToken,
    });
  } catch (error) {
    console.error("Refresh error:", error);
    return NextResponse.json({ message: "Internal server error" }, { status: 500 });
  }
}
