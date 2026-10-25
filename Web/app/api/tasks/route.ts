import { NextResponse } from "next/server";
import { connectDB } from "@/lib/mongodb";
import { Task } from "@/models/Task";
import { User } from "@/models/User";
import { getUserFromRequest } from "@/lib/auth";
import {
  getCachedTasks,
  setCachedTasks,
  addCachedTask,
  removeCachedTask,
} from "@/lib/taskCache";
import { sendPushNotification } from "@/lib/firebaseAdmin";
import { sendSharedTaskEmail } from "@/lib/email";
import mongoose from "mongoose";

export async function GET(request: Request) {
  try {
    const payload = getUserFromRequest(request);
    if (!payload?.userId) {
      return NextResponse.json({ message: "Unauthorized" }, { status: 401 });
    }

    const { searchParams } = new URL(request.url);
    const page = Math.max(1, parseInt(searchParams.get("page") || "1", 10) || 1);
    const limit = Math.max(1, parseInt(searchParams.get("limit") || "50", 10) || 50);

    let tasks = getCachedTasks(payload.userId);
    let cacheHit = true;

    if (!tasks) {
      cacheHit = false;
      await connectDB();
      const currentUserId = new mongoose.Types.ObjectId(payload.userId);

      const dbTasks = await Task.find({
        $or: [{ userId: currentUserId }, { sharedWith: currentUserId }],
      })
        .populate("userId", "_id name email avatar")
        .populate("sharedWith", "_id name email avatar")
        .populate("completedBy", "_id name email avatar")
        .sort({
          completed: 1,
          dueDate: 1,
          createdAt: -1,
        });

      setCachedTasks(payload.userId, dbTasks);
      tasks = getCachedTasks(payload.userId) || JSON.parse(JSON.stringify(dbTasks));
    }

    const total = tasks ? tasks.length : 0;
    const totalPages = Math.ceil(total / limit) || 1;
    const startIndex = (page - 1) * limit;
    const paginatedTasks = tasks ? tasks.slice(startIndex, startIndex + limit) : [];

    return NextResponse.json(
      {
        tasks: paginatedTasks,
        pagination: {
          page,
          limit,
          total,
          totalPages,
        },
      },
      { headers: { "X-Cache": cacheHit ? "HIT" : "MISS" } }
    );
  } catch (error: unknown) {
    if ((error as { digest?: string })?.digest?.startsWith("NEXT_")) {
      throw error;
    }
    console.error("GET /api/tasks error:", error);
    return NextResponse.json({ message: "Internal server error" }, { status: 500 });
  }
}

export async function POST(request: Request) {
  try {
    const payload = getUserFromRequest(request);
    if (!payload?.userId) {
      return NextResponse.json({ message: "Unauthorized" }, { status: 401 });
    }

    const body = await request.json();
    const { title, description, dueDate, hasTime, recurrence, priority, category, sharedWith } = body;

    if (!title || typeof title !== "string" || !title.trim()) {
      return NextResponse.json({ message: "Title is required" }, { status: 400 });
    }

    const validRecurrence = ["none", "daily", "weekly", "monthly", "yearly"].includes(recurrence)
      ? recurrence
      : "none";

    await connectDB();
    const currentUserId = new mongoose.Types.ObjectId(payload.userId);
    const currentUser = await User.findById(currentUserId);

    const validSharedWith: mongoose.Types.ObjectId[] = [];
    if (Array.isArray(sharedWith)) {
      for (const id of sharedWith) {
        if (typeof id === "string" && mongoose.Types.ObjectId.isValid(id) && id !== payload.userId) {
          validSharedWith.push(new mongoose.Types.ObjectId(id));
        }
      }
    }

    const task = await Task.create({
      userId: currentUserId,
      title: title.trim(),
      description: typeof description === "string" ? description.trim() : "",
      dueDate: dueDate ? new Date(dueDate) : null,
      hasTime: Boolean(hasTime),
      recurrence: validRecurrence,
      priority: ["low", "medium", "high"].includes(priority) ? priority : "medium",
      category: typeof category === "string" && category.trim() ? category.trim() : "General",
      sharedWith: validSharedWith,
      completedBy: [],
    });

    const populatedTask = await Task.findById(task._id)
      .populate("userId", "_id name email avatar")
      .populate("sharedWith", "_id name email avatar")
      .populate("completedBy", "_id name email avatar");

    addCachedTask(payload.userId, populatedTask || task);

    // If shared with friends, notify them and invalidate their task caches
    if (validSharedWith.length > 0) {
      const friends = await User.find({ _id: { $in: validSharedWith } });
      for (const friend of friends) {
        // Clear cached tasks so they get the new shared task
        removeCachedTask(friend._id.toString(), "");

        // Push notification
        if (friend.fcmTokens?.length) {
          sendPushNotification(friend.fcmTokens, {
            title: "New Shared Task! 🐾",
            body: `${currentUser?.name || currentUser?.email || "A friend"} shared a task: "${task.title}"`,
            data: { taskId: task._id.toString() },
          }).catch(() => {});
        }

        // Email notification via SMTP
        if (friend.email) {
          sendSharedTaskEmail({
            toEmail: friend.email,
            senderName: currentUser?.name,
            senderEmail: currentUser?.email || "",
            taskTitle: task.title,
          }).catch(() => {});
        }
      }
    }

    return NextResponse.json({ task: populatedTask || task }, { status: 201 });
  } catch (error: unknown) {
    if ((error as { digest?: string })?.digest?.startsWith("NEXT_")) {
      throw error;
    }
    console.error("POST /api/tasks error:", error);
    return NextResponse.json({ message: "Internal server error" }, { status: 500 });
  }
}
