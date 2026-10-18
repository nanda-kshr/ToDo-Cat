export interface CachedTask {
  _id: string;
  userId?: string;
  title: string;
  description?: string;
  completed: boolean;
  dueDate?: string | Date | null;
  priority?: "low" | "medium" | "high";
  category?: string;
  createdAt?: string | Date;
  updatedAt?: string | Date;
  [key: string]: unknown;
}

interface CacheEntry {
  data: CachedTask[];
  cachedAt: number;
}

interface TaskCacheStore {
  tasksByUser: Map<string, CacheEntry>;
}

declare global {
  var taskCacheStore: TaskCacheStore | undefined;
}

const cacheStore: TaskCacheStore = global.taskCacheStore || {
  tasksByUser: new Map(),
};

if (!global.taskCacheStore) {
  global.taskCacheStore = cacheStore;
}

const DEFAULT_TTL_MS = 5 * 60 * 1000; // 5 minutes

export function sortTasks<
  T extends {
    completed?: boolean;
    dueDate?: string | Date | null;
    createdAt?: string | Date;
  }
>(tasks: T[]): T[] {
  return [...tasks].sort((a, b) => {
    // 1. completed: 1 (false before true)
    const compA = Boolean(a.completed);
    const compB = Boolean(b.completed);
    if (compA !== compB) {
      return compA ? 1 : -1;
    }

    // 2. dueDate: 1 (nulls first, then chronological)
    const dueA = a.dueDate ? new Date(a.dueDate).getTime() : null;
    const dueB = b.dueDate ? new Date(b.dueDate).getTime() : null;
    if (dueA === null && dueB !== null) return -1;
    if (dueA !== null && dueB === null) return 1;
    if (dueA !== null && dueB !== null && dueA !== dueB) {
      return dueA - dueB;
    }

    // 3. createdAt: -1 (newer first)
    const createdA = a.createdAt ? new Date(a.createdAt).getTime() : 0;
    const createdB = b.createdAt ? new Date(b.createdAt).getTime() : 0;
    return createdB - createdA;
  });
}

export function getCachedTasks(
  userId: string,
  ttlMs: number = DEFAULT_TTL_MS
): CachedTask[] | null {
  const entry = cacheStore.tasksByUser.get(userId);
  if (!entry) return null;

  if (Date.now() - entry.cachedAt > ttlMs) {
    cacheStore.tasksByUser.delete(userId);
    return null;
  }

  return entry.data;
}

export function setCachedTasks(userId: string, tasks: unknown[]): void {
  const plainTasks = JSON.parse(JSON.stringify(tasks)) as CachedTask[];
  cacheStore.tasksByUser.set(userId, {
    data: sortTasks(plainTasks),
    cachedAt: Date.now(),
  });
}

export function addCachedTask(userId: string, task: unknown): void {
  const plainTask = JSON.parse(JSON.stringify(task)) as CachedTask;
  const entry = cacheStore.tasksByUser.get(userId);
  if (!entry) return;

  const existing = entry.data.filter(
    (t) => String(t._id) !== String(plainTask._id)
  );
  entry.data = sortTasks([plainTask, ...existing]);
  entry.cachedAt = Date.now();
}

export function updateCachedTask(userId: string, task: unknown): void {
  const plainTask = JSON.parse(JSON.stringify(task)) as CachedTask;
  const entry = cacheStore.tasksByUser.get(userId);
  if (!entry) return;

  const taskId = String(plainTask._id);
  const index = entry.data.findIndex((t) => String(t._id) === taskId);

  if (index !== -1) {
    entry.data[index] = plainTask;
  } else {
    entry.data.push(plainTask);
  }

  entry.data = sortTasks(entry.data);
  entry.cachedAt = Date.now();
}

export function removeCachedTask(userId: string, taskId: string): void {
  const entry = cacheStore.tasksByUser.get(userId);
  if (!entry) return;

  entry.data = entry.data.filter((t) => String(t._id) !== String(taskId));
  entry.cachedAt = Date.now();
}

export function invalidateTaskCache(userId: string): void {
  cacheStore.tasksByUser.delete(userId);
}

export function clearAllTaskCache(): void {
  cacheStore.tasksByUser.clear();
}
