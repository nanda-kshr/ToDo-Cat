"use client";

import { Suspense, useEffect, useState, useMemo, useCallback } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import Image from "next/image";
import CatAnimation from "@/components/CatAnimation";
import FriendsView from "@/components/FriendsView";

interface UserProfile {
  id: string;
  email: string;
  name?: string;
  avatar?: string;
}

export type TaskPriority = "low" | "medium" | "high";

export interface TaskItem {
  _id: string;
  title: string;
  description?: string;
  completed: boolean;
  dueDate?: string | null;
  hasTime?: boolean;
  recurrence?: string;
  priority: TaskPriority;
  category: string;
  createdAt: string;
  updatedAt: string;
}

type ViewFilter = "all" | "today" | "upcoming" | "completed" | "friends";

// Check if a date string is today in local time
function isTodayDate(dateStr: string): boolean {
  const d = new Date(dateStr);
  const now = new Date();
  return (
    d.getFullYear() === now.getFullYear() &&
    d.getMonth() === now.getMonth() &&
    d.getDate() === now.getDate()
  );
}

// Check if a date string is before today in local time
function isOverdueDate(dateStr: string): boolean {
  const d = new Date(dateStr);
  const startOfToday = new Date();
  startOfToday.setHours(0, 0, 0, 0);
  return d < startOfToday;
}

// Check if a date string is after today in local time
function isUpcomingDate(dateStr: string): boolean {
  const d = new Date(dateStr);
  const endOfToday = new Date();
  endOfToday.setHours(23, 59, 59, 999);
  return d > endOfToday;
}

// Format date for display
function formatDate(dateStr: string, hasTime?: boolean): string {
  const d = new Date(dateStr);
  const datePart = d.toLocaleDateString(undefined, {
    month: "short",
    day: "numeric",
    year: d.getFullYear() !== new Date().getFullYear() ? "numeric" : undefined,
  });
  if (hasTime) {
    const timePart = d.toLocaleTimeString(undefined, {
      hour: "numeric",
      minute: "2-digit",
    });
    return `${datePart}, ${timePart}`;
  }
  return datePart;
}

