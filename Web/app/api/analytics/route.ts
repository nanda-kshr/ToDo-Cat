import { NextResponse } from "next/server";
import { connectDB } from "@/lib/mongodb";
import { Task } from "@/models/Task";
import { getUserFromRequest } from "@/lib/auth";
import { getCachedTasks } from "@/lib/taskCache";

export async function GET(request: Request) {
  try {
    const payload = getUserFromRequest(request);
    if (!payload?.userId) {
      return NextResponse.json({ message: "Unauthorized" }, { status: 401 });
    }

    const { searchParams } = new URL(request.url);
    const fromParam = searchParams.get("from") || searchParams.get("startDate");
    const toParam = searchParams.get("to") || searchParams.get("endDate");
    const period = searchParams.get("period")?.toLowerCase();
    const dateField = searchParams.get("dateField") === "dueDate" ? "dueDate" : "createdAt";

    const now = new Date();
    const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const endOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59, 999);

    let startDate: Date | null = null;
    let endDate: Date | null = null;

    if (period === "today") {
      startDate = startOfToday;
      endDate = endOfToday;
    } else if (period === "7d") {
      startDate = new Date(startOfToday);
      startDate.setDate(startDate.getDate() - 6);
      endDate = endOfToday;
    } else if (period === "30d") {
      startDate = new Date(startOfToday);
      startDate.setDate(startDate.getDate() - 29);
      endDate = endOfToday;
    } else if (period === "this_month") {
      startDate = new Date(now.getFullYear(), now.getMonth(), 1);
      endDate = endOfToday;
    }

    if (fromParam) {
      const parsed = new Date(fromParam);
      if (!isNaN(parsed.getTime())) {
        startDate = parsed;
      }
    }

    if (toParam) {
      const parsed = new Date(toParam);
      if (!isNaN(parsed.getTime())) {
        // If date only string like YYYY-MM-DD, set to end of that day
        if (toParam.length === 10) {
          parsed.setHours(23, 59, 59, 999);
        }
        endDate = parsed;
      }
    }

    const hasDateFilter = Boolean(startDate || endDate);

    type TaskLike = {
      _id: unknown;
      title: string;
      completed: boolean;
      dueDate?: Date | string | null;
      priority?: string;
      category?: string;
      createdAt?: Date | string;
      updatedAt?: Date | string;
    };

    let tasks: TaskLike[] = [];
    let cacheHit = false;

    // Use task cache if no custom date filter is active and cache is available
    if (!hasDateFilter) {
      const cached = getCachedTasks(payload.userId);
      if (cached) {
        tasks = cached as TaskLike[];
        cacheHit = true;
      }
    }

    if (!cacheHit) {
      await connectDB();
      const filter: Record<string, unknown> = { userId: payload.userId };

      if (hasDateFilter) {
        const dateCondition: Record<string, Date> = {};
        if (startDate) dateCondition.$gte = startDate;
        if (endDate) dateCondition.$lte = endDate;
        filter[dateField] = dateCondition;
      }

      tasks = await Task.find(filter).sort({ createdAt: -1 }).lean();
    }

    // 1. Summary
    const total = tasks.length;
    const completed = tasks.filter((t) => t.completed).length;
    const pending = total - completed;
    const completionRate = total === 0 ? 0 : Math.round((completed / total) * 100);

    // 2. By Priority
    const byPriority = {
      high: { total: 0, completed: 0, pending: 0 },
      medium: { total: 0, completed: 0, pending: 0 },
      low: { total: 0, completed: 0, pending: 0 },
    };

    for (const t of tasks) {
      const p = (t.priority && t.priority in byPriority)
        ? (t.priority as keyof typeof byPriority)
        : "medium";
      byPriority[p].total++;
      if (t.completed) {
        byPriority[p].completed++;
      } else {
        byPriority[p].pending++;
      }
    }

    // 3. By Category
    const categoryMap = new Map<string, { total: number; completed: number; pending: number }>();
    for (const t of tasks) {
      const cat = t.category && t.category.trim() ? t.category.trim() : "General";
      if (!categoryMap.has(cat)) {
        categoryMap.set(cat, { total: 0, completed: 0, pending: 0 });
      }
      const stats = categoryMap.get(cat)!;
      stats.total++;
      if (t.completed) {
        stats.completed++;
      } else {
        stats.pending++;
      }
    }

    const byCategory = Array.from(categoryMap.entries()).map(([category, stats]) => ({
      category,
      ...stats,
    }));

    // 4. Due Status
    let overdue = 0;
    let dueToday = 0;
    let upcoming = 0;
    let noDueDate = 0;

    for (const t of tasks) {
      if (!t.dueDate) {
        noDueDate++;
      } else {
        const due = new Date(t.dueDate);
        if (due < startOfToday) {
          if (!t.completed) overdue++;
        } else if (due <= endOfToday) {
          if (!t.completed) dueToday++;
        } else {
          if (!t.completed) upcoming++;
        }
      }
    }

    // 5. 7-Day Completion Trend
    const trendMap = new Map<string, { date: string; completed: number; created: number }>();
    for (let i = 6; i >= 0; i--) {
      const d = new Date(startOfToday);
      d.setDate(d.getDate() - i);
      const dateKey = d.toISOString().split("T")[0];
      trendMap.set(dateKey, { date: dateKey, completed: 0, created: 0 });
    }

    for (const t of tasks) {
      if (t.createdAt) {
        const createdKey = new Date(t.createdAt).toISOString().split("T")[0];
        if (trendMap.has(createdKey)) {
          trendMap.get(createdKey)!.created++;
        }
      }
      if (t.completed && t.updatedAt) {
        const completedKey = new Date(t.updatedAt).toISOString().split("T")[0];
        if (trendMap.has(completedKey)) {
          trendMap.get(completedKey)!.completed++;
        }
      }
    }

    const completionTrend = Array.from(trendMap.values());

    return NextResponse.json(
      {
        filters: {
          from: startDate ? startDate.toISOString() : null,
          to: endDate ? endDate.toISOString() : null,
          period: period || null,
          dateField,
        },
        summary: {
          total,
          completed,
          pending,
          completionRate,
        },
        byPriority,
        byCategory,
        dueStatus: {
          overdue,
          dueToday,
          upcoming,
          noDueDate,
        },
        completionTrend,
      },
      { headers: { "X-Cache": cacheHit ? "HIT" : "MISS" } }
    );
  } catch (error: unknown) {
    if ((error as { digest?: string })?.digest?.startsWith("NEXT_")) {
      throw error;
    }
    console.error("GET /api/analytics error:", error);
    return NextResponse.json({ message: "Internal server error" }, { status: 500 });
  }
}
