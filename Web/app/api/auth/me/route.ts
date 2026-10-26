import { NextResponse } from "next/server";
import { connectDB } from "@/lib/mongodb";
import { User } from "@/models/User";
import { getUserFromRequest } from "@/lib/auth";

export async function GET(request: Request) {
  try {
    const payload = getUserFromRequest(request);
    if (!payload?.userId) {
      return NextResponse.json(
        { message: "Unauthorized: Invalid or missing access token" },
        { status: 401 }
      );
    }

    await connectDB();
    const user = await User.findById(payload.userId).select("-password -refreshTokens");
    if (!user) {
      return NextResponse.json({ message: "User not found" }, { status: 404 });
    }

    const userObj = (user.toObject ? user.toObject() : user) as unknown as Record<string, unknown>;
    userObj.isProfilePublic = Boolean(userObj.isProfilePublic);

    return NextResponse.json({ user: userObj });
  } catch (error: unknown) {
    if ((error as { digest?: string })?.digest?.startsWith("NEXT_")) {
      throw error;
    }
    console.error("Auth me error:", error);
    return NextResponse.json({ message: "Internal server error" }, { status: 500 });
  }
}

export async function PATCH(request: Request) {
  try {
    const payload = getUserFromRequest(request);
    if (!payload?.userId) {
      return NextResponse.json(
        { message: "Unauthorized: Invalid or missing access token" },
        { status: 401 }
      );
    }

    const body = await request.json();
    await connectDB();

    const updateFields: Record<string, unknown> = {};
    if (typeof body.name === "string") {
      updateFields.name = body.name.trim();
    }
    if (typeof body.isProfilePublic === "boolean") {
      updateFields.isProfilePublic = body.isProfilePublic;
    }

    const user = await User.findByIdAndUpdate(
      payload.userId,
      { $set: updateFields },
      { new: true, strict: false }
    ).select("-password -refreshTokens");

    if (!user) {
      return NextResponse.json({ message: "User not found" }, { status: 404 });
    }

    const userObj = (user.toObject ? user.toObject() : user) as unknown as Record<string, unknown>;
    userObj.isProfilePublic = Boolean(userObj.isProfilePublic);

    return NextResponse.json({ user: userObj });
  } catch (error: unknown) {
    if ((error as { digest?: string })?.digest?.startsWith("NEXT_")) {
      throw error;
    }
    console.error("Update profile error:", error);
    return NextResponse.json({ message: "Internal server error" }, { status: 500 });
  }
}

export async function DELETE(request: Request) {
  try {
    const payload = getUserFromRequest(request);
    if (!payload?.userId) {
      return NextResponse.json(
        { message: "Unauthorized: Invalid or missing access token" },
        { status: 401 }
      );
    }

    await connectDB();
    const { Task } = await import("@/models/Task");
    await Task.deleteMany({ userId: payload.userId });

    const { invalidateTaskCache } = await import("@/lib/taskCache");
    invalidateTaskCache(payload.userId);

    await User.findByIdAndDelete(payload.userId);

    const response = NextResponse.json({
      message: "Account and all associated tasks successfully deleted",
    });
    response.cookies.delete("token");
    response.cookies.delete("refreshToken");
    return response;
  } catch (error: unknown) {
    if ((error as { digest?: string })?.digest?.startsWith("NEXT_")) {
      throw error;
    }
    console.error("Delete user account error:", error);
    return NextResponse.json({ message: "Internal server error" }, { status: 500 });
  }
}
