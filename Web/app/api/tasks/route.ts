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

    const { searchParams } = new URL(request.url);
    const page = Math.max(1, parseInt(searchParams.get("page") || "1", 10) || 1);
    const limit = Math.max(1, parseInt(searchParams.get("limit") || "50", 10) || 50);

    let tasks = getCachedTasks(payload.userId);
    let cacheHit = true;

    if (!tasks) {
      cacheHit = false;
      await connectDB();
      const dbTasks = await Task.find({ userId: payload.userId }).sort({
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
