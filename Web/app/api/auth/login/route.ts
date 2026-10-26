import { NextResponse } from "next/server";
import { connectDB } from "@/lib/mongodb";
import { User } from "@/models/User";
import {
  comparePassword,
  generateTokens,
  setRefreshTokenCookie,
} from "@/lib/auth";
import { checkRateLimit, getClientIp } from "@/lib/rateLimit";

export async function POST(request: Request) {
  try {
    const ip = getClientIp(request);
    const ipLimit = checkRateLimit(`login_ip:${ip}`, 10, 15 * 60);
    if (!ipLimit.allowed) {
      return NextResponse.json(
        { message: `Too many login attempts. Please try again in ${ipLimit.resetInSeconds} seconds.` },
        { status: 429 }
      );
    }

    const body = await request.json();
    const { email, password } = body || {};

    if (!email || typeof email !== "string" || !password || typeof password !== "string") {
      return NextResponse.json(
        { message: "Email and password are required" },
        { status: 400 }
      );
    }

    await connectDB();

    const normalizedEmail = email.toLowerCase().trim();
    const user = await User.findOne({ email: normalizedEmail });

    if (!user || !user.password) {
      return NextResponse.json(
        { message: "Invalid email or password" },
        { status: 401 }
      );
    }

    const isMatch = await comparePassword(password, user.password);
    if (!isMatch) {
      return NextResponse.json(
        { message: "Invalid email or password" },
        { status: 401 }
      );
    }

    const { accessToken, refreshToken } = generateTokens(user._id.toString());
    user.refreshTokens = [...(user.refreshTokens || []).slice(-9), refreshToken];
    await user.save();

    await setRefreshTokenCookie(refreshToken);

    return NextResponse.json({
      message: "Login successful",
      user: {
        id: user._id,
        email: user.email,
        name: user.name,
      },
      accessToken,
      refreshToken,
    });
  } catch (error) {
    console.error("Login error:", error);
    return NextResponse.json({ message: "Internal server error" }, { status: 500 });
  }
}
