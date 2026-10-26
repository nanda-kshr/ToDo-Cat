import { NextResponse } from "next/server";
import { connectDB } from "@/lib/mongodb";
import { User } from "@/models/User";
import { Friendship } from "@/models/Friendship";
import { getUserFromRequest } from "@/lib/auth";
import mongoose from "mongoose";

export async function GET(request: Request) {
  try {
    const payload = getUserFromRequest(request);
    if (!payload?.userId) {
      return NextResponse.json({ message: "Unauthorized" }, { status: 401 });
    }

    const { searchParams } = new URL(request.url);
    const query = (searchParams.get("email") || "").trim().toLowerCase();

    // Prevent email scraping/enumeration: require full email address with domain
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/;
    if (!query || !emailRegex.test(query)) {
      return NextResponse.json({ users: [] });
    }

    await connectDB();
    const currentUserId = new mongoose.Types.ObjectId(payload.userId);

    // Exact email match only (exclude current user) to prevent leaking emails
    const users = await User.find({
      _id: { $ne: currentUserId },
      email: query,
    })
      .select("_id name email avatar")
      .limit(1);

    if (users.length === 0) {
      return NextResponse.json({ users: [] });
    }

    const targetUser = users[0];

    // Check existing friendship with this user
    const friendship = await Friendship.findOne({
      $or: [
        { requester: currentUserId, recipient: targetUser._id },
        { recipient: currentUserId, requester: targetUser._id },
      ],
    });

    let friendshipStatus = "none";
    let friendshipId: string | undefined;

    if (friendship) {
      friendshipId = friendship._id.toString();
      const isRequester = friendship.requester.toString() === payload.userId;
      if (friendship.status === "accepted") {
        friendshipStatus = "accepted";
      } else if (friendship.status === "pending") {
        friendshipStatus = isRequester ? "pending_sent" : "pending_received";
      }
    }

    return NextResponse.json({
      users: [
        {
          _id: targetUser._id,
          name: targetUser.name,
          email: targetUser.email,
          avatar: targetUser.avatar,
          friendshipStatus,
          friendshipId,
        },
      ],
    });
  } catch (error) {
    console.error("[Friends Search GET] Error:", error);
    return NextResponse.json({ message: "Internal server error" }, { status: 500 });
  }
}
