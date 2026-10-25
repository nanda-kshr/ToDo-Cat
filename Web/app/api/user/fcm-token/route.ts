import { NextResponse } from "next/server";
import { connectDB } from "@/lib/mongodb";
import { User } from "@/models/User";
import { getUserFromRequest } from "@/lib/auth";

export async function POST(request: Request) {
  try {
    const payload = getUserFromRequest(request);
    if (!payload?.userId) {
      return NextResponse.json({ message: "Unauthorized" }, { status: 401 });
    }

    const { token } = await request.json();
    if (!token || typeof token !== "string") {
      return NextResponse.json({ message: "Token is required" }, { status: 400 });
    }

    await connectDB();
    await User.findByIdAndUpdate(payload.userId, {
      $addToSet: { fcmTokens: token.trim() },
    });

    return NextResponse.json({ message: "FCM token registered" }, { status: 200 });
  } catch (error) {
    console.error("[FCM Token POST] Error:", error);
    return NextResponse.json({ message: "Internal server error" }, { status: 500 });
  }
}

export async function DELETE(request: Request) {
  try {
    const payload = getUserFromRequest(request);
    if (!payload?.userId) {
      return NextResponse.json({ message: "Unauthorized" }, { status: 401 });
    }

    const { token } = await request.json();
    if (!token || typeof token !== "string") {
      return NextResponse.json({ message: "Token is required" }, { status: 400 });
    }

    await connectDB();
    await User.findByIdAndUpdate(payload.userId, {
      $pull: { fcmTokens: token.trim() },
    });

    return NextResponse.json({ message: "FCM token removed" }, { status: 200 });
  } catch (error) {
    console.error("[FCM Token DELETE] Error:", error);
    return NextResponse.json({ message: "Internal server error" }, { status: 500 });
  }
}
