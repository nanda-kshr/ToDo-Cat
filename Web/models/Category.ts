import mongoose, { Document, Model, Schema, Types } from "mongoose";

export interface ICategory extends Document {
  userId: Types.ObjectId;
  name: string;
  sharedWith: Types.ObjectId[];
  createdAt: Date;
  updatedAt: Date;
}

const CategorySchema = new Schema<ICategory>(
  {
    userId: {
      type: Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },
    name: {
      type: String,
      required: [true, "Category name is required"],
      trim: true,
    },
    sharedWith: {
      type: [{ type: Schema.Types.ObjectId, ref: "User" }],
      default: [],
      index: true,
    },
  },
  {
    timestamps: true,
  }
);

// Compound index to ensure uniqueness per user
CategorySchema.index({ userId: 1, name: 1 }, { unique: true });

export const Category: Model<ICategory> =
  mongoose.models.Category || mongoose.model<ICategory>("Category", CategorySchema);

export default Category;
