import { NextResponse } from "next/server";
import { connectDB } from "@/lib/mongodb";
import { Task } from "@/models/Task";
import { User } from "@/models/User";
import { Category } from "@/models/Category";
import { getUserFromRequest } from "@/lib/auth";
import { updateCachedTask, removeCachedTask } from "@/lib/taskCache";
import { sendPushNotification } from "@/lib/firebaseAdmin";
import mongoose from "mongoose";

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

    await connectDB();
    const currentUserId = new mongoose.Types.ObjectId(payload.userId);

    const task = await Task.findOne({
      _id: id,
      $or: [{ userId: currentUserId }, { sharedWith: currentUserId }],
    });

    if (!task) {
      return NextResponse.json({ message: "Task not found" }, { status: 404 });
    }

    const isCreator = task.userId.toString() === payload.userId;

    // Handle completion toggle
    if (body.completed !== undefined) {
      const willComplete = Boolean(body.completed);
      const isShared = task.sharedWith && task.sharedWith.length > 0;

      if (isShared) {
        let completedByStrings = (task.completedBy || []).map((u) => u.toString());
        if (willComplete) {
          if (!completedByStrings.includes(payload.userId)) {
            task.completedBy = [...(task.completedBy || []), currentUserId];
          }
        } else {
          task.completedBy = (task.completedBy || []).filter(
            (u) => u.toString() !== payload.userId
          );
        }

        // Dual completion condition: all participants (creator + all friends) must complete
        const sharedList = task.sharedWith || [];
        const totalRequired = 1 + sharedList.length;
        const previouslyCompleted = task.completed;
        task.completed = (task.completedBy || []).length >= totalRequired;

        // If newly fully completed, celebrate with notification!
        if (!previouslyCompleted && task.completed) {
          const allUserIds = [task.userId, ...sharedList];
          const participants = await User.find({ _id: { $in: allUserIds } });
          for (const p of participants) {
            if (p.fcmTokens?.length) {
              sendPushNotification(p.fcmTokens, {
                title: "Shared Task Completed!",
                body: `All friends completed: "${task.title}"! The cat is dancing!`,
                data: { taskId: task._id.toString() },
              }).catch(() => {});
            }
          }
        }
      } else {
        task.completed = willComplete;
        task.completedBy = willComplete ? [currentUserId] : [];
      }
    }

    if (body.deleted !== undefined) {
      task.deleted = Boolean(body.deleted);
    }

    // Only creator can edit metadata (title, due date, etc.)
    if (isCreator) {
      if (body.title !== undefined) {
        if (typeof body.title !== "string" || !body.title.trim()) {
          return NextResponse.json({ message: "Title cannot be empty" }, { status: 400 });
        }
        task.title = body.title.trim();
      }

      if (body.description !== undefined) {
        task.description = typeof body.description === "string" ? body.description.trim() : "";
      }

      if (body.dueDate !== undefined) {
        task.dueDate = body.dueDate ? new Date(body.dueDate) : null;
      }

      if (body.hasTime !== undefined) {
        task.hasTime = Boolean(body.hasTime);
      }

      if (body.recurrence !== undefined) {
        if (["none", "daily", "weekly", "monthly", "yearly"].includes(body.recurrence)) {
          task.recurrence = body.recurrence;
        }
      }

      if (body.priority !== undefined) {
        if (["low", "medium", "high"].includes(body.priority)) {
          task.priority = body.priority;
        }
      }

      if (body.category !== undefined) {
        if (typeof body.category === "string" && body.category.trim()) {
          task.category = body.category.trim();
          if (task.category !== "General") {
            const escapedCat = task.category.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
            const matchedCategory = await Category.findOne({
              name: new RegExp(`^${escapedCat}$`, "i"),
              $or: [{ userId: currentUserId }, { sharedWith: currentUserId }],
            });
            if (matchedCategory && matchedCategory.sharedWith?.length > 0 && !Array.isArray(body.sharedWith)) {
              const extraIds = [
                ...(matchedCategory.userId.toString() !== payload.userId ? [matchedCategory.userId] : []),
                ...(matchedCategory.sharedWith || []).filter((id) => id.toString() !== payload.userId),
              ];
              const existingStrings = (task.sharedWith || []).map((id) => id.toString());
              for (const xId of extraIds) {
                if (!existingStrings.includes(xId.toString())) {
                  task.sharedWith = [...(task.sharedWith || []), xId];
                }
              }
            }
          }
        }
      }

      if (Array.isArray(body.sharedWith)) {
        const validIds: mongoose.Types.ObjectId[] = [];
        for (const sId of body.sharedWith) {
          if (typeof sId === "string" && mongoose.Types.ObjectId.isValid(sId) && sId !== payload.userId) {
            validIds.push(new mongoose.Types.ObjectId(sId));
          }
        }
        task.sharedWith = validIds;
      }
    }

    await task.save();

    const populatedTask = await Task.findById(task._id)
      .populate("userId", "_id name email avatar")
      .populate("sharedWith", "_id name email avatar")
      .populate("completedBy", "_id name email avatar");

    updateCachedTask(payload.userId, populatedTask || task);

    return NextResponse.json({ task: populatedTask || task });
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
    const currentUserId = new mongoose.Types.ObjectId(payload.userId);

    const task = await Task.findOne({
      _id: id,
      $or: [{ userId: currentUserId }, { sharedWith: currentUserId }],
    });

    if (!task) {
      return NextResponse.json({ message: "Task not found" }, { status: 404 });
    }

    const isCreator = task.userId.toString() === payload.userId;

    if (isCreator) {
      await Task.findByIdAndDelete(id);
      removeCachedTask(payload.userId, id);
      return NextResponse.json({ message: "Task deleted successfully" });
    } else {
      // Shared user removing themselves
      task.sharedWith = (task.sharedWith || []).filter(
        (u) => u.toString() !== payload.userId
      );
      task.completedBy = (task.completedBy || []).filter(
        (u) => u.toString() !== payload.userId
      );
      task.completed = (task.completedBy || []).length >= (1 + (task.sharedWith || []).length);
      await task.save();
      removeCachedTask(payload.userId, id);
      return NextResponse.json({ message: "Left shared task successfully" });
    }
  } catch (error: unknown) {
    if ((error as { digest?: string })?.digest?.startsWith("NEXT_")) {
      throw error;
    }
    console.error("DELETE /api/tasks/[id] error:", error);
    return NextResponse.json({ message: "Internal server error" }, { status: 500 });
  }
}
