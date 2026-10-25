import { NextResponse } from "next/server";
import { connectDB } from "@/lib/mongodb";
import { User } from "@/models/User";
import { sendPasswordResetEmail } from "@/lib/email";
import { checkRateLimit, getClientIp } from "@/lib/rateLimit";
import crypto from "crypto";

export async function POST(request: Request) {
  try {
    const ip = getClientIp(request);

    // 1. Rate limit by IP: max 5 requests per 15 mins
    const ipLimit = checkRateLimit(`forgot_pw_ip:${ip}`, 5, 15 * 60);
    if (!ipLimit.allowed) {
      return NextResponse.json(
        { message: `Too many password reset requests from this IP. Please try again in ${Math.ceil(ipLimit.resetInSeconds / 60)} minutes.` },
        { status: 429 }
      );
    }

    const { email } = await request.json();
    if (!email || typeof email !== "string" || !email.includes("@")) {
      return NextResponse.json({ message: "A valid email is required" }, { status: 400 });
    }

    const cleanEmail = email.trim().toLowerCase();

    // 2. Rate limit by Email: max 1 request per 60 seconds (prevent mailbox bombing)
    const emailLimit = checkRateLimit(`forgot_pw_email:${cleanEmail}`, 1, 60);
    if (!emailLimit.allowed) {
      return NextResponse.json(
        { message: `Please wait ${emailLimit.resetInSeconds} seconds before requesting another reset code.` },
        { status: 429 }
      );
    }

    await connectDB();
    const user = await User.findOne({ email: cleanEmail });

    // Always return success message even if email is not found to prevent user enumeration
    if (!user) {
      return NextResponse.json({
        message: "If an account exists with this email, password reset instructions have been sent.",
      });
    }

    // Google-only users without passwords
    if (user.googleId && !user.password) {
      return NextResponse.json(
        { message: "This account was created with Google Sign-In. Please log in using Google." },
        { status: 400 }
      );
    }

    // Generate 6-digit OTP and secure link token
    const otp = crypto.randomInt(100000, 999999).toString();
    const token = crypto.randomBytes(32).toString("hex");
    const expires = new Date(Date.now() + 15 * 60 * 1000); // 15 mins

    user.resetPasswordToken = token;
    user.resetPasswordOtp = otp;
    user.resetPasswordExpires = expires;
    user.resetPasswordAttempts = 0;
    await user.save();

    // Determine reset link
    const origin = request.headers.get("origin");
    const host = request.headers.get("host");
    const proto = request.headers.get("x-forwarded-proto") || "https";
    const baseUrl = origin || (host ? `${proto}://${host}` : "https://todocat.instaroid.page");
    const resetLink = `${baseUrl}/reset-password?token=${token}`;

    sendPasswordResetEmail({
      toEmail: cleanEmail,
      userName: user.name,
      otp,
      resetLink,
    }).catch((err) => console.error("[Forgot Password] Email send error:", err));

    return NextResponse.json({
      message: "If an account exists with this email, password reset instructions have been sent.",
    });
  } catch (error) {
    console.error("[Forgot Password POST] Error:", error);
    return NextResponse.json(
      { message: error instanceof Error ? error.message : "Internal server error" },
      { status: 500 }
    );
  }
}
