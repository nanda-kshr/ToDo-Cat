import { NextResponse } from "next/server";
import { connectDB } from "@/lib/mongodb";
import { User } from "@/models/User";
import { Friendship } from "@/models/Friendship";
import { getUserFromRequest } from "@/lib/auth";
import { sendPushNotification } from "@/lib/firebaseAdmin";
import { sendFriendAcceptedEmail } from "@/lib/email";
import mongoose from "mongoose";

export async function PATCH(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const payload = getUserFromRequest(request);
    if (!payload?.userId) {
      return NextResponse.json({ message: "Unauthorized" }, { status: 401 });
    }

    const { id } = await params;
    const { action } = await request.json(); // "accept" | "decline"

    if (!["accept", "decline"].includes(action)) {
      return NextResponse.json({ message: "Invalid action" }, { status: 400 });
    }

    await connectDB();
    const friendship = await Friendship.findById(id);

    if (!friendship) {
      return NextResponse.json({ message: "Friend request not found" }, { status: 404 });
    }

    // Only recipient can accept/decline incoming request
    if (friendship.recipient.toString() !== payload.userId) {
      return NextResponse.json(
        { message: "You are not authorized to respond to this request" },
        { status: 403 }
      );
    }

    if (action === "accept") {
      friendship.status = "accepted";
      await friendship.save();

      // Notify the requester
      const [requester, recipient] = await Promise.all([
        User.findById(friendship.requester),
        User.findById(friendship.recipient),
      ]);

      if (requester?.fcmTokens?.length) {
        sendPushNotification(requester.fcmTokens, {
          title: "Friend Request Accepted! 🐾",
          body: `${recipient?.name || recipient?.email || "Your friend"} accepted your friend request!`,
        }).catch(() => {});
      }

      if (requester?.email) {
        sendFriendAcceptedEmail({
          toEmail: requester.email,
          friendName: recipient?.name,
          friendEmail: recipient?.email || "",
        }).catch(() => {});
      }

      return NextResponse.json({ message: "Friend request accepted", friendship });
    } else {
      friendship.status = "declined";
      await friendship.save();
      return NextResponse.json({ message: "Friend request declined" });
    }
  } catch (error) {
    console.error("[Friendship PATCH] Error:", error);
    return NextResponse.json({ message: "Internal server error" }, { status: 500 });
  }
}

export async function DELETE(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const payload = getUserFromRequest(request);
    if (!payload?.userId) {
      return NextResponse.json({ message: "Unauthorized" }, { status: 401 });
    }

    const { id } = await params;
    await connectDB();

    const friendship = await Friendship.findById(id);
    if (!friendship) {
      return NextResponse.json({ message: "Friendship not found" }, { status: 404 });
    }

    // Requester or recipient can delete
    if (
      friendship.requester.toString() !== payload.userId &&
      friendship.recipient.toString() !== payload.userId
    ) {
      return NextResponse.json({ message: "Forbidden" }, { status: 403 });
    }

    await Friendship.findByIdAndDelete(id);
    return NextResponse.json({ message: "Friendship removed" });
  } catch (error) {
    console.error("[Friendship DELETE] Error:", error);
    return NextResponse.json({ message: "Internal server error" }, { status: 500 });
  }
}
