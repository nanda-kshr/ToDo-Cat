import { NextResponse } from "next/server";
import { connectDB } from "@/lib/mongodb";
import { Category } from "@/models/Category";
import { User } from "@/models/User";
import { getUserFromRequest } from "@/lib/auth";
import { checkRateLimit } from "@/lib/rateLimit";
import { sendPushNotification } from "@/lib/firebaseAdmin";
import mongoose from "mongoose";

export async function GET(request: Request) {
  try {
    const payload = getUserFromRequest(request);
    if (!payload?.userId) {
      return NextResponse.json({ message: "Unauthorized" }, { status: 401 });
    }

    const rateLimit = checkRateLimit(`get_categories:${payload.userId}`, 120, 60);
    if (!rateLimit.allowed) {
      return NextResponse.json(
        { message: "Too many requests. Please slow down." },
        { status: 429 }
      );
    }

    await connectDB();
    const currentUserId = new mongoose.Types.ObjectId(payload.userId);

    const categories = await Category.find({
      $or: [{ userId: currentUserId }, { sharedWith: currentUserId }],
    })
      .populate("userId", "_id name email avatar")
      .populate("sharedWith", "_id name email avatar")
      .sort({ createdAt: 1 });

    return NextResponse.json({ categories });
  } catch (error: unknown) {
    if ((error as { digest?: string })?.digest?.startsWith("NEXT_")) {
      throw error;
    }
    console.error("GET /api/categories error:", error);
    return NextResponse.json({ message: "Internal server error" }, { status: 500 });
  }
}

export async function POST(request: Request) {
  try {
    const payload = getUserFromRequest(request);
    if (!payload?.userId) {
      return NextResponse.json({ message: "Unauthorized" }, { status: 401 });
    }

    const rateLimit = checkRateLimit(`create_category:${payload.userId}`, 60, 60);
    if (!rateLimit.allowed) {
      return NextResponse.json(
        { message: "Too many requests. Please slow down." },
        { status: 429 }
      );
    }

    const body = await request.json();
    const { name, sharedWith } = body;

    if (!name || typeof name !== "string" || !name.trim()) {
      return NextResponse.json({ message: "Category name is required" }, { status: 400 });
    }

    const trimmedName = name.trim();
    await connectDB();
    const currentUserId = new mongoose.Types.ObjectId(payload.userId);
    const currentUser = await User.findById(currentUserId);

    const validSharedWith: mongoose.Types.ObjectId[] = [];
    if (Array.isArray(sharedWith)) {
      for (const id of sharedWith) {
        if (
          typeof id === "string" &&
          mongoose.Types.ObjectId.isValid(id) &&
          id !== payload.userId
        ) {
          validSharedWith.push(new mongoose.Types.ObjectId(id));
        }
      }
    }

    const escapedName = trimmedName.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    let category = await Category.findOne({
      userId: currentUserId,
      name: new RegExp(`^${escapedName}$`, "i"),
    });

    if (category) {
      category.name = trimmedName;
      category.sharedWith = validSharedWith;
      await category.save();
    } else {
      category = await Category.create({
        userId: currentUserId,
        name: trimmedName,
        sharedWith: validSharedWith,
      });
    }

    const populatedCategory = await Category.findById(category._id)
      .populate("userId", "_id name email avatar")
      .populate("sharedWith", "_id name email avatar");

    // If shared, push notify friends
    if (validSharedWith.length > 0) {
      const friends = await User.find({ _id: { $in: validSharedWith } });
      for (const friend of friends) {
        if (friend.fcmTokens?.length) {
          sendPushNotification(friend.fcmTokens, {
            title: "New Shared Category!",
            body: `${currentUser?.name || currentUser?.email || "A friend"} shared the "${trimmedName}" category with you!`,
            data: { categoryId: category._id.toString() },
          }).catch(() => {});
        }
      }
    }

    return NextResponse.json({ category: populatedCategory || category }, { status: 201 });
  } catch (error: unknown) {
    if ((error as { digest?: string })?.digest?.startsWith("NEXT_")) {
      throw error;
    }
    console.error("POST /api/categories error:", error);
    return NextResponse.json({ message: "Internal server error" }, { status: 500 });
  }
}
