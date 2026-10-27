import { cookies } from "next/headers";
import jwt from "jsonwebtoken";
import bcrypt from "bcryptjs";

const JWT_SECRET = process.env.JWT_SECRET || "todocat_jwt_access_secret_change_in_production";
const JWT_REFRESH_SECRET = process.env.JWT_REFRESH_SECRET || "todocat_jwt_refresh_secret_change_in_production";

const ACCESS_TOKEN_EXPIRES_IN = "24h";
const REFRESH_TOKEN_EXPIRES_IN = "30d";

export interface TokenPayload {
  userId: string;
}

export async function hashPassword(password: string): Promise<string> {
  const salt = await bcrypt.genSalt(10);
  return bcrypt.hash(password, salt);
}

export async function comparePassword(password: string, hash: string): Promise<boolean> {
  return bcrypt.compare(password, hash);
}

export function generateTokens(userId: string): { accessToken: string; refreshToken: string } {
  const accessToken = jwt.sign({ userId }, JWT_SECRET, {
    expiresIn: ACCESS_TOKEN_EXPIRES_IN,
  });

  const refreshToken = jwt.sign({ userId }, JWT_REFRESH_SECRET, {
    expiresIn: REFRESH_TOKEN_EXPIRES_IN,
  });

  return { accessToken, refreshToken };
}

export function verifyAccessToken(token: string): TokenPayload | null {
  try {
    return jwt.verify(token, JWT_SECRET) as TokenPayload;
  } catch {
    return null;
  }
}

export function verifyRefreshToken(token: string): TokenPayload | null {
  try {
    return jwt.verify(token, JWT_REFRESH_SECRET) as TokenPayload;
  } catch {
    return null;
  }
}

export async function setRefreshTokenCookie(token: string): Promise<void> {
  const cookieStore = await cookies();
  cookieStore.set("refreshToken", token, {
    httpOnly: true,
    secure: process.env.NODE_ENV === "production",
    sameSite: "lax",
    maxAge: 30 * 24 * 60 * 60,
    path: "/",
  });
}

export async function clearRefreshTokenCookie(): Promise<void> {
  const cookieStore = await cookies();
  cookieStore.delete("refreshToken");
}

export async function getRefreshToken(fallbackBodyToken?: string): Promise<string | null> {
  const cookieStore = await cookies();
  const fromCookie = cookieStore.get("refreshToken")?.value;
  if (fromCookie) {
    return fromCookie;
  }
  if (fallbackBodyToken && typeof fallbackBodyToken === "string") {
    return fallbackBodyToken;
  }
  return null;
}

export function getUserFromRequest(request: Request): TokenPayload | null {
  const authHeader = request.headers.get("authorization");
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return null;
  }

  const token = authHeader.substring(7);
  return verifyAccessToken(token);
}