function DashboardContent() {
  const router = useRouter();
  const searchParams = useSearchParams();

  const [user, setUser] = useState<UserProfile | null>(null);
  const [loading, setLoading] = useState(true);
  const [tasks, setTasks] = useState<TaskItem[]>([]);
  const [loadingTasks, setLoadingTasks] = useState(false);

  // Filters & Search
  const [activeView, setActiveView] = useState<ViewFilter>("all");
  const [friendsCount, setFriendsCount] = useState<number>(0);
  const [searchQuery, setSearchQuery] = useState("");
  const [priorityFilter, setPriorityFilter] = useState<string>("all");
  const [categoryFilter, setCategoryFilter] = useState<string>("all");

  // Modal State (Create / Edit)
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingTaskId, setEditingTaskId] = useState<string | null>(null);
  const [formTitle, setFormTitle] = useState("");
  const [formDescription, setFormDescription] = useState("");
  const [formDueDate, setFormDueDate] = useState("");
  const [formHasTime, setFormHasTime] = useState(false);
  const [formTime, setFormTime] = useState("");
  const [formRecurrence, setFormRecurrence] = useState("none");
  const [formPriority, setFormPriority] = useState<TaskPriority>("medium");
  const [formCategory, setFormCategory] = useState("General");
  const [formSubmitting, setFormSubmitting] = useState(false);
  const [formError, setFormError] = useState<string | null>(null);

  // Authenticated fetch with automatic token refresh
  const authFetch = useCallback(
    async (url: string, options: RequestInit = {}): Promise<Response> => {
      let token = localStorage.getItem("accessToken");
      const headers = new Headers(options.headers || {});
      if (token) {
        headers.set("Authorization", `Bearer ${token}`);
      }

      let res = await fetch(url, { ...options, headers });

      if (res.status === 401) {
        // Attempt refresh
        try {
          const refreshRes = await fetch("/api/auth/refresh", { method: "POST" });
          if (refreshRes.ok) {
            const refreshData = await refreshRes.json();
            if (refreshData.accessToken && typeof refreshData.accessToken === "string") {
              const newToken = refreshData.accessToken;
              localStorage.setItem("accessToken", newToken);
              headers.set("Authorization", `Bearer ${newToken}`);
              res = await fetch(url, { ...options, headers });
            }
          } else {
            localStorage.removeItem("accessToken");
            router.push("/auth?action=login");
          }
        } catch {
          localStorage.removeItem("accessToken");
          router.push("/auth?action=login");
        }
      }

      return res;
    },
    [router]
  );

  // Initial user & task loading
  useEffect(() => {
    const urlToken = searchParams.get("token");
    if (urlToken) {
      localStorage.setItem("accessToken", urlToken);
      router.replace("/dashboard");
    }

    async function init() {
      try {
        const userRes = await authFetch("/api/auth/me");
        if (userRes.ok) {
          const data = await userRes.json();
          setUser(data.user);
          loadTasks();
          loadFriendsCount();
        } else {
          router.push("/auth?action=login");
        }
      } catch (err) {
        console.error("Dashboard init error:", err);
        router.push("/auth?action=login");
      } finally {
        setLoading(false);
      }
    }

    init();
  }, [authFetch, router, searchParams]);

  const loadTasks = async () => {
    setLoadingTasks(true);
    try {
      const res = await authFetch("/api/tasks");
      if (res.ok) {
        const data = await res.json();
        setTasks(data.tasks || []);
      }
    } catch (err) {
      console.error("Failed to load tasks:", err);
    } finally {
      setLoadingTasks(false);
    }
  };

  const loadFriendsCount = async () => {
    try {
      const res = await authFetch("/api/friends?limit=1");
      if (res.ok) {
        const data = await res.json();
        setFriendsCount(data.pagination?.total ?? data.friends?.length ?? 0);
      }
    } catch (err) {
      console.error("Failed to load friends count:", err);
    }
  };

  const handleLogout = async () => {
    try {
      await fetch("/api/auth/logout", { method: "POST" });
    } catch {
      // ignore
    }
    localStorage.removeItem("accessToken");
    router.push("/");
  };

  // Toggle complete
  const handleToggleComplete = async (task: TaskItem) => {
    const nextCompleted = !task.completed;
    // Optimistic update
    setTasks((prev) =>
      prev.map((t) => (t._id === task._id ? { ...t, completed: nextCompleted } : t))
    );

    try {
      const res = await authFetch(`/api/tasks/${task._id}`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ completed: nextCompleted }),
      });

      if (!res.ok) {
        // Rollback
        setTasks((prev) =>
          prev.map((t) => (t._id === task._id ? { ...t, completed: task.completed } : t))
        );
      }
    } catch {
      // Rollback
      setTasks((prev) =>
        prev.map((t) => (t._id === task._id ? { ...t, completed: task.completed } : t))
      );
    }
  };

  // Delete task
  const handleDeleteTask = async (id: string) => {
    const originalTasks = tasks;
    setTasks((prev) => prev.filter((t) => t._id !== id));

    try {
      const res = await authFetch(`/api/tasks/${id}`, { method: "DELETE" });
      if (!res.ok) {
        setTasks(originalTasks);
      }
    } catch {
      setTasks(originalTasks);
    }
  };

  // Open modal for Create
  const handleOpenCreate = () => {
    setEditingTaskId(null);
    setFormTitle("");
    setFormDescription("");
    setFormDueDate("");
    setFormHasTime(false);
    setFormTime("");
    setFormRecurrence("none");
    setFormPriority("medium");
    setFormCategory("General");
    setFormError(null);
    setIsModalOpen(true);
  };

  // Open modal for Edit
  const handleOpenEdit = (task: TaskItem) => {
    setEditingTaskId(task._id);
    setFormTitle(task.title);
    setFormDescription(task.description || "");
    if (task.dueDate) {
      const d = new Date(task.dueDate);
      const yyyy = d.getFullYear();
      const mm = String(d.getMonth() + 1).padStart(2, "0");
      const dd = String(d.getDate()).padStart(2, "0");
      setFormDueDate(`${yyyy}-${mm}-${dd}`);
      if (task.hasTime) {
        const hh = String(d.getHours()).padStart(2, "0");
        const min = String(d.getMinutes()).padStart(2, "0");
        setFormTime(`${hh}:${min}`);
        setFormHasTime(true);
      } else {
        setFormTime("");
        setFormHasTime(false);
      }
    } else {
      setFormDueDate("");
      setFormTime("");
      setFormHasTime(false);
    }
    setFormRecurrence(task.recurrence || "none");
    setFormPriority(task.priority);
    setFormCategory(task.category || "General");
    setFormError(null);
    setIsModalOpen(true);
  };

  // Save Task (Create or Update)
  const handleSubmitTask = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!formTitle.trim()) {
      setFormError("Task title is required");
      return;
    }

    setFormSubmitting(true);
    setFormError(null);

    let finalDueDate: string | null = null;
    if (formDueDate) {
      if (formHasTime && formTime) {
        finalDueDate = new Date(`${formDueDate}T${formTime}:00`).toISOString();
      } else {
        finalDueDate = new Date(`${formDueDate}T00:00:00`).toISOString();
      }
    }

    const payload = {
      title: formTitle.trim(),
      description: formDescription.trim(),
      dueDate: finalDueDate,
      hasTime: formHasTime && Boolean(formTime),
      recurrence: formRecurrence,
      priority: formPriority,
      category: formCategory.trim() || "General",
    };

    try {
      if (editingTaskId) {
        const res = await authFetch(`/api/tasks/${editingTaskId}`, {
          method: "PATCH",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(payload),
        });

        if (res.ok) {
          const data = await res.json();
          setTasks((prev) =>
            prev.map((t) => (t._id === editingTaskId ? data.task : t))
          );
          setIsModalOpen(false);
        } else {
          const err = await res.json();
          setFormError(err.message || "Failed to update task");
        }
      } else {
        const res = await authFetch("/api/tasks", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(payload),
        });

        if (res.ok) {
          const data = await res.json();
          setTasks((prev) => [data.task, ...prev]);
          setIsModalOpen(false);
        } else {
          const err = await res.json();
          setFormError(err.message || "Failed to create task");
        }
      }
    } catch {
      setFormError("An unexpected error occurred");
    } finally {
      setFormSubmitting(false);
    }
  };

  // Categories list
  const categories = useMemo(() => {
    const set = new Set<string>();
    tasks.forEach((t) => {
      if (t.category) set.add(t.category);
    });
    return Array.from(set);
  }, [tasks]);

  // View counts
  const viewCounts = useMemo(() => {
    return {
      all: tasks.length,
      today: tasks.filter((t) => t.dueDate && (isTodayDate(t.dueDate) || (!t.completed && isOverdueDate(t.dueDate)))).length,
      upcoming: tasks.filter((t) => t.dueDate && isUpcomingDate(t.dueDate) && !t.completed).length,
      completed: tasks.filter((t) => t.completed).length,
    };
  }, [tasks]);

  // Filtered tasks
  const filteredTasks = useMemo(() => {
    return tasks.filter((task) => {
      // View filter
      if (activeView === "today") {
        const matchesToday =
          task.dueDate &&
          (isTodayDate(task.dueDate) || (!task.completed && isOverdueDate(task.dueDate)));
        if (!matchesToday) return false;
      } else if (activeView === "upcoming") {
        if (!task.dueDate || !isUpcomingDate(task.dueDate) || task.completed) return false;
      } else if (activeView === "completed") {
        if (!task.completed) return false;
      }

      // Priority filter
      if (priorityFilter !== "all" && task.priority !== priorityFilter) {
        return false;
      }

      // Category filter
      if (categoryFilter !== "all" && task.category.toLowerCase() !== categoryFilter.toLowerCase()) {
        return false;
      }

      // Search query
      if (searchQuery.trim()) {
        const query = searchQuery.toLowerCase();
        const matchesTitle = task.title.toLowerCase().includes(query);
        const matchesDesc = task.description?.toLowerCase().includes(query);
        if (!matchesTitle && !matchesDesc) return false;
      }

      return true;
    });
  }, [tasks, activeView, priorityFilter, categoryFilter, searchQuery]);

  // Cat speed & activity calculation
  const completedCount = tasks.filter((t) => t.completed).length;
  const activeTasksCount = tasks.filter((t) => !t.completed).length;

  // Cat is sleeping (0%) when all tasks are completed or no tasks exist
  // Cat reaches 100% when there are many tasks pending (5 or more)
  const catSpeedPercent = useMemo(() => {
    if (tasks.length === 0 || activeTasksCount === 0) return 0;
    return Math.min(100, Math.round((activeTasksCount / 5) * 100));
  }, [tasks.length, activeTasksCount]);

  const catSpeedMessage = useMemo(() => {
    if (tasks.length === 0) return "No tasks yet • Cat is sleeping peacefully";
    if (activeTasksCount === 0) return "All tasks completed! Cat is sleeping peacefully";
    if (catSpeedPercent >= 100) return `${activeTasksCount} tasks pending • Cat is at 100% maximum speed`;
    if (catSpeedPercent >= 75) return `${activeTasksCount} tasks pending • Cat is sprinting fast`;
    if (catSpeedPercent >= 40) return `${activeTasksCount} tasks pending • Cat is trotting along`;
    return `${activeTasksCount} task pending • Cat is stretching and alert`;
  }, [tasks.length, activeTasksCount, catSpeedPercent]);

  if (loading) {
    return (
      <div className="flex-1 flex items-center justify-center">
        <div className="text-neutral-500 text-sm animate-pulse">Loading TodoCat...</div>
      </div>
    );
  }

  return (
    <div className="flex-1 flex flex-col w-full max-w-5xl mx-auto p-4 sm:p-6 md:p-8 space-y-6">
      {/* Top Navigation */}
      <header className="flex items-center justify-between pb-6 border-b border-neutral-800">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 relative rounded-xl bg-white p-1.5 shadow-sm overflow-hidden flex items-center justify-center">
            <Image src="/logo.svg" alt="TodoCat" fill className="object-contain p-1" priority />
          </div>
          <div>
            <h1 className="font-bold text-white text-lg tracking-tight">TodoCat</h1>
            <p className="text-xs text-neutral-400">Task Management</p>
          </div>
        </div>

        <div className="flex items-center gap-4">
          <div className="text-right hidden sm:block">
            <div className="text-sm font-medium text-neutral-200">
              {user?.name || user?.email?.split("@")[0]}
            </div>
            <div className="text-xs text-neutral-500">{user?.email}</div>
          </div>
          <button
            onClick={handleLogout}
            className="py-2 px-3.5 rounded-xl text-xs font-medium border border-neutral-800 bg-neutral-900 text-neutral-300 hover:bg-neutral-800 hover:text-white transition"
          >
            Sign Out
          </button>
        </div>
      </header>

      {/* Progress & Cat Speed Banner */}
      <div className="bg-neutral-900/80 border border-neutral-800 rounded-2xl p-5 flex flex-col md:flex-row md:items-center justify-between gap-6">
        <div className="flex items-center gap-4">
          <CatAnimation speedPercent={catSpeedPercent} size={48} theme="card" />

          <div className="space-y-1.5">
            <div className="flex items-center gap-2 flex-wrap">
              <span className="text-xs uppercase tracking-wider font-semibold text-neutral-400">
                Cat Speed & Activity
              </span>
              <span
                className={`text-xs font-semibold px-2 py-0.5 rounded-full ${
                  catSpeedPercent === 0
                    ? "bg-indigo-500/10 text-indigo-400 border border-indigo-500/20"
                    : catSpeedPercent >= 100
                    ? "bg-rose-500/10 text-rose-400 border border-rose-500/20"
                    : "bg-amber-500/10 text-amber-400 border border-amber-500/20"
                }`}
              >
                {catSpeedPercent}% Speed
              </span>
              <span className="text-xs text-neutral-500">
                ({completedCount}/{tasks.length} completed)
              </span>
            </div>

            <div className="flex items-center gap-2">
              {catSpeedPercent === 0 ? (
                <svg className="w-4 h-4 text-indigo-400 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z" />
                </svg>
              ) : catSpeedPercent >= 100 ? (
                <svg className="w-4 h-4 text-rose-400 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 10V3L4 14h7v7l9-11h-7z" />
                </svg>
              ) : (
                <svg className="w-4 h-4 text-amber-400 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6" />
                </svg>
              )}
              <p className="text-sm font-medium text-neutral-200">{catSpeedMessage}</p>
            </div>
          </div>
        </div>

        <div className="flex-1 max-w-xs md:max-w-sm flex items-center gap-3">
          <div className="w-full bg-neutral-800 rounded-full h-2.5 overflow-hidden">
            <div
              className={`h-2.5 rounded-full transition-all duration-500 ${
                catSpeedPercent === 0
                  ? "bg-indigo-500/40 w-0"
                  : catSpeedPercent >= 100
                  ? "bg-gradient-to-r from-amber-500 to-rose-500"
                  : "bg-gradient-to-r from-emerald-400 to-amber-500"
              }`}
              style={{ width: `${catSpeedPercent}%` }}
            />
          </div>
          <button
            onClick={handleOpenCreate}
            className="shrink-0 flex items-center gap-1.5 bg-white text-neutral-950 hover:bg-neutral-200 font-medium px-4 py-2 rounded-xl text-xs shadow-sm transition"
          >
            <svg className="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M12 4v16m8-8H4" />
            </svg>
            New Task
          </button>
        </div>
      </div>

      {/* Views and Filter Bar */}
      <div className="space-y-3">
        {/* View Tabs */}
        <div className="flex items-center justify-between flex-wrap gap-2">
          <div className="flex items-center gap-1 bg-neutral-900 border border-neutral-800 p-1 rounded-xl">
            {(
              [
                { id: "all", label: "All Tasks", count: viewCounts.all },
                { id: "today", label: "Today", count: viewCounts.today },
                { id: "upcoming", label: "Upcoming", count: viewCounts.upcoming },
                { id: "completed", label: "Completed", count: viewCounts.completed },
                { id: "friends", label: "Friends", count: friendsCount },
              ] as const
            ).map((tab) => (
              <button
                key={tab.id}
                onClick={() => setActiveView(tab.id)}
                className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-medium transition ${
                  activeView === tab.id
                    ? "bg-neutral-800 text-white shadow-sm"
                    : "text-neutral-400 hover:text-neutral-200"
                }`}
              >
                <span>{tab.label}</span>
                <span
                  className={`text-[10px] px-1.5 py-0.2 rounded-full ${
                    activeView === tab.id
                      ? "bg-neutral-700 text-neutral-200"
                      : "bg-neutral-800 text-neutral-400"
                  }`}
                >
                  {tab.count}
                </span>
              </button>
            ))}
          </div>

          <button
            onClick={handleOpenCreate}
            className="md:hidden flex items-center gap-1.5 bg-white text-neutral-950 font-medium px-3 py-1.5 rounded-xl text-xs"
          >
            + New Task
          </button>
        </div>

        {/* Search & Filters Row */}
        {activeView !== "friends" && (
          <div className="flex flex-col sm:flex-row items-stretch sm:items-center gap-2">
          <div className="relative flex-1">
            <svg
              className="w-4 h-4 text-neutral-500 absolute left-3 top-1/2 -translate-y-1/2 pointer-events-none"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
              />
            </svg>
            <input
              type="text"
              placeholder="Search tasks by title or description..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full bg-neutral-900 border border-neutral-800 rounded-xl pl-9 pr-3 py-2 text-xs text-white placeholder-neutral-500 focus:outline-none focus:border-neutral-600 transition"
            />
          </div>

          <div className="flex items-center gap-2">
            {/* Priority Filter */}
            <select
              value={priorityFilter}
              onChange={(e) => setPriorityFilter(e.target.value)}
              className="bg-neutral-900 border border-neutral-800 rounded-xl px-3 py-2 text-xs text-neutral-300 focus:outline-none focus:border-neutral-600 transition"
            >
              <option value="all">All Priorities</option>
              <option value="high">High Priority</option>
              <option value="medium">Medium Priority</option>
              <option value="low">Low Priority</option>
            </select>

            {/* Category Filter */}
            <select
              value={categoryFilter}
              onChange={(e) => setCategoryFilter(e.target.value)}
              className="bg-neutral-900 border border-neutral-800 rounded-xl px-3 py-2 text-xs text-neutral-300 focus:outline-none focus:border-neutral-600 transition"
            >
              <option value="all">All Categories</option>
              {categories.map((c) => (
                <option key={c} value={c}>
                  {c}
                </option>
              ))}
            </select>
          </div>
        </div>
        )}
      </div>

      {activeView === "friends" ? (
        <FriendsView authFetch={authFetch} onCountUpdate={setFriendsCount} />
      ) : (
        /* Task List */
        <div className="space-y-2">
        {loadingTasks ? (
          <div className="text-center py-12 text-xs text-neutral-500">Loading tasks...</div>
        ) : filteredTasks.length === 0 ? (
          <div className="bg-neutral-900/40 border border-dashed border-neutral-800 rounded-2xl p-12 text-center flex flex-col items-center justify-center">
            <div className="w-12 h-12 rounded-xl bg-neutral-900 border border-neutral-800 flex items-center justify-center text-neutral-400 mb-3">
              <svg className="w-6 h-6 text-neutral-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4" />
              </svg>
            </div>
            <p className="text-sm font-medium text-neutral-300 mb-1">No tasks found</p>
            <p className="text-xs text-neutral-500 mb-4">
              {searchQuery || priorityFilter !== "all" || categoryFilter !== "all"
                ? "Try adjusting your search or filters"
                : "Create a task to keep TodoCat running fast!"}
            </p>
            <button
              onClick={handleOpenCreate}
              className="bg-neutral-800 hover:bg-neutral-700 text-white px-3.5 py-1.5 rounded-xl text-xs font-medium transition"
            >
              + Create First Task
            </button>
          </div>
        ) : (
          filteredTasks.map((task) => {
            // Due date calculations
            const hasDue = Boolean(task.dueDate);
            const isDueToday = hasDue && isTodayDate(task.dueDate!);
            const isDueOverdue = hasDue && !task.completed && isOverdueDate(task.dueDate!);
            const isDueUpcoming = hasDue && isUpcomingDate(task.dueDate!);

            return (
              <div
                key={task._id}
                className={`group flex items-start justify-between gap-3 p-4 rounded-2xl border transition ${
                  task.completed
                    ? "bg-neutral-950/40 border-neutral-900 opacity-60"
                    : "bg-neutral-900/60 hover:bg-neutral-900 border-neutral-800/80"
                }`}
              >
                {/* Checkbox & Details */}
                <div className="flex items-start gap-3.5 flex-1 min-w-0">
                  <button
                    onClick={() => handleToggleComplete(task)}
                    className={`mt-0.5 w-5 h-5 rounded-lg border flex items-center justify-center transition shrink-0 ${
                      task.completed
                        ? "bg-emerald-500 border-emerald-500 text-black"
                        : "border-neutral-700 hover:border-neutral-500 bg-neutral-800/50"
                    }`}
                  >
                    {task.completed && (
                      <svg className="w-3.5 h-3.5" viewBox="0 0 20 20" fill="currentColor">
                        <path
                          fillRule="evenodd"
                          d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"
                          clipRule="evenodd"
                        />
                      </svg>
                    )}
                  </button>

                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2 flex-wrap">
                      <span
                        className={`text-sm font-medium break-words ${
                          task.completed ? "line-through text-neutral-500" : "text-neutral-100"
                        }`}
                      >
                        {task.title}
                      </span>

                      {/* Priority Badge */}
                      <span
                        className={`text-[10px] font-medium px-2 py-0.5 rounded-full border ${
                          task.priority === "high"
                            ? "bg-rose-500/10 text-rose-400 border-rose-500/20"
                            : task.priority === "medium"
                            ? "bg-amber-500/10 text-amber-400 border-amber-500/20"
                            : "bg-emerald-500/10 text-emerald-400 border-emerald-500/20"
                        }`}
                      >
                        {task.priority.toUpperCase()}
                      </span>

                      {/* Category Badge */}
                      {task.category && (
                        <span className="text-[10px] font-medium px-2 py-0.5 rounded-full bg-neutral-800 text-neutral-400 border border-neutral-700">
                          {task.category}
                        </span>
                      )}

                      {/* Due Date Badge */}
                      {hasDue && (
                        <span
                          className={`text-[10px] font-medium px-2 py-0.5 rounded-full flex items-center gap-1.5 border ${
                            isDueOverdue
                              ? "bg-red-500/10 text-red-400 border-red-500/20 font-semibold"
                              : isDueToday
                              ? "bg-amber-500/10 text-amber-300 border-amber-500/20 font-semibold"
                              : isDueUpcoming
                              ? "bg-blue-500/10 text-blue-400 border-blue-500/20"
                              : "bg-neutral-800 text-neutral-400 border-neutral-700"
                          }`}
                        >
                          <svg className="w-3 h-3 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path
                              strokeLinecap="round"
                              strokeLinejoin="round"
                              strokeWidth={2}
                              d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"
                            />
                          </svg>
                          <span>
                            {isDueOverdue
                              ? `Overdue (${formatDate(task.dueDate!, task.hasTime)})`
                              : isDueToday
                              ? (task.hasTime ? `Due Today, ${new Date(task.dueDate!).toLocaleTimeString(undefined, { hour: "numeric", minute: "2-digit" })}` : "Due Today")
                              : formatDate(task.dueDate!, task.hasTime)}
                          </span>
                        </span>
                      )}

                      {/* Recurrence Badge */}
                      {task.recurrence && task.recurrence !== "none" && (
                        <span className="text-[10px] font-medium px-2 py-0.5 rounded-full bg-neutral-800 text-neutral-300 border border-neutral-700 flex items-center gap-1">
                          <svg className="w-3 h-3 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
                          </svg>
                          <span className="capitalize">{task.recurrence}</span>
                        </span>
                      )}
                    </div>

                    {task.description && (
                      <p
                        className={`text-xs mt-1 break-words ${
                          task.completed ? "text-neutral-600" : "text-neutral-400"
                        }`}
                      >
                        {task.description}
                      </p>
                    )}
                  </div>
                </div>

                {/* Edit & Delete actions */}
                <div className="flex items-center gap-1 shrink-0 opacity-80 group-hover:opacity-100 transition">
                  <button
                    onClick={() => handleOpenEdit(task)}
                    title="Edit task"
                    className="p-1.5 rounded-lg text-neutral-400 hover:text-white hover:bg-neutral-800 transition"
                  >
                    <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path
                        strokeLinecap="round"
                        strokeLinejoin="round"
                        strokeWidth={2}
                        d="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z"
                      />
                    </svg>
                  </button>

                  <button
                    onClick={() => handleDeleteTask(task._id)}
                    title="Delete task"
                    className="p-1.5 rounded-lg text-neutral-500 hover:text-rose-400 hover:bg-neutral-800 transition"
                  >
                    <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path
                        strokeLinecap="round"
                        strokeLinejoin="round"
                        strokeWidth={2}
                        d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"
                      />
                    </svg>
                  </button>
                </div>
              </div>
            );
          })
        )}
      </div>
      )}

      {/* Create / Edit Task Modal */}
      {isModalOpen && (
        <div className="fixed inset-0 z-50 bg-black/70 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-neutral-900 border border-neutral-800 rounded-2xl w-full max-w-md p-6 shadow-2xl relative">
            <div className="flex items-center justify-between pb-4 border-b border-neutral-800">
              <h2 className="text-base font-bold text-white">
                {editingTaskId ? "Edit Task" : "Create New Task"}
              </h2>
              <button
                onClick={() => setIsModalOpen(false)}
                aria-label="Close modal"
                className="text-neutral-500 hover:text-neutral-300 p-1.5 rounded-lg hover:bg-neutral-800 transition"
              >
                <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
            </div>

            <form onSubmit={handleSubmitTask} className="mt-4 space-y-4">
              {formError && (
                <div className="p-3 text-xs bg-rose-500/10 border border-rose-500/20 text-rose-400 rounded-xl">
                  {formError}
                </div>
              )}

              {/* Title */}
              <div>
                <label className="block text-xs font-medium text-neutral-300 mb-1">
                  Title <span className="text-rose-400">*</span>
                </label>
                <input
                  type="text"
                  required
                  placeholder="e.g., Feed the cat, complete quarterly review"
                  value={formTitle}
                  onChange={(e) => setFormTitle(e.target.value)}
                  className="w-full bg-neutral-950 border border-neutral-800 rounded-xl px-3 py-2 text-xs text-white placeholder-neutral-500 focus:outline-none focus:border-neutral-600 transition"
                />
              </div>

              {/* Description */}
              <div>
                <label className="block text-xs font-medium text-neutral-300 mb-1">
                  Description (optional)
                </label>
                <textarea
                  rows={3}
                  placeholder="Add extra notes or details..."
                  value={formDescription}
                  onChange={(e) => setFormDescription(e.target.value)}
                  className="w-full bg-neutral-950 border border-neutral-800 rounded-xl px-3 py-2 text-xs text-white placeholder-neutral-500 focus:outline-none focus:border-neutral-600 transition resize-none"
                />
              </div>

              {/* Due Date & Optional Time & Category */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <div>
                  <div className="flex items-center justify-between mb-1">
                    <label className="text-xs font-medium text-neutral-300">
                      Due Date
                    </label>
                    <button
                      type="button"
                      onClick={() => {
                        if (formHasTime) {
                          setFormHasTime(false);
                          setFormTime("");
                        } else {
                          setFormHasTime(true);
                          if (!formTime) setFormTime("12:00");
                        }
                      }}
                      className="text-[11px] text-neutral-400 hover:text-white transition"
                    >
                      {formHasTime ? "Remove time" : "+ Add time"}
                    </button>
                  </div>
                  <div className="flex items-center gap-2">
                    <input
                      type="date"
                      value={formDueDate}
                      onChange={(e) => setFormDueDate(e.target.value)}
                      className="w-full bg-neutral-950 border border-neutral-800 rounded-xl px-3 py-2 text-xs text-white placeholder-neutral-500 focus:outline-none focus:border-neutral-600 transition"
                    />
                    {formHasTime && (
                      <input
                        type="time"
                        value={formTime}
                        onChange={(e) => setFormTime(e.target.value)}
                        className="w-32 bg-neutral-950 border border-neutral-800 rounded-xl px-3 py-2 text-xs text-white placeholder-neutral-500 focus:outline-none focus:border-neutral-600 transition"
                      />
                    )}
                  </div>
                </div>

                <div>
                  <label className="block text-xs font-medium text-neutral-300 mb-1">
                    Category
                  </label>
                  <input
                    type="text"
                    list="category-suggestions"
                    placeholder="General, Work, etc."
                    value={formCategory}
                    onChange={(e) => setFormCategory(e.target.value)}
                    className="w-full bg-neutral-950 border border-neutral-800 rounded-xl px-3 py-2 text-xs text-white placeholder-neutral-500 focus:outline-none focus:border-neutral-600 transition"
                  />
                  <datalist id="category-suggestions">
                    <option value="General" />
                    <option value="Work" />
                    <option value="Personal" />
                    <option value="Shopping" />
                    <option value="Health" />
                  </datalist>
                </div>
              </div>

              {/* Repeat / Recurring */}
              <div>
                <label className="block text-xs font-medium text-neutral-300 mb-1.5">
                  Repeat
                </label>
                <div className="grid grid-cols-5 gap-1.5">
                  {[
                    { label: "None", value: "none" },
                    { label: "Daily", value: "daily" },
                    { label: "Weekly", value: "weekly" },
                    { label: "Monthly", value: "monthly" },
                    { label: "Yearly", value: "yearly" },
                  ].map((r) => (
                    <button
                      key={r.value}
                      type="button"
                      onClick={() => setFormRecurrence(r.value)}
                      className={`py-1.5 rounded-xl text-xs font-medium border capitalize transition ${
                        formRecurrence === r.value
                          ? "bg-white text-neutral-950 border-white font-semibold"
                          : "bg-neutral-950 border-neutral-800 text-neutral-400 hover:text-neutral-200"
                      }`}
                    >
                      {r.label}
                    </button>
                  ))}
                </div>
              </div>

              {/* Priority */}
              <div>
                <label className="block text-xs font-medium text-neutral-300 mb-1.5">
                  Priority
                </label>
                <div className="grid grid-cols-3 gap-2">
                  {(["low", "medium", "high"] as TaskPriority[]).map((p) => (
                    <button
                      key={p}
                      type="button"
                      onClick={() => setFormPriority(p)}
                      className={`py-2 rounded-xl text-xs font-medium border capitalize transition ${
                        formPriority === p
                          ? p === "high"
                            ? "bg-rose-500/20 border-rose-500/50 text-rose-300"
                            : p === "medium"
                            ? "bg-amber-500/20 border-amber-500/50 text-amber-300"
                            : "bg-emerald-500/20 border-emerald-500/50 text-emerald-300"
                          : "bg-neutral-950 border-neutral-800 text-neutral-400 hover:text-neutral-200"
                      }`}
                    >
                      {p}
                    </button>
                  ))}
                </div>
              </div>

              {/* Actions */}
              <div className="flex items-center justify-end gap-2 pt-3 border-t border-neutral-800">
                <button
                  type="button"
                  onClick={() => setIsModalOpen(false)}
                  className="px-4 py-2 rounded-xl text-xs font-medium text-neutral-400 hover:text-white hover:bg-neutral-800 transition"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={formSubmitting}
                  className="bg-white hover:bg-neutral-200 text-neutral-950 px-5 py-2 rounded-xl text-xs font-medium transition disabled:opacity-50"
                >
                  {formSubmitting
                    ? "Saving..."
                    : editingTaskId
                    ? "Update Task"
                    : "Create Task"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}

export default function DashboardPage() {
  return (
    <Suspense
      fallback={
        <div className="flex-1 flex items-center justify-center text-neutral-500 text-sm">
          Loading...
        </div>
      }
    >
      <DashboardContent />
    </Suspense>
  );
}
