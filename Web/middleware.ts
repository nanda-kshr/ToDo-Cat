import { NextRequest, NextResponse } from "next/server";

const ALLOWED_ORIGIN_PATTERNS = [
  /^https?:\/\/localhost(:\d+)?$/,
  /^https?:\/\/127\.0\.0\.1(:\d+)?$/,
  /^https:\/\/todo-cat-web\.vercel\.app$/,
  /^https:\/\/to-do-cat\.vercel\.app$/,
  /^https:\/\/todocat\.instaroid\.page$/,
];

function isOriginAllowed(origin: string | null): boolean {
  if (!origin) return false;
  return ALLOWED_ORIGIN_PATTERNS.some((pattern) => pattern.test(origin));
}

export function middleware(request: NextRequest) {
  const origin = request.headers.get("origin");
  const isAllowed = isOriginAllowed(origin);

  // If origin is allowed, mirror back that origin; otherwise fallback to production origin
  const allowOrigin = isAllowed && origin ? origin : "https://todo-cat-web.vercel.app";

  const corsHeaders: Record<string, string> = {
    "Access-Control-Allow-Origin": allowOrigin,
    "Access-Control-Allow-Methods": "GET, POST, PATCH, PUT, DELETE, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, Authorization, Accept, X-Requested-With",
    "Access-Control-Allow-Credentials": "true",
    "Vary": "Origin",
  };

  // Handle CORS preflight request
  if (request.method === "OPTIONS") {
    return new NextResponse(null, { status: 204, headers: corsHeaders });
  }

  const response = NextResponse.next();
  Object.entries(corsHeaders).forEach(([key, value]) => {
    response.headers.set(key, value);
  });

  return response;
}

export const config = {
  matcher: "/api/:path*",
};
