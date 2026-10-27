import mongoose, { Document, Model, Schema } from "mongoose";

export interface IRotatedToken {
  token: string;
  newAccessToken: string;
  newRefreshToken: string;
  rotatedAt: Date;
}

export interface IUser extends Document {
  email: string;
  password?: string;
  name?: string;
  googleId?: string;
  avatar?: string;
  refreshTokens: string[];
  rotatedTokens?: IRotatedToken[];
  fcmTokens?: string[];
  resetPasswordToken?: string;
  resetPasswordOtp?: string;
  resetPasswordExpires?: Date;
  resetPasswordAttempts?: number;
  isProfilePublic?: boolean;
  createdAt: Date;
  updatedAt: Date;
}

const UserSchema = new Schema<IUser>(
  {
    email: {
      type: String,
      required: [true, "Email is required"],
      unique: true,
      lowercase: true,
      trim: true,
    },
    password: {
      type: String,
      required: function (this: IUser) {
        return !this.googleId;
      },
    },
    name: {
      type: String,
      trim: true,
    },
    googleId: {
      type: String,
      unique: true,
      sparse: true,
    },
    avatar: {
      type: String,
    },
    refreshTokens: {
      type: [String],
      default: [],
    },
    rotatedTokens: [
      {
        token: { type: String, required: true },
        newAccessToken: { type: String, required: true },
        newRefreshToken: { type: String, required: true },
        rotatedAt: { type: Date, default: Date.now },
      },
    ],
    fcmTokens: {
      type: [String],
      default: [],
    },
    resetPasswordToken: {
      type: String,
      index: true,
    },
    resetPasswordOtp: {
      type: String,
      index: true,
    },
    resetPasswordExpires: {
      type: Date,
      index: true,
    },
    resetPasswordAttempts: {
      type: Number,
      default: 0,
    },
    isProfilePublic: {
      type: Boolean,
      default: false,
    },
  },
  {
    timestamps: true,
  }
);

if (mongoose.models.User) {
  delete (mongoose.models as Record<string, unknown>).User;
}

export const User: Model<IUser> =
  mongoose.models.User || mongoose.model<IUser>("User", UserSchema);

export default User;
