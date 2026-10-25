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

    if (!query || query.length < 2) {
      return NextResponse.json({ users: [] });
    }

    await connectDB();
    const currentUserId = new mongoose.Types.ObjectId(payload.userId);

    // Search users by email prefix or exact match, exclude current user
    const users = await User.find({
      _id: { $ne: currentUserId },
      email: { $regex: query, $options: "i" },
    })
      .select("_id name email avatar")
      .limit(10);

    const userIds = users.map((u) => u._id);

    // Check existing friendships with these users
    const existingFriendships = await Friendship.find({
      $or: [
        { requester: currentUserId, recipient: { $in: userIds } },
        { recipient: currentUserId, requester: { $in: userIds } },
      ],
    });

    const statusMap = new Map<string, { status: string; friendshipId?: string }>();
    for (const f of existingFriendships) {
      const isRequester = f.requester.toString() === payload.userId;
      const otherId = isRequester ? f.recipient.toString() : f.requester.toString();

      if (f.status === "accepted") {
        statusMap.set(otherId, { status: "accepted", friendshipId: f._id.toString() });
      } else if (f.status === "pending") {
        statusMap.set(otherId, {
          status: isRequester ? "pending_sent" : "pending_received",
          friendshipId: f._id.toString(),
        });
      }
    }

    const results = users.map((u) => {
      const fsInfo = statusMap.get(u._id.toString()) || { status: "none" };
      return {
        _id: u._id,
        name: u.name,
        email: u.email,
        avatar: u.avatar,
        friendshipStatus: fsInfo.status,
        friendshipId: fsInfo.friendshipId,
      };
    });

    return NextResponse.json({ users: results });
  } catch (error) {
    console.error("[Friends Search GET] Error:", error);
    return NextResponse.json({ message: "Internal server error" }, { status: 500 });
  }
}
