import { NextResponse } from "next/server";
import { connectDB } from "@/lib/mongodb";
import { User } from "@/models/User";
import {
  hashPassword,
  generateTokens,
  setRefreshTokenCookie,
} from "@/lib/auth";
import { checkRateLimit, getClientIp } from "@/lib/rateLimit";

export async function POST(request: Request) {
  try {
    const ip = getClientIp(request);
    const ipLimit = checkRateLimit(`register_ip:${ip}`, 5, 60 * 60);
    if (!ipLimit.allowed) {
      return NextResponse.json(
        { message: `Too many accounts registered from this IP. Please try again in ${Math.ceil(ipLimit.resetInSeconds / 60)} minutes.` },
        { status: 429 }
      );
    }

    const body = await request.json();
    const { email, password, name } = body || {};

    if (!email || typeof email !== "string" || !password || typeof password !== "string") {
      return NextResponse.json(
        { message: "Email and password are required" },
        { status: 400 }
      );
    }

    if (password.length < 6) {
      return NextResponse.json(
        { message: "Password must be at least 6 characters long" },
        { status: 400 }
      );
    }

    await connectDB();

    const normalizedEmail = email.toLowerCase().trim();
    const existingUser = await User.findOne({ email: normalizedEmail });

    if (existingUser) {
      return NextResponse.json(
        { message: "User with this email already exists" },
        { status: 409 }
      );
    }

    const hashedPassword = await hashPassword(password);
    const user = new User({
      email: normalizedEmail,
      password: hashedPassword,
      name: typeof name === "string" ? name.trim() : undefined,
    });

    const { accessToken, refreshToken } = generateTokens(user._id.toString());
    user.refreshTokens = [refreshToken];
    await user.save();

    await setRefreshTokenCookie(refreshToken);

    return NextResponse.json(
      {
        message: "Registration successful",
        user: {
          id: user._id,
          email: user.email,
          name: user.name,
        },
        accessToken,
        refreshToken,
      },
      { status: 201 }
    );
  } catch (error) {
    console.error("Register error:", error);
    return NextResponse.json({ message: "Internal server error" }, { status: 500 });
  }
}
