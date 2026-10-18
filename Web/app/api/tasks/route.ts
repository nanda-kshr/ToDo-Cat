import { NextResponse } from "next/server";
import { connectDB } from "@/lib/mongodb";
import { Task } from "@/models/Task";
import { getUserFromRequest } from "@/lib/auth";
import {
  getCachedTasks,
  setCachedTasks,
  addCachedTask,
} from "@/lib/taskCache";

export async function GET(request: Request) {
  try {
    const payload = getUserFromRequest(request);
    if (!payload?.userId) {
      return NextResponse.json({ message: "Unauthorized" }, { status: 401 });
    }

    const cachedTasks = getCachedTasks(payload.userId);
    if (cachedTasks) {
      return NextResponse.json(
        { tasks: cachedTasks },
        { headers: { "X-Cache": "HIT" } }
      );
    }

    await connectDB();
    const tasks = await Task.find({ userId: payload.userId }).sort({
      completed: 1,
      dueDate: 1,
      createdAt: -1,
    });

    setCachedTasks(payload.userId, tasks);

    return NextResponse.json(
      { tasks },
      { headers: { "X-Cache": "MISS" } }
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
    const { title, description, dueDate, priority, category } = body;

    if (!title || typeof title !== "string" || !title.trim()) {
      return NextResponse.json({ message: "Title is required" }, { status: 400 });
    }

    await connectDB();
    const task = await Task.create({
      userId: payload.userId,
      title: title.trim(),
      description: typeof description === "string" ? description.trim() : "",
      dueDate: dueDate ? new Date(dueDate) : null,
      priority: ["low", "medium", "high"].includes(priority) ? priority : "medium",
      category: typeof category === "string" && category.trim() ? category.trim() : "General",
    });

    addCachedTask(payload.userId, task);

    return NextResponse.json({ task }, { status: 201 });
  } catch (error: unknown) {
    if ((error as { digest?: string })?.digest?.startsWith("NEXT_")) {
      throw error;
    }
    console.error("POST /api/tasks error:", error);
    return NextResponse.json({ message: "Internal server error" }, { status: 500 });
  }
}
