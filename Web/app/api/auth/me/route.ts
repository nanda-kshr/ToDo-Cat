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

    return NextResponse.json({ user });
  } catch (error: unknown) {
    if ((error as { digest?: string })?.digest?.startsWith("NEXT_")) {
      throw error;
    }
    console.error("Auth me error:", error);
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
