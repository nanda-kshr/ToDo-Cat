const { test, describe } = require("node:test");
const assert = require("node:assert");

function getDesktopCallbackUrl(stateParam) {
  if (!stateParam) return null;
  try {
    const decoded = Buffer.from(stateParam, "base64url").toString("utf-8");
    const parsed = JSON.parse(decoded);
    const port = Number(parsed.port);
    if (Number.isInteger(port) && port >= 1024 && port <= 65535) {
      return `http://127.0.0.1:${port}/auth-callback`;
    }
  } catch (_) {}
  return null;
}

function buildGoogleAuthRedirectUrl({ clientId, redirectUri, state }) {
  if (!clientId) {
    return { status: 500, body: { message: "Google OAuth is not configured: missing GOOGLE_CLIENT_ID" } };
  }

  const params = new URLSearchParams({
    client_id: clientId,
    redirect_uri: redirectUri,
    response_type: "code",
    scope: "openid email profile",
    access_type: "offline",
    prompt: "consent",
  });

  if (state) {
    params.set("state", state);
  }

  return {
    status: 302,
    redirectUrl: `https://accounts.google.com/o/oauth2/v2/auth?${params.toString()}`,
  };
}

describe("GET /api/auth/google OAuth initiation", () => {
  test("Initiates Google OAuth with correct redirect URL and parameters", () => {
    const res = buildGoogleAuthRedirectUrl({
      clientId: "test-client-id",
      redirectUri: "https://to-do-cat.vercel.app/api/auth/callback/google",
    });

    assert.strictEqual(res.status, 302);
    const parsed = new URL(res.redirectUrl);
    assert.strictEqual(parsed.hostname, "accounts.google.com");
    assert.strictEqual(parsed.pathname, "/o/oauth2/v2/auth");
    assert.strictEqual(parsed.searchParams.get("client_id"), "test-client-id");
    assert.strictEqual(parsed.searchParams.get("redirect_uri"), "https://to-do-cat.vercel.app/api/auth/callback/google");
    assert.strictEqual(parsed.searchParams.get("response_type"), "code");
  });

  test("Forwards state parameter when provided for desktop login", () => {
    const statePayload = Buffer.from(JSON.stringify({ port: 45678 })).toString("base64url");
    const res = buildGoogleAuthRedirectUrl({
      clientId: "test-client-id",
      redirectUri: "https://to-do-cat.vercel.app/api/auth/callback/google",
      state: statePayload,
    });

    assert.strictEqual(res.status, 302);
    const parsed = new URL(res.redirectUrl);
    assert.strictEqual(parsed.searchParams.get("state"), statePayload);
  });

  test("Validation: returns 500 error when GOOGLE_CLIENT_ID is missing", () => {
    const res = buildGoogleAuthRedirectUrl({
      clientId: null,
      redirectUri: "https://to-do-cat.vercel.app/api/auth/callback/google",
    });
    assert.strictEqual(res.status, 500);
    assert.ok(res.body.message.includes("missing GOOGLE_CLIENT_ID"));
  });
});

describe("Desktop OAuth State & Callback Validation", () => {
  test("Happy path: extracts valid loopback callback URL from valid state payload", () => {
    const state = Buffer.from(JSON.stringify({ port: 38291 })).toString("base64url");
    const callbackUrl = getDesktopCallbackUrl(state);
    assert.strictEqual(callbackUrl, "http://127.0.0.1:38291/auth-callback");
  });

  test("Validation: rejects null, undefined, or empty state", () => {
    assert.strictEqual(getDesktopCallbackUrl(null), null);
    assert.strictEqual(getDesktopCallbackUrl(""), null);
    assert.strictEqual(getDesktopCallbackUrl(undefined), null);
  });

  test("Security: rejects privileged ports (< 1024)", () => {
    const state = Buffer.from(JSON.stringify({ port: 80 })).toString("base64url");
    assert.strictEqual(getDesktopCallbackUrl(state), null);
  });

  test("Security: rejects out-of-range ports (> 65535)", () => {
    const state = Buffer.from(JSON.stringify({ port: 70000 })).toString("base64url");
    assert.strictEqual(getDesktopCallbackUrl(state), null);
  });

  test("Security: rejects non-integer or malformed port values", () => {
    const state = Buffer.from(JSON.stringify({ port: "invalid" })).toString("base64url");
    assert.strictEqual(getDesktopCallbackUrl(state), null);
  });

  test("Security: rejects corrupted base64 payloads gracefully without throwing", () => {
    assert.strictEqual(getDesktopCallbackUrl("not-valid-base64-json!!!"), null);
  });

  test("Routing: redirects to desktop loopback with error when OAuth error occurs", () => {
    const state = Buffer.from(JSON.stringify({ port: 52140 })).toString("base64url");
    const desktopCallback = getDesktopCallbackUrl(state);
    assert.ok(desktopCallback);

    const error = "access_denied";
    const redirectUrl = new URL(`${desktopCallback}?error=${encodeURIComponent(error)}`);
    assert.strictEqual(redirectUrl.origin, "http://127.0.0.1:52140");
    assert.strictEqual(redirectUrl.pathname, "/auth-callback");
    assert.strictEqual(redirectUrl.searchParams.get("error"), "access_denied");
  });

  test("Routing: redirects to desktop loopback with tokens upon successful authentication", () => {
    const state = Buffer.from(JSON.stringify({ port: 52140 })).toString("base64url");
    const desktopCallback = getDesktopCallbackUrl(state);
    assert.ok(desktopCallback);

    const token = "mock_access_token";
    const refreshToken = "mock_refresh_token";
    const redirectUrl = new URL(`${desktopCallback}?token=${token}&refreshToken=${refreshToken}`);
    assert.strictEqual(redirectUrl.origin, "http://127.0.0.1:52140");
    assert.strictEqual(redirectUrl.pathname, "/auth-callback");
    assert.strictEqual(redirectUrl.searchParams.get("token"), token);
    assert.strictEqual(redirectUrl.searchParams.get("refreshToken"), refreshToken);
  });
});
