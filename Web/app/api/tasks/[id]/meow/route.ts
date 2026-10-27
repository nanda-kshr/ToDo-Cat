import { NextResponse } from "next/server";
import { connectDB } from "@/lib/mongodb";
import { Task } from "@/models/Task";
import { User } from "@/models/User";
import { getUserFromRequest } from "@/lib/auth";
import { sendPushNotification } from "@/lib/firebaseAdmin";
import { checkRateLimit } from "@/lib/rateLimit";
import mongoose from "mongoose";

export async function POST(
  request: Request,
  context: { params: Promise<{ id: string }> }
) {
  try {
    const payload = getUserFromRequest(request);
    if (!payload?.userId) {
      return NextResponse.json({ message: "Unauthorized" }, { status: 401 });
    }

    const { id } = await context.params;
    const body = await request.json();
    const { targetUserId } = body;

    if (!targetUserId || typeof targetUserId !== "string") {
      return NextResponse.json({ message: "Target user ID is required" }, { status: 400 });
    }

    // Rate limit: max 1 meow per 30 seconds per sender/target/task
    const rateKey = `meow:${payload.userId}:${targetUserId}:${id}`;
    const rateCheck = checkRateLimit(rateKey, 1, 30);
    if (!rateCheck.allowed) {
      return NextResponse.json(
        { message: "Please wait a moment before sending another Meow." },
        { status: 429 }
      );
    }

    await connectDB();
    const currentUserId = new mongoose.Types.ObjectId(payload.userId);
    const targetId = new mongoose.Types.ObjectId(targetUserId);

    const task = await Task.findOne({
      _id: id,
      $or: [{ userId: currentUserId }, { sharedWith: currentUserId }],
    });

    if (!task) {
      return NextResponse.json({ message: "Task not found" }, { status: 404 });
    }

    // Check if target user is part of the task
    const isTargetCreator = task.userId.toString() === targetUserId;
    const isTargetShared = (task.sharedWith || []).some(
      (sId) => sId.toString() === targetUserId
    );

    if (!isTargetCreator && !isTargetShared) {
      return NextResponse.json({ message: "Target user is not part of this task" }, { status: 400 });
    }

    // Check if already completed
    const isAlreadyCompleted = (task.completedBy || []).some(
      (cId) => cId.toString() === targetUserId
    );
    if (isAlreadyCompleted) {
      return NextResponse.json({ message: "Target user has already completed their part." }, { status: 400 });
    }

    const [sender, targetUser] = await Promise.all([
      User.findById(currentUserId),
      User.findById(targetId),
    ]);

    if (!targetUser) {
      return NextResponse.json({ message: "Target user not found" }, { status: 404 });
    }

    const senderName = sender?.name?.trim() || sender?.email?.split("@")[0] || "A friend";

    // Strictly no emojis in push notification title and body
    if (targetUser.fcmTokens && targetUser.fcmTokens.length > 0) {
      await sendPushNotification(targetUser.fcmTokens, {
        title: "Meow!",
        body: `${senderName} nudged you to finish "${task.title}".`,
        data: { taskId: task._id.toString(), type: "meow" },
      });
    }

    return NextResponse.json({ message: "Meow sent successfully" });
  } catch (error: unknown) {
    if ((error as { digest?: string })?.digest?.startsWith("NEXT_")) {
      throw error;
    }
    console.error("POST /api/tasks/[id]/meow error:", error);
    return NextResponse.json({ message: "Internal server error" }, { status: 500 });
  }
}
