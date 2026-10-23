"use client";

import { useState, useMemo } from "react";
import Link from "next/link";
import Image from "next/image";
import CatAnimation from "@/components/CatAnimation";

export default function Home() {
  // Demo interactive state
  const [demoTasks, setDemoTasks] = useState([
    { id: 1, title: "Review quarterly sprint roadmap", completed: false, priority: "high" },
    { id: 2, title: "Deploy updated API endpoints", completed: false, priority: "medium" },
    { id: 3, title: "Prepare weekly status update", completed: false, priority: "low" },
    { id: 4, title: "Answer pending community threads", completed: true, priority: "low" },
  ]);

  const activeCount = useMemo(() => demoTasks.filter((t) => !t.completed).length, [demoTasks]);
  const demoSpeed = useMemo(() => {
    if (activeCount === 0) return 0;
    return Math.min(100, Math.round((activeCount / 3) * 100));
  }, [activeCount]);

  const toggleTask = (id: number) => {
    setDemoTasks((prev) =>
      prev.map((t) => (t.id === id ? { ...t, completed: !t.completed } : t))
    );
  };

  const setAllCompleted = (done: boolean) => {
    setDemoTasks((prev) => prev.map((t) => ({ ...t, completed: done })));
  };

  return (
    <div className="flex-1 flex flex-col min-h-screen bg-neutral-950 text-white selection:bg-neutral-800">
      {/* Navigation Bar */}
      <nav className="w-full border-b border-neutral-800/80 bg-neutral-950/80 backdrop-blur-md sticky top-0 z-40">
        <div className="max-w-6xl mx-auto px-4 sm:px-6 h-16 flex items-center justify-between">
          <Link href="/" className="flex items-center gap-3">
            <div className="w-9 h-9 relative rounded-xl bg-white p-1.5 shadow-sm flex items-center justify-center">
              <Image src="/logo.svg" alt="TodoCat" fill className="object-contain p-1" priority />
            </div>
            <span className="font-bold text-white text-base tracking-tight">TodoCat</span>
          </Link>

          <div className="hidden md:flex items-center gap-6 text-xs font-medium text-neutral-400">
            <a href="#features" className="hover:text-white transition">Features</a>
            <a href="#demo" className="hover:text-white transition">Interactive Demo</a>
            <a href="#workflow" className="hover:text-white transition">Workflow</a>
            <Link href="/about" className="hover:text-white transition">About Developer</Link>
          </div>

          <div className="flex items-center gap-2.5">
            <a
              href="https://buymeacoffee.com/nanda_kshr"
              target="_blank"
              rel="noopener noreferrer"
              aria-label="Buy Me a Coffee"
              title="Buy Me a Coffee"
              className="hidden sm:inline-flex items-center gap-1.5 py-1.5 px-3 rounded-xl bg-amber-400 hover:bg-amber-300 text-neutral-950 text-xs font-bold transition shadow-sm"
            >
              <span>☕</span>
              <span>Coffee</span>
            </a>
            <a
              href="https://github.com/nanda-kshr/ToDo-Cat"
              target="_blank"
              rel="noopener noreferrer"
              aria-label="GitHub Repository"
              className="p-2 rounded-xl text-neutral-400 hover:text-white hover:bg-neutral-900 border border-neutral-800 transition"
              title="GitHub: nanda-kshr/ToDo-Cat"
            >
              <svg className="w-4 h-4 fill-current" viewBox="0 0 24 24">
                <path fillRule="evenodd" clipRule="evenodd" d="M12 2C6.477 2 2 6.484 2 12.017c0 4.425 2.865 8.18 6.839 9.504.5.092.682-.217.682-.483 0-.237-.008-.868-.013-1.703-2.782.605-3.369-1.343-3.369-1.343-.454-1.158-1.11-1.466-1.11-1.466-.908-.62.069-.608.069-.608 1.003.07 1.53 1.032 1.53 1.032.892 1.53 2.341 1.088 2.91.832.092-.647.35-1.088.636-1.338-2.22-.253-4.555-1.113-4.555-4.951 0-1.093.39-1.988 1.029-2.688-.103-.253-.446-1.272.098-2.65 0 0 .84-.27 2.75 1.026A9.564 9.564 0 0112 6.844c.85.004 1.705.115 2.504.337 1.909-1.296 2.747-1.027 2.747-1.027.546 1.379.202 2.398.1 2.651.64.7 1.028 1.595 1.028 2.688 0 3.848-2.339 4.695-4.566 4.943.359.309.678.92.678 1.855 0 1.338-.012 2.419-.012 2.747 0 .268.18.58.688.482A10.019 10.019 0 0022 12.017C22 6.484 17.522 2 12 2z" />
              </svg>
            </a>
            <Link
              href="/auth?action=login"
              className="py-2 px-3.5 rounded-xl text-xs font-medium text-neutral-300 hover:text-white border border-neutral-800 bg-neutral-900/60 hover:bg-neutral-900 transition"
            >
              Sign In
            </Link>
            <Link
              href="/auth?action=signup"
              className="py-2 px-4 rounded-xl text-xs font-medium text-neutral-950 bg-white hover:bg-neutral-200 shadow-sm transition"
            >
              Get Started
            </Link>
          </div>
        </div>
      </nav>

      <main className="flex-1">
        {/* Hero Section */}
        <section className="pt-16 pb-20 px-4 sm:px-6 max-w-5xl mx-auto text-center flex flex-col items-center">
          {/* Pill Badge */}
          <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full border border-neutral-800 bg-neutral-900/80 text-xs font-medium text-neutral-300 mb-6">
            <span className="w-2 h-2 rounded-full bg-amber-400 animate-pulse" />
            <span>Interactive Visual Task Management</span>
          </div>

          <h1 className="text-4xl sm:text-5xl md:text-6xl font-extrabold tracking-tight text-white max-w-3xl leading-[1.12]">
            The to-do app that runs at the speed of your backlog.
          </h1>

          <p className="mt-5 text-neutral-400 text-sm sm:text-base max-w-2xl leading-relaxed">
            When tasks pile up, your cat kicks into maximum speed. Check off your tasks, and your cat curls up to sleep peacefully. Visual motivation built for real focus.
          </p>

          <div className="mt-8 flex flex-col sm:flex-row items-center gap-3 w-full max-w-sm justify-center">
            <Link
              href="/auth?action=signup"
              className="w-full sm:w-auto flex-1 flex items-center justify-center gap-2 py-3 px-6 rounded-xl font-medium text-xs bg-white text-neutral-950 hover:bg-neutral-200 shadow-lg shadow-white/5 transition"
            >
              <span>Start Tracking Free</span>
              <svg className="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M13 7l5 5m0 0l-5 5m5-5H6" />
              </svg>
            </Link>
            <Link
              href="/auth?action=login"
              className="w-full sm:w-auto flex-1 py-3 px-6 rounded-xl font-medium text-xs border border-neutral-800 bg-neutral-900/80 text-neutral-200 hover:bg-neutral-800 transition"
            >
              Go to Dashboard
            </Link>
          </div>
        </section>

        {/* Live Interactive Demo Widget */}
        <section id="demo" className="px-4 sm:px-6 pb-20 max-w-3xl mx-auto">
          <div className="bg-neutral-900/70 border border-neutral-800 rounded-3xl p-6 shadow-2xl backdrop-blur-sm">
            <div className="flex items-center justify-between pb-4 border-b border-neutral-800 flex-wrap gap-3">
              <div className="flex items-center gap-2">
                <div className="w-2.5 h-2.5 rounded-full bg-rose-500/80" />
                <div className="w-2.5 h-2.5 rounded-full bg-amber-500/80" />
                <div className="w-2.5 h-2.5 rounded-full bg-emerald-500/80" />
                <span className="text-xs text-neutral-400 font-medium ml-2">Live Demo: Interactive Cat Speed</span>
              </div>

              <div className="flex items-center gap-2">
                <button
                  onClick={() => setAllCompleted(true)}
                  className="px-2.5 py-1 rounded-lg text-[11px] font-medium border border-neutral-800 bg-neutral-950 text-neutral-400 hover:text-white transition"
                >
                  Complete All (Sleep)
                </button>
                <button
                  onClick={() => setAllCompleted(false)}
                  className="px-2.5 py-1 rounded-lg text-[11px] font-medium border border-neutral-800 bg-neutral-950 text-neutral-400 hover:text-white transition"
                >
                  Reset All (Run)
                </button>
              </div>
            </div>

            {/* Runner Banner */}
            <div className="my-5 p-4 rounded-2xl bg-neutral-950 border border-neutral-800/80 flex items-center justify-between gap-4">
              <div className="flex items-center gap-3.5">
                <CatAnimation speedPercent={demoSpeed} size={44} theme="card" />
                <div>
                  <div className="flex items-center gap-2">
                    <span className="text-xs font-semibold text-white">Cat Status</span>
                    <span
                      className={`text-[10px] font-medium px-2 py-0.5 rounded-full ${
                        demoSpeed === 0
                          ? "bg-indigo-500/10 text-indigo-400 border border-indigo-500/20"
                          : demoSpeed >= 100
                          ? "bg-rose-500/10 text-rose-400 border border-rose-500/20"
                          : "bg-amber-500/10 text-amber-400 border border-amber-500/20"
                      }`}
                    >
                      {demoSpeed}% Speed
                    </span>
                  </div>
                  <p className="text-xs text-neutral-400 mt-0.5">
                    {demoSpeed === 0
                      ? "All tasks cleared. Cat is sleeping peacefully."
                      : demoSpeed >= 100
                      ? `${activeCount} pending tasks. Maximum speed zoomies!`
                      : `${activeCount} pending tasks. Cat is running along.`}
                  </p>
                </div>
              </div>

              <div className="hidden sm:block text-right">
                <span className="text-xs text-neutral-500">
                  {demoTasks.length - activeCount} / {demoTasks.length} done
                </span>
              </div>
            </div>

            {/* Sample task list to click */}
            <div className="space-y-2">
              <p className="text-[11px] uppercase tracking-wider text-neutral-500 font-semibold mb-2">
                Click any task to toggle and watch the cat react:
              </p>
              {demoTasks.map((t) => (
                <div
                  key={t.id}
                  onClick={() => toggleTask(t.id)}
                  className={`flex items-center justify-between p-3 rounded-xl border cursor-pointer select-none transition ${
                    t.completed
                      ? "bg-neutral-950/40 border-neutral-900 opacity-60"
                      : "bg-neutral-950 border-neutral-800 hover:border-neutral-700"
                  }`}
                >
                  <div className="flex items-center gap-3">
                    <div
                      className={`w-4 h-4 rounded-md border flex items-center justify-center transition ${
                        t.completed
                          ? "bg-emerald-500 border-emerald-500 text-black"
                          : "border-neutral-700 bg-neutral-900"
                      }`}
                    >
                      {t.completed && (
                        <svg className="w-3 h-3" viewBox="0 0 20 20" fill="currentColor">
                          <path
                            fillRule="evenodd"
                            d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"
                            clipRule="evenodd"
                          />
                        </svg>
                      )}
                    </div>
                    <span
                      className={`text-xs font-medium ${
                        t.completed ? "line-through text-neutral-500" : "text-neutral-200"
                      }`}
                    >
                      {t.title}
                    </span>
                  </div>

                  <span
                    className={`text-[9px] uppercase font-semibold px-2 py-0.5 rounded-full border ${
                      t.priority === "high"
                        ? "bg-rose-500/10 text-rose-400 border-rose-500/20"
                        : t.priority === "medium"
                        ? "bg-amber-500/10 text-amber-400 border-amber-500/20"
                        : "bg-neutral-800 text-neutral-400 border-neutral-700"
                    }`}
                  >
                    {t.priority}
                  </span>
                </div>
              ))}
            </div>
          </div>
        </section>

        {/* Features Section */}
        <section id="features" className="py-20 border-t border-neutral-900 px-4 sm:px-6 max-w-5xl mx-auto">
          <div className="text-center max-w-2xl mx-auto mb-14">
            <h2 className="text-2xl sm:text-3xl font-bold tracking-tight text-white">
              Built for speed, clarity, and momentum.
            </h2>
            <p className="mt-3 text-neutral-400 text-xs sm:text-sm">
              Everything you need to organize your daily priorities without cognitive overhead.
            </p>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
            {/* Feature 1 */}
            <div className="p-5 rounded-2xl bg-neutral-900/60 border border-neutral-800/80 flex flex-col justify-between">
              <div>
                <div className="w-10 h-10 rounded-xl bg-neutral-800 border border-neutral-700/80 flex items-center justify-center text-neutral-200 mb-4">
                  <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 10V3L4 14h7v7l9-11h-7z" />
                  </svg>
                </div>
                <h3 className="text-sm font-semibold text-white">Dynamic Speed</h3>
                <p className="text-xs text-neutral-400 mt-2 leading-relaxed">
                  Your runner accelerates as pending tasks accumulate, and slows to a rest when completed.
                </p>
              </div>
            </div>

            {/* Feature 2 */}
            <div className="p-5 rounded-2xl bg-neutral-900/60 border border-neutral-800/80 flex flex-col justify-between">
              <div>
                <div className="w-10 h-10 rounded-xl bg-neutral-800 border border-neutral-700/80 flex items-center justify-center text-neutral-200 mb-4">
                  <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
                  </svg>
                </div>
                <h3 className="text-sm font-semibold text-white">Deadlines & Due Dates</h3>
                <p className="text-xs text-neutral-400 mt-2 leading-relaxed">
                  Clear separation between Today, Upcoming, and Overdue items with real-time badges.
                </p>
              </div>
            </div>

            {/* Feature 3 */}
            <div className="p-5 rounded-2xl bg-neutral-900/60 border border-neutral-800/80 flex flex-col justify-between">
              <div>
                <div className="w-10 h-10 rounded-xl bg-neutral-800 border border-neutral-700/80 flex items-center justify-center text-neutral-200 mb-4">
                  <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M7 7h.01M7 3h5c.512 0 1.024.195 1.414.586l7 7a2 2 0 010 2.828l-7 7a2 2 0 01-2.828 0l-7-7A1.994 1.994 0 013 12V7a4 4 0 014-4z" />
                  </svg>
                </div>
                <h3 className="text-sm font-semibold text-white">Priority & Tags</h3>
                <p className="text-xs text-neutral-400 mt-2 leading-relaxed">
                  Categorize work, personal, and shopping tasks with color-coded High, Medium, and Low priorities.
                </p>
              </div>
            </div>

            {/* Feature 4 */}
            <div className="p-5 rounded-2xl bg-neutral-900/60 border border-neutral-800/80 flex flex-col justify-between">
              <div>
                <div className="w-10 h-10 rounded-xl bg-neutral-800 border border-neutral-700/80 flex items-center justify-center text-neutral-200 mb-4">
                  <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 7v10c0 2 1.5 3 3.5 3h9c2 0 3.5-1 3.5-3V7c0-2-1.5-3-3.5-3h-9C5.5 4 4 5 4 7zm0 5h16" />
                  </svg>
                </div>
                <h3 className="text-sm font-semibold text-white">Cloud Database</h3>
                <p className="text-xs text-neutral-400 mt-2 leading-relaxed">
                  Persistent MongoDB storage with secure token authentication and Google OAuth integration.
                </p>
              </div>
            </div>
          </div>
        </section>

        {/* Workflow Section */}
        <section id="workflow" className="py-20 border-t border-neutral-900 px-4 sm:px-6 max-w-4xl mx-auto">
          <div className="text-center max-w-xl mx-auto mb-14">
            <h2 className="text-2xl sm:text-3xl font-bold tracking-tight text-white">
              How TodoCat Works
            </h2>
            <p className="mt-3 text-neutral-400 text-xs sm:text-sm">
              A straightforward feedback loop that keeps your focus sharp throughout the day.
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            <div className="p-6 rounded-2xl bg-neutral-900/40 border border-neutral-800 text-center flex flex-col items-center">
              <div className="w-8 h-8 rounded-full bg-neutral-800 text-white text-xs font-bold flex items-center justify-center mb-4 border border-neutral-700">
                1
              </div>
              <h3 className="text-sm font-semibold text-white mb-2">Create & Categorize</h3>
              <p className="text-xs text-neutral-400 leading-relaxed">
                Add your tasks with optional due dates, descriptions, and priority levels.
              </p>
            </div>

            <div className="p-6 rounded-2xl bg-neutral-900/40 border border-neutral-800 text-center flex flex-col items-center">
              <div className="w-8 h-8 rounded-full bg-neutral-800 text-white text-xs font-bold flex items-center justify-center mb-4 border border-neutral-700">
                2
              </div>
              <h3 className="text-sm font-semibold text-white mb-2">Visual Pace</h3>
              <p className="text-xs text-neutral-400 leading-relaxed">
                Watch your runner accelerate as your queue grows, signaling current load.
              </p>
            </div>

            <div className="p-6 rounded-2xl bg-neutral-900/40 border border-neutral-800 text-center flex flex-col items-center">
              <div className="w-8 h-8 rounded-full bg-neutral-800 text-white text-xs font-bold flex items-center justify-center mb-4 border border-neutral-700">
                3
              </div>
              <h3 className="text-sm font-semibold text-white mb-2">Rest & Reset</h3>
              <p className="text-xs text-neutral-400 leading-relaxed">
                Check off your backlog. Once everything is done, your cat curls up and sleeps.
              </p>
            </div>
          </div>
        </section>

        {/* CTA Banner */}
        <section className="py-20 border-t border-neutral-900 px-4 sm:px-6">
          <div className="max-w-4xl mx-auto rounded-3xl bg-neutral-900/90 border border-neutral-800 p-8 sm:p-12 text-center flex flex-col items-center shadow-2xl">
            <div className="w-14 h-14 relative rounded-2xl bg-white p-2 shadow-md mb-6">
              <Image src="/logo.svg" alt="TodoCat" fill className="object-contain p-1" priority />
            </div>

            <h2 className="text-2xl sm:text-3xl font-extrabold text-white tracking-tight max-w-lg">
              Ready to give your cat a well-earned nap?
            </h2>
            <p className="text-xs sm:text-sm text-neutral-400 max-w-md mt-3 mb-8">
              Join TodoCat and make your daily checklist satisfying, organized, and focused.
            </p>

            <Link
              href="/auth?action=signup"
              className="py-3 px-8 rounded-xl font-medium text-xs bg-white text-neutral-950 hover:bg-neutral-200 transition shadow-lg shadow-white/5"
            >
              Create Free Account
            </Link>
          </div>
        </section>
      </main>

      {/* Footer */}
      <footer className="border-t border-neutral-900 py-10 px-4 sm:px-6 text-xs text-neutral-500">
        <div className="max-w-6xl mx-auto flex flex-col md:flex-row items-center justify-between gap-6">
          <div className="flex items-center gap-3">
            <div className="w-8 h-8 relative rounded-xl bg-white p-1.5 shadow-sm">
              <Image src="/logo.svg" alt="TodoCat" fill className="object-contain p-0.5" />
            </div>
            <div className="text-left">
              <span className="font-semibold text-neutral-200 text-sm">TodoCat</span>
              <p className="text-[11px] text-neutral-500">Visual task management powered by RunCat frames</p>
            </div>
          </div>

          <div className="flex flex-wrap items-center justify-center gap-6 text-xs">
            {/* GitHub Repo */}
            <a
              href="https://github.com/nanda-kshr/ToDo-Cat"
              target="_blank"
              rel="noopener noreferrer"
              className="flex items-center gap-2 text-neutral-400 hover:text-white transition"
            >
              <svg className="w-4 h-4 fill-current shrink-0" viewBox="0 0 24 24">
                <path fillRule="evenodd" clipRule="evenodd" d="M12 2C6.477 2 2 6.484 2 12.017c0 4.425 2.865 8.18 6.839 9.504.5.092.682-.217.682-.483 0-.237-.008-.868-.013-1.703-2.782.605-3.369-1.343-3.369-1.343-.454-1.158-1.11-1.466-1.11-1.466-.908-.62.069-.608.069-.608 1.003.07 1.53 1.032 1.53 1.032.892 1.53 2.341 1.088 2.91.832.092-.647.35-1.088.636-1.338-2.22-.253-4.555-1.113-4.555-4.951 0-1.093.39-1.988 1.029-2.688-.103-.253-.446-1.272.098-2.65 0 0 .84-.27 2.75 1.026A9.564 9.564 0 0112 6.844c.85.004 1.705.115 2.504.337 1.909-1.296 2.747-1.027 2.747-1.027.546 1.379.202 2.398.1 2.651.64.7 1.028 1.595 1.028 2.688 0 3.848-2.339 4.695-4.566 4.943.359.309.678.92.678 1.855 0 1.338-.012 2.419-.012 2.747 0 .268.18.58.688.482A10.019 10.019 0 0022 12.017C22 6.484 17.522 2 12 2z" />
              </svg>
              <span>GitHub</span>
            </a>

            {/* Email Contact */}
            <a
              href="mailto:nandakishorep212@gmail.com"
              className="flex items-center gap-2 text-neutral-400 hover:text-white transition"
            >
              <svg className="w-4 h-4 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
              </svg>
              <span>nandakishorep212@gmail.com</span>
            </a>

            <Link href="/about" className="text-neutral-400 hover:text-white transition">
              About Developer
            </Link>
            <Link href="/privacy" className="text-neutral-400 hover:text-white transition">
              Privacy Policy
            </Link>
            <Link href="/terms" className="text-neutral-400 hover:text-white transition">
              Terms &amp; Conditions
            </Link>
            <Link href="/delete-account" className="text-neutral-400 hover:text-white transition">
              Delete Account
            </Link>
            <a
              href="https://buymeacoffee.com/nanda_kshr"
              target="_blank"
              rel="noopener noreferrer"
              className="text-amber-400 hover:text-amber-300 transition font-medium"
            >
              ☕ Buy Me a Coffee
            </a>
          </div>

          <div className="flex items-center gap-4 text-xs">
            <Link href="/auth?action=login" className="hover:text-neutral-300 transition">Sign In</Link>
            <Link href="/auth?action=signup" className="hover:text-neutral-300 transition">Register</Link>
          </div>
        </div>
      </footer>
    </div>
  );
}
