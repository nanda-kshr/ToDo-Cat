import { NextResponse } from "next/server";
import { connectDB } from "@/lib/mongodb";
import { Task } from "@/models/Task";
import { getUserFromRequest } from "@/lib/auth";
import { updateCachedTask, removeCachedTask } from "@/lib/taskCache";

export async function PATCH(
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

    const updateData: Record<string, unknown> = {};

    if (body.title !== undefined) {
      if (typeof body.title !== "string" || !body.title.trim()) {
        return NextResponse.json({ message: "Title cannot be empty" }, { status: 400 });
      }
      updateData.title = body.title.trim();
    }

    if (body.description !== undefined) {
      updateData.description = typeof body.description === "string" ? body.description.trim() : "";
    }

    if (body.completed !== undefined) {
      updateData.completed = Boolean(body.completed);
    }

    if (body.dueDate !== undefined) {
      updateData.dueDate = body.dueDate ? new Date(body.dueDate) : null;
    }

    if (body.hasTime !== undefined) {
      updateData.hasTime = Boolean(body.hasTime);
    }

    if (body.recurrence !== undefined) {
      if (["none", "daily", "weekly", "monthly", "yearly"].includes(body.recurrence)) {
        updateData.recurrence = body.recurrence;
      }
    }

    if (body.priority !== undefined) {
      if (["low", "medium", "high"].includes(body.priority)) {
        updateData.priority = body.priority;
      }
    }

    if (body.category !== undefined) {
      if (typeof body.category === "string" && body.category.trim()) {
        updateData.category = body.category.trim();
      }
    }

    await connectDB();
    const task = await Task.findOneAndUpdate(
      { _id: id, userId: payload.userId },
      { $set: updateData },
      { new: true }
    );

    if (!task) {
      return NextResponse.json({ message: "Task not found" }, { status: 404 });
    }

    updateCachedTask(payload.userId, task);

    return NextResponse.json({ task });
  } catch (error: unknown) {
    if ((error as { digest?: string })?.digest?.startsWith("NEXT_")) {
      throw error;
    }
    console.error("PATCH /api/tasks/[id] error:", error);
    return NextResponse.json({ message: "Internal server error" }, { status: 500 });
  }
}

export async function DELETE(
  request: Request,
  context: { params: Promise<{ id: string }> }
) {
  try {
    const payload = getUserFromRequest(request);
    if (!payload?.userId) {
      return NextResponse.json({ message: "Unauthorized" }, { status: 401 });
    }

    const { id } = await context.params;

    await connectDB();
    const task = await Task.findOneAndDelete({ _id: id, userId: payload.userId });

    if (!task) {
      return NextResponse.json({ message: "Task not found" }, { status: 404 });
    }

    removeCachedTask(payload.userId, id);

    return NextResponse.json({ message: "Task deleted successfully" });
  } catch (error: unknown) {
    if ((error as { digest?: string })?.digest?.startsWith("NEXT_")) {
      throw error;
    }
    console.error("DELETE /api/tasks/[id] error:", error);
    return NextResponse.json({ message: "Internal server error" }, { status: 500 });
  }
}
