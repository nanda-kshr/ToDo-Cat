import { NextResponse } from "next/server";
import { connectDB } from "@/lib/mongodb";
import { User } from "@/models/User";
import { Friendship } from "@/models/Friendship";
import { getUserFromRequest } from "@/lib/auth";
import { sendPushNotification } from "@/lib/firebaseAdmin";
import { sendFriendRequestEmail, sendFriendAcceptedEmail } from "@/lib/email";
import { checkRateLimit } from "@/lib/rateLimit";
import mongoose from "mongoose";

export async function GET(request: Request) {
  try {
    const payload = getUserFromRequest(request);
    if (!payload?.userId) {
      return NextResponse.json({ message: "Unauthorized" }, { status: 401 });
    }

    const rateLimit = checkRateLimit(`get_friends:${payload.userId}`, 90, 60);
    if (!rateLimit.allowed) {
      return NextResponse.json(
        { message: "Too many requests. Please wait a moment." },
        { status: 429 }
      );
    }

    const { searchParams } = new URL(request.url);
    const search = (
      searchParams.get("search") ||
      searchParams.get("email") ||
      searchParams.get("query") ||
      ""
    ).trim().toLowerCase();
    const hasPagination = searchParams.has("page") || searchParams.has("limit");
    const page = Math.max(1, parseInt(searchParams.get("page") || "1", 10));
    const limit = Math.max(1, Math.min(100, parseInt(searchParams.get("limit") || "15", 10)));

    await connectDB();
    const currentUserId = new mongoose.Types.ObjectId(payload.userId);

    // Fetch all active or pending friendships involving the user
    const friendships = await Friendship.find({
      $or: [{ requester: currentUserId }, { recipient: currentUserId }],
      status: { $in: ["accepted", "pending"] },
    })
      .populate("requester", "_id name email avatar isProfilePublic")
      .populate("recipient", "_id name email avatar isProfilePublic")
      .sort({ updatedAt: -1 });

    let allFriends: any[] = [];
    const pendingIncoming: any[] = [];
    const pendingOutgoing: any[] = [];

    for (const f of friendships) {
      const requester = f.requester as any;
      const recipient = f.recipient as any;

      if (!requester || !recipient) continue;

      const isRequester = requester._id.toString() === payload.userId;
      const otherUser = isRequester ? recipient : requester;

      if (f.status === "accepted") {
        allFriends.push({
          friendshipId: f._id,
          user: otherUser,
          since: f.updatedAt,
        });
      } else if (f.status === "pending") {
        if (isRequester) {
          pendingOutgoing.push({
            friendshipId: f._id,
            user: otherUser,
            createdAt: f.createdAt,
          });
        } else {
          pendingIncoming.push({
            friendshipId: f._id,
            user: otherUser,
            createdAt: f.createdAt,
          });
        }
      }
    }

    // Search existing friends by email (or name)
    if (search) {
      allFriends = allFriends.filter((f) => {
        const email = (f.user?.email || "").toLowerCase();
        const name = (f.user?.name || "").toLowerCase();
        return email.includes(search) || name.includes(search);
      });
    }

    const total = allFriends.length;
    let paginatedFriends = allFriends;
    let hasMore = false;

    if (hasPagination) {
      const startIndex = (page - 1) * limit;
      paginatedFriends = allFriends.slice(startIndex, startIndex + limit);
      hasMore = startIndex + limit < total;
    }

    return NextResponse.json({
      friends: paginatedFriends,
      pendingIncoming,
      pendingOutgoing,
      pagination: {
        page,
        limit: hasPagination ? limit : total,
        total,
        hasMore,
      },
    });
  } catch (error) {
    console.error("[Friends GET] Error:", error);
    return NextResponse.json({ message: "Internal server error" }, { status: 500 });
  }
}

