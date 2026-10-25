import mongoose, { Document, Model, Schema } from "mongoose";

export interface IFriendship extends Document {
  requester: mongoose.Types.ObjectId;
  recipient: mongoose.Types.ObjectId;
  status: "pending" | "accepted" | "declined";
  createdAt: Date;
  updatedAt: Date;
}

const FriendshipSchema = new Schema<IFriendship>(
  {
    requester: {
      type: Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },
    recipient: {
      type: Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },
    status: {
      type: String,
      enum: ["pending", "accepted", "declined"],
      default: "pending",
      index: true,
    },
  },
  {
    timestamps: true,
  }
);

FriendshipSchema.index({ requester: 1, recipient: 1 }, { unique: true });

export const Friendship: Model<IFriendship> =
  mongoose.models.Friendship ||
  mongoose.model<IFriendship>("Friendship", FriendshipSchema);
