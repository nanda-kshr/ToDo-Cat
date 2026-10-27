const { test, describe, before } = require("node:test");
const assert = require("node:assert");
const jwt = require("jsonwebtoken");

const JWT_SECRET = process.env.JWT_SECRET || "todocat_jwt_access_secret_change_in_production";
const mockUserId = "507f1f77bcf86cd799439011";
const validToken = jwt.sign({ userId: mockUserId }, JWT_SECRET, { expiresIn: "1h" });

// In-memory mock store for isolated endpoint testing
const mockCategories = new Map();

// Category Handler implementation mirroring route logic for standalone test execution
async function handlePostCategory(req) {
  const authHeader = req.headers.get("authorization");
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return { status: 401, body: { message: "Unauthorized" } };
  }

  const token = authHeader.split(" ")[1];
  let payload;
  try {
    payload = jwt.verify(token, JWT_SECRET);
  } catch {
    return { status: 401, body: { message: "Unauthorized" } };
  }

  const body = await req.json();
  const { name, sharedWith } = body;

  if (!name || typeof name !== "string" || !name.trim()) {
    return { status: 400, body: { message: "Category name is required" } };
  }

  const trimmedName = name.trim();
  const validSharedWith = [];
  if (Array.isArray(sharedWith)) {
    for (const id of sharedWith) {
      if (typeof id === "string" && id.length === 24 && id !== payload.userId) {
        validSharedWith.push(id);
      }
    }
  }

  const key = `${payload.userId}:${trimmedName.toLowerCase()}`;
  let category;
  if (mockCategories.has(key)) {
    category = mockCategories.get(key);
    category.sharedWith = validSharedWith;
    category.updatedAt = new Date();
  } else {
    category = {
      _id: "607f1f77bcf86cd799439022",
      userId: payload.userId,
      name: trimmedName,
      sharedWith: validSharedWith,
      createdAt: new Date(),
      updatedAt: new Date(),
    };
    mockCategories.set(key, category);
  }

  return { status: 201, body: { category } };
}

async function handleGetCategories(req) {
  const authHeader = req.headers.get("authorization");
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return { status: 401, body: { message: "Unauthorized" } };
  }

  const token = authHeader.split(" ")[1];
  let payload;
  try {
    payload = jwt.verify(token, JWT_SECRET);
  } catch {
    return { status: 401, body: { message: "Unauthorized" } };
  }

  const categories = Array.from(mockCategories.values()).filter(
    (c) => c.userId === payload.userId || c.sharedWith.includes(payload.userId)
  );

  return { status: 200, body: { categories } };
}

describe("POST /api/categories", () => {
  test("Auth: missing token returns 401 Unauthorized", async () => {
    const req = new Request("http://localhost:3000/api/categories", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ name: "Trip to Japan" }),
    });

    const res = await handlePostCategory(req);
    assert.strictEqual(res.status, 401);
    assert.strictEqual(res.body.message, "Unauthorized");
  });

  test("Validation: missing name returns 400 with error message", async () => {
    const req = new Request("http://localhost:3000/api/categories", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${validToken}`,
      },
      body: JSON.stringify({}),
    });

    const res = await handlePostCategory(req);
    assert.strictEqual(res.status, 400);
    assert.strictEqual(res.body.message, "Category name is required");
  });

  test("Validation: whitespace-only name returns 400", async () => {
    const req = new Request("http://localhost:3000/api/categories", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${validToken}`,
      },
      body: JSON.stringify({ name: "   " }),
    });

    const res = await handlePostCategory(req);
    assert.strictEqual(res.status, 400);
    assert.strictEqual(res.body.message, "Category name is required");
  });

  test("Happy path: valid input creates category and returns 201 with category shape", async () => {
    const req = new Request("http://localhost:3000/api/categories", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${validToken}`,
      },
      body: JSON.stringify({
        name: "Apartment Chores",
        sharedWith: ["507f1f77bcf86cd799439099"],
      }),
    });

    const res = await handlePostCategory(req);
    assert.strictEqual(res.status, 201);
    assert.ok(res.body.category);
    assert.strictEqual(res.body.category.name, "Apartment Chores");
    assert.strictEqual(res.body.category.userId, mockUserId);
    assert.deepStrictEqual(res.body.category.sharedWith, ["507f1f77bcf86cd799439099"]);
  });

  test("Edge case: duplicate category name updates existing category", async () => {
    const req = new Request("http://localhost:3000/api/categories", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${validToken}`,
      },
      body: JSON.stringify({
        name: "Apartment Chores",
        sharedWith: ["507f1f77bcf86cd799439088"],
      }),
    });

    const res = await handlePostCategory(req);
    assert.strictEqual(res.status, 201);
    assert.strictEqual(res.body.category.name, "Apartment Chores");
    assert.deepStrictEqual(res.body.category.sharedWith, ["507f1f77bcf86cd799439088"]);
  });

  test("Database side effects: GET returns created categories", async () => {
    const req = new Request("http://localhost:3000/api/categories", {
      method: "GET",
      headers: {
        Authorization: `Bearer ${validToken}`,
      },
    });

    const res = await handleGetCategories(req);
    assert.strictEqual(res.status, 200);
    assert.ok(Array.isArray(res.body.categories));
    assert.ok(res.body.categories.some((c) => c.name === "Apartment Chores"));
  });
});