export async function POST(request: Request) {
  try {
    const payload = getUserFromRequest(request);
    if (!payload?.userId) {
      return NextResponse.json({ message: "Unauthorized" }, { status: 401 });
    }

    // Rate limit: max 15 friend requests per hour per user
    const userLimit = checkRateLimit(`friend_req_user:${payload.userId}`, 15, 60 * 60);
    if (!userLimit.allowed) {
      return NextResponse.json(
        { message: `Too many friend requests sent. Please try again in ${Math.ceil(userLimit.resetInSeconds / 60)} minutes.` },
        { status: 429 }
      );
    }

    const { email } = await request.json();
    if (!email || typeof email !== "string") {
      return NextResponse.json({ message: "Valid email is required" }, { status: 400 });
    }

    const cleanEmail = email.trim().toLowerCase();

    // Rate limit: max 1 request to the same target email per 60 seconds
    const targetLimit = checkRateLimit(`friend_req_target:${payload.userId}:${cleanEmail}`, 1, 60);
    if (!targetLimit.allowed) {
      return NextResponse.json(
        { message: "You recently sent a request to this user. Please wait a minute before trying again." },
        { status: 429 }
      );
    }

    await connectDB();
    const currentUserId = new mongoose.Types.ObjectId(payload.userId);
    const currentUser = await User.findById(currentUserId);

    if (!currentUser) {
      return NextResponse.json({ message: "User not found" }, { status: 404 });
    }

    if (cleanEmail === currentUser.email.toLowerCase()) {
      return NextResponse.json({ message: "You cannot add yourself as a friend" }, { status: 400 });
    }

    const targetUser = await User.findOne({ email: cleanEmail });
    if (!targetUser) {
      return NextResponse.json({ message: "User not found with this email" }, { status: 404 });
    }

    const targetUserId = targetUser._id;

    // Check if reverse request exists
    const reverseFriendship = await Friendship.findOne({
      requester: targetUserId,
      recipient: currentUserId,
    });

    if (reverseFriendship) {
      if (reverseFriendship.status === "accepted") {
        return NextResponse.json({ message: "Already friends" }, { status: 400 });
      }
      // Auto-accept existing incoming request
      reverseFriendship.status = "accepted";
      await reverseFriendship.save();

      if (targetUser.fcmTokens?.length) {
        sendPushNotification(targetUser.fcmTokens, {
          title: "Friend Request Accepted!",
          body: `${currentUser.name || currentUser.email} accepted your friend request.`,
          data: {
            type: "friend_accepted",
            senderId: currentUser._id.toString(),
            senderName: currentUser.name || currentUser.email,
          },
        }).catch((err) => {
          console.error("[FCM Friend Accept Error]:", err);
        });
      }

      sendFriendAcceptedEmail({
        toEmail: targetUser.email,
        friendName: currentUser.name,
        friendEmail: currentUser.email,
      }).catch(() => {});

      return NextResponse.json({
        message: "Friend request accepted",
        friendship: reverseFriendship,
      });
    }

    // Check existing outgoing friendship
    const existing = await Friendship.findOne({
      requester: currentUserId,
      recipient: targetUserId,
    });

    if (existing) {
      if (existing.status === "accepted") {
        return NextResponse.json({ message: "Already friends" }, { status: 400 });
      }
      if (existing.status === "pending") {
        return NextResponse.json({ message: "Friend request already sent" }, { status: 400 });
      }
      existing.status = "pending";
      await existing.save();
    } else {
      await Friendship.create({
        requester: currentUserId,
        recipient: targetUserId,
        status: "pending",
      });
    }

    // Send push notification to target user
    if (targetUser.fcmTokens?.length) {
      sendPushNotification(targetUser.fcmTokens, {
        title: "New Friend Request!",
        body: `${currentUser.name || currentUser.email} sent you a friend request.`,
        data: {
          type: "friend_request",
          senderId: currentUser._id.toString(),
          senderName: currentUser.name || currentUser.email,
          senderEmail: currentUser.email,
        },
      }).catch((err) => {
        console.error("[FCM Friend Request Error]:", err);
      });
    }

    sendFriendRequestEmail({
      toEmail: targetUser.email,
      senderName: currentUser.name,
      senderEmail: currentUser.email,
    }).catch(() => {});

    return NextResponse.json({ message: "Request sent" });
  } catch (error) {
    console.error("[Friends POST] Error:", error);
    return NextResponse.json({ message: "Internal server error" }, { status: 500 });
  }
}
