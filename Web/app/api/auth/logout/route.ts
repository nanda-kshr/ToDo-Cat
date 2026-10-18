import { NextResponse } from "next/server";
import { connectDB } from "@/lib/mongodb";
import { User } from "@/models/User";
import {
  verifyRefreshToken,
  getRefreshToken,
  clearRefreshTokenCookie,
} from "@/lib/auth";
import { invalidateTaskCache } from "@/lib/taskCache";

export async function POST(request: Request) {
  try {
    let fallbackToken: string | undefined;
    try {
      const body = await request.json();
      fallbackToken = body?.refreshToken;
    } catch {
      // Body is optional
    }

    const token = await getRefreshToken(fallbackToken);
    await clearRefreshTokenCookie();

    if (token) {
      try {
        const payload = verifyRefreshToken(token);
        await connectDB();

        if (payload?.userId) {
          invalidateTaskCache(payload.userId);
          await User.findByIdAndUpdate(payload.userId, {
            $pull: { refreshTokens: token },
          });
        } else {
          await User.updateOne(
            { refreshTokens: token },
            { $pull: { refreshTokens: token } }
          );
        }
      } catch (error) {
        console.error("Logout DB cleanup error:", error);
      }
    }

    return NextResponse.json({ message: "Logged out successfully" });
  } catch (error) {
    console.error("Logout error:", error);
    return NextResponse.json({ message: "Internal server error" }, { status: 500 });
  }
}
