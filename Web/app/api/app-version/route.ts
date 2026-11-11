import { NextResponse } from "next/server";

const VALID_PLATFORMS = ["android", "ios", "macos", "linux", "web"] as const;
type Platform = (typeof VALID_PLATFORMS)[number];

interface PlatformVersionConfig {
  latestVersion: string;
  latestBuildNumber: number;
  minSupportedVersion: string;
  minSupportedBuildNumber: number;
  updateUrl: string;
}

function getPlatformConfig(platform: Platform): PlatformVersionConfig {
  switch (platform) {
    case "android":
      return {
        latestVersion: process.env.APP_ANDROID_LATEST_VERSION || "1.0.2",
        latestBuildNumber: parseInt(process.env.APP_ANDROID_LATEST_BUILD || "6", 10),
        minSupportedVersion: process.env.APP_ANDROID_MIN_VERSION || "1.0.0",
        minSupportedBuildNumber: parseInt(process.env.APP_ANDROID_MIN_BUILD || "1", 10),
        updateUrl:
          process.env.APP_ANDROID_UPDATE_URL ||
          "https://play.google.com/store/apps/details?id=com.todocat.app",
      };
    case "ios":
      return {
        latestVersion: process.env.APP_IOS_LATEST_VERSION || "1.0.0",
        latestBuildNumber: parseInt(process.env.APP_IOS_LATEST_BUILD || "1", 10),
        minSupportedVersion: process.env.APP_IOS_MIN_VERSION || "1.0.0",
        minSupportedBuildNumber: parseInt(process.env.APP_IOS_MIN_BUILD || "1", 10),
        updateUrl:
          process.env.APP_IOS_UPDATE_URL ||
          "https://apps.apple.com/app/todocat/id6738900000",
      };
    case "macos":
      return {
        latestVersion: process.env.APP_MACOS_LATEST_VERSION || "1.0.2",
        latestBuildNumber: parseInt(process.env.APP_MACOS_LATEST_BUILD || "8", 10),
        minSupportedVersion: process.env.APP_MACOS_MIN_VERSION || "1.0.0",
        minSupportedBuildNumber: parseInt(process.env.APP_MACOS_MIN_BUILD || "1", 10),
        updateUrl:
          process.env.APP_MACOS_UPDATE_URL ||
          "https://github.com/nanda-kshr/ToDo-Cat/releases/latest",
      };
    case "linux":
      return {
        latestVersion: process.env.APP_LINUX_LATEST_VERSION || "1.0.2",
        latestBuildNumber: parseInt(process.env.APP_LINUX_LATEST_BUILD || "8", 10),
        minSupportedVersion: process.env.APP_LINUX_MIN_VERSION || "1.0.0",
        minSupportedBuildNumber: parseInt(process.env.APP_LINUX_MIN_BUILD || "1", 10),
        updateUrl:
          process.env.APP_LINUX_UPDATE_URL ||
          "https://github.com/nanda-kshr/ToDo-Cat/releases/latest",
      };
    case "web":
      return {
        latestVersion: "1.0.0",
        latestBuildNumber: 1,
        minSupportedVersion: "1.0.0",
        minSupportedBuildNumber: 1,
        updateUrl: "https://to-do-cat.vercel.app",
      };
  }
}

export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const platformParam = (searchParams.get("platform") || "android").toLowerCase();

    if (!VALID_PLATFORMS.includes(platformParam as Platform)) {
      return NextResponse.json(
        {
          message: `Unsupported platform '${platformParam}'. Supported platforms: ${VALID_PLATFORMS.join(", ")}`,
        },
        { status: 400 }
      );
    }

    const platform = platformParam as Platform;
    const config = getPlatformConfig(platform);

    return NextResponse.json({
      platform,
      ...config,
    });
  } catch (error: unknown) {
    if ((error as { digest?: string })?.digest?.startsWith("NEXT_")) {
      throw error;
    }
    console.error("GET /api/app-version error:", error);
    return NextResponse.json({ message: "Internal server error" }, { status: 500 });
  }
}
