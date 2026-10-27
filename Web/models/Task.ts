import mongoose, { Document, Model, Schema, Types } from "mongoose";

export type TaskPriority = "low" | "medium" | "high";
export type TaskRecurrence = "none" | "daily" | "weekly" | "monthly" | "yearly";

export interface ITask extends Document {
  userId: Types.ObjectId;
  title: string;
  description?: string;
  completed: boolean;
  deleted?: boolean;
  dueDate?: Date | null;
  hasTime?: boolean;
  recurrence?: TaskRecurrence;
  priority: TaskPriority;
  category: string;
  sharedWith?: Types.ObjectId[];
  completedBy?: Types.ObjectId[];
  createdAt: Date;
  updatedAt: Date;
}

const TaskSchema = new Schema<ITask>(
  {
    userId: {
      type: Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },
    title: {
      type: String,
      required: [true, "Title is required"],
      trim: true,
    },
    description: {
      type: String,
      trim: true,
      default: "",
    },
    completed: {
      type: Boolean,
      default: false,
      index: true,
    },
    deleted: {
      type: Boolean,
      default: false,
      index: true,
    },
    dueDate: {
      type: Date,
      default: null,
      index: true,
    },
    hasTime: {
      type: Boolean,
      default: false,
    },
    recurrence: {
      type: String,
      enum: ["none", "daily", "weekly", "monthly", "yearly"],
      default: "none",
      index: true,
    },
    priority: {
      type: String,
      enum: ["low", "medium", "high"],
      default: "medium",
      index: true,
    },
    category: {
      type: String,
      trim: true,
      default: "General",
      index: true,
    },
    sharedWith: {
      type: [{ type: Schema.Types.ObjectId, ref: "User" }],
      default: [],
      index: true,
    },
    completedBy: {
      type: [{ type: Schema.Types.ObjectId, ref: "User" }],
      default: [],
      index: true,
    },
  },
  {
    timestamps: true,
  }
);

export const Task: Model<ITask> =
  mongoose.models.Task || mongoose.model<ITask>("Task", TaskSchema);

export default Task;
