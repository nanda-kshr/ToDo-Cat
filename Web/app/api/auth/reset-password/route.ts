import { NextResponse } from "next/server";
import { connectDB } from "@/lib/mongodb";
import { User } from "@/models/User";
import { checkRateLimit, getClientIp } from "@/lib/rateLimit";
import bcrypt from "bcryptjs";

export async function POST(request: Request) {
  try {
    const ip = getClientIp(request);

    // Rate limit: max 10 attempts per 15 minutes per IP
    const ipLimit = checkRateLimit(`reset_pw_ip:${ip}`, 10, 15 * 60);
    if (!ipLimit.allowed) {
      return NextResponse.json(
        { message: "Too many attempts from this IP. Please try again later." },
        { status: 429 }
      );
    }

    const body = await request.json();
    const { token, email, otp, newPassword } = body;

    if (!newPassword || typeof newPassword !== "string" || newPassword.length < 6) {
      return NextResponse.json(
        { message: "New password must be at least 6 characters long." },
        { status: 400 }
      );
    }

    await connectDB();
    const now = new Date();

    let user: InstanceType<typeof User> | null = null;

    if (token && typeof token === "string") {
      // 1. Link-based reset
      user = await User.findOne({
        resetPasswordToken: token.trim(),
        resetPasswordExpires: { $gt: now },
      });

      if (!user) {
        return NextResponse.json(
          { message: "Invalid or expired reset password link. Please request a new one." },
          { status: 400 }
        );
      }
    } else if (email && otp && typeof email === "string" && typeof otp === "string") {
      // 2. OTP-based reset
      const cleanEmail = email.trim().toLowerCase();
      user = await User.findOne({ email: cleanEmail });

      if (!user) {
        return NextResponse.json(
          { message: "Invalid email or OTP code." },
          { status: 400 }
        );
      }

      // Check expiry
      if (!user.resetPasswordExpires || user.resetPasswordExpires < now) {
        return NextResponse.json(
          { message: "OTP code has expired. Please request a new code." },
          { status: 400 }
        );
      }

      // Check max attempts
      if ((user.resetPasswordAttempts || 0) >= 5) {
        return NextResponse.json(
          { message: "Too many incorrect OTP attempts. Please request a new code." },
          { status: 429 }
        );
      }

      // Check OTP
      if (user.resetPasswordOtp !== otp.trim()) {
        user.resetPasswordAttempts = (user.resetPasswordAttempts || 0) + 1;
        await user.save();
        const remainingAttempts = 5 - user.resetPasswordAttempts;
        return NextResponse.json(
          { message: `Invalid OTP code. ${remainingAttempts} attempts remaining.` },
          { status: 400 }
        );
      }
    } else {
      return NextResponse.json(
        { message: "Either a valid token or email and OTP code must be provided." },
        { status: 400 }
      );
    }

    // Hash new password & clear reset state + refresh tokens
    const hashedPassword = await bcrypt.hash(newPassword, 12);
    user.password = hashedPassword;
    user.resetPasswordToken = undefined;
    user.resetPasswordOtp = undefined;
    user.resetPasswordExpires = undefined;
    user.resetPasswordAttempts = 0;
    user.refreshTokens = []; // Revoke active sessions for security

    await user.save();

    return NextResponse.json({
      message: "Password reset successful! You can now log in with your new password.",
    });
  } catch (error) {
    console.error("[Reset Password POST] Error:", error);
    return NextResponse.json({ message: "Internal server error" }, { status: 500 });
  }
}
