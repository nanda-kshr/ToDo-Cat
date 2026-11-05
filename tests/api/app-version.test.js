const { test, describe } = require("node:test");
const assert = require("node:assert");

const VALID_PLATFORMS = ["android", "ios", "web"];

function getPlatformConfig(platform) {
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

async function handleGetAppVersion(reqUrl) {
  const url = new URL(reqUrl, "http://localhost:3000");
  const platformParam = (url.searchParams.get("platform") || "android").toLowerCase();

  if (!VALID_PLATFORMS.includes(platformParam)) {
    return {
      status: 400,
      body: {
        message: `Unsupported platform '${platformParam}'. Supported platforms: ${VALID_PLATFORMS.join(", ")}`,
      },
    };
  }

  const platform = platformParam;
  const config = getPlatformConfig(platform);

  return {
    status: 200,
    body: {
      platform,
      ...config,
    },
  };
}

describe("GET /api/app-version", () => {
  test("Happy path: default request returns 200 with Android config and correct Play Store URL", async () => {
    const res = await handleGetAppVersion("/api/app-version");
    assert.strictEqual(res.status, 200);
    assert.strictEqual(res.body.platform, "android");
    assert.strictEqual(
      res.body.updateUrl,
      "https://play.google.com/store/apps/details?id=com.todocat.app"
    );
    assert.strictEqual(res.body.latestVersion, "1.0.2");
    assert.strictEqual(res.body.latestBuildNumber, 6);
    assert.strictEqual(res.body.minSupportedVersion, "1.0.0");
    assert.strictEqual(res.body.minSupportedBuildNumber, 1);
    assert.ok(res.body.latestBuildNumber >= res.body.minSupportedBuildNumber);
  });

  test("Happy path: explicit platform=android returns 200 with Android config", async () => {
    const res = await handleGetAppVersion("/api/app-version?platform=android");
    assert.strictEqual(res.status, 200);
    assert.strictEqual(res.body.platform, "android");
    assert.ok(res.body.updateUrl.includes("play.google.com"));
  });

  test("Happy path: platform=ios returns 200 with iOS config", async () => {
    const res = await handleGetAppVersion("/api/app-version?platform=ios");
    assert.strictEqual(res.status, 200);
    assert.strictEqual(res.body.platform, "ios");
    assert.ok(res.body.updateUrl.includes("apps.apple.com"));
  });

  test("Happy path: platform=web returns 200 with Web config", async () => {
    const res = await handleGetAppVersion("/api/app-version?platform=web");
    assert.strictEqual(res.status, 200);
    assert.strictEqual(res.body.platform, "web");
    assert.strictEqual(res.body.updateUrl, "https://to-do-cat.vercel.app");
  });

  test("Edge case: case-insensitivity (platform=ANDROID) parses correctly as android", async () => {
    const res = await handleGetAppVersion("/api/app-version?platform=ANDROID");
    assert.strictEqual(res.status, 200);
    assert.strictEqual(res.body.platform, "android");
  });

  test("Validation: unsupported platform returns 400 with error message", async () => {
    const res = await handleGetAppVersion("/api/app-version?platform=blackberry");
    assert.strictEqual(res.status, 400);
    assert.ok(res.body.message.includes("Unsupported platform"));
  });

  test("Validation: unknown random platform returns 400", async () => {
    const res = await handleGetAppVersion("/api/app-version?platform=fake_os");
    assert.strictEqual(res.status, 400);
    assert.ok(res.body.message.includes("Unsupported platform"));
  });

  test("Config: environment variables override latest version and build number", async () => {
    process.env.APP_ANDROID_LATEST_BUILD = "99";
    process.env.APP_ANDROID_LATEST_VERSION = "2.0.0";
    try {
      const res = await handleGetAppVersion("/api/app-version?platform=android");
      assert.strictEqual(res.status, 200);
      assert.strictEqual(res.body.latestBuildNumber, 99);
      assert.strictEqual(res.body.latestVersion, "2.0.0");
    } finally {
      delete process.env.APP_ANDROID_LATEST_BUILD;
      delete process.env.APP_ANDROID_LATEST_VERSION;
    }
  });
});
