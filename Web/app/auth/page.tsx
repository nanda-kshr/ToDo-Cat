"use client";

import { Suspense, useState } from "react";
import { useSearchParams, useRouter } from "next/navigation";
import Link from "next/link";
import Image from "next/image";

function AuthForm() {
  const searchParams = useSearchParams();
  const router = useRouter();

  const urlAction = searchParams.get("action");
  const [overrideAction, setOverrideAction] = useState<"login" | "signup" | null>(null);
  const action = overrideAction ?? (urlAction === "signup" ? "signup" : "login");

  const urlError = searchParams.get("error");
  const [customError, setCustomError] = useState<string | null>(null);
  const error = customError ?? (urlError ? decodeURIComponent(urlError).replace(/_/g, " ") : null);

  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setCustomError(null);
    setLoading(true);

    const endpoint = action === "signup" ? "/api/auth/register" : "/api/auth/login";
    const payload = action === "signup" ? { email, password, name } : { email, password };

    try {
      const res = await fetch(endpoint, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
      });

      const data = await res.json();

      if (!res.ok) {
        throw new Error(data.message || "Authentication failed");
      }

      if (data.accessToken) {
        localStorage.setItem("accessToken", data.accessToken);
      }

      router.push("/dashboard");
    } catch (err: unknown) {
      if (err instanceof Error) {
        setCustomError(err.message);
      } else {
        setCustomError("An unexpected error occurred");
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="max-w-md w-full bg-neutral-900/60 border border-neutral-800/80 rounded-2xl p-8 backdrop-blur-sm shadow-xl">
      <div className="flex flex-col items-center mb-6">
        <Link href="/" className="mb-4">
          <div className="w-16 h-16 relative rounded-2xl bg-white p-2.5 shadow-md">
            <Image src="/logo.svg" alt="TodoCat" fill className="object-contain p-1.5" priority />
          </div>
        </Link>
        <h1 className="text-2xl font-bold tracking-tight text-white">
          {action === "signup" ? "Create your account" : "Welcome back"}
        </h1>
        <p className="text-sm text-neutral-400 mt-1">
          {action === "signup" ? "Start tracking with TodoCat" : "Sign in to manage your tasks"}
        </p>
      </div>

      <a
        href="/api/auth/google"
        className="w-full flex items-center justify-center gap-3 py-2.5 px-4 rounded-xl border border-neutral-700/80 bg-neutral-800 hover:bg-neutral-700/70 text-neutral-200 text-sm font-medium transition"
      >
        <svg className="w-4 h-4" viewBox="0 0 24 24">
          <path
            fill="#4285F4"
            d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"
          />
          <path
            fill="#34A853"
            d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
          />
          <path
            fill="#FBBC05"
            d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.06H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.94l2.85-2.22.81-.63z"
          />
          <path
            fill="#EA4335"
            d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.06l3.66 2.84c.87-2.6 3.3-4.52 6.16-4.52z"
          />
        </svg>
        Continue with Google
      </a>

      <div className="flex items-center my-6">
        <div className="flex-1 border-t border-neutral-800" />
        <span className="px-3 text-xs uppercase tracking-wider text-neutral-500 font-medium">or</span>
        <div className="flex-1 border-t border-neutral-800" />
      </div>

      {error && (
        <div className="mb-4 p-3 rounded-xl bg-red-950/60 border border-red-800/60 text-red-300 text-xs text-center">
          {error}
        </div>
      )}

      <form onSubmit={handleSubmit} className="space-y-4">
        {action === "signup" && (
          <div>
            <label className="block text-xs font-medium text-neutral-300 mb-1.5" htmlFor="name">
              Name
            </label>
            <input
              id="name"
              type="text"
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="Your name"
              className="w-full px-3.5 py-2.5 rounded-xl bg-neutral-950 border border-neutral-800 text-neutral-100 text-sm placeholder-neutral-500 focus:outline-none focus:border-neutral-600 transition"
            />
          </div>
        )}

        <div>
          <label className="block text-xs font-medium text-neutral-300 mb-1.5" htmlFor="email">
            Email address
          </label>
          <input
            id="email"
            type="email"
            required
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            placeholder="you@example.com"
            className="w-full px-3.5 py-2.5 rounded-xl bg-neutral-950 border border-neutral-800 text-neutral-100 text-sm placeholder-neutral-500 focus:outline-none focus:border-neutral-600 transition"
          />
        </div>

        <div>
          <label className="block text-xs font-medium text-neutral-300 mb-1.5" htmlFor="password">
            Password
          </label>
          <input
            id="password"
            type="password"
            required
            minLength={6}
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            placeholder="••••••••"
            className="w-full px-3.5 py-2.5 rounded-xl bg-neutral-950 border border-neutral-800 text-neutral-100 text-sm placeholder-neutral-500 focus:outline-none focus:border-neutral-600 transition"
          />
        </div>

        <button
          type="submit"
          disabled={loading}
          className="w-full py-2.5 px-4 rounded-xl font-medium text-sm bg-white text-neutral-950 hover:bg-neutral-200 transition disabled:opacity-50 shadow-sm mt-2"
        >
          {loading ? "Please wait..." : action === "signup" ? "Create Account" : "Sign In"}
        </button>
      </form>

      <div className="mt-6 text-center text-xs text-neutral-400">
        {action === "signup" ? (
          <>
            Already have an account?{" "}
            <button
              type="button"
              onClick={() => {
                setOverrideAction("login");
                setCustomError(null);
              }}
              className="text-white hover:underline font-medium"
            >
              Sign In
            </button>
          </>
        ) : (
          <>
            Don&apos;t have an account?{" "}
            <button
              type="button"
              onClick={() => {
                setOverrideAction("signup");
                setCustomError(null);
              }}
              className="text-white hover:underline font-medium"
            >
              Sign Up
            </button>
          </>
        )}
      </div>

      <p className="mt-6 pt-4 border-t border-neutral-800/80 text-center text-[11px] text-neutral-500 leading-relaxed">
        By signing in or signing up, you agree to our{" "}
        <Link href="/terms" className="text-neutral-400 hover:text-white underline underline-offset-2">
          Terms &amp; Conditions
        </Link>{" "}
        and{" "}
        <Link href="/privacy" className="text-neutral-400 hover:text-white underline underline-offset-2">
          Privacy Policy
        </Link>
        .
      </p>
    </div>
  );
}

export default function AuthPage() {
  return (
    <main className="flex-1 flex flex-col items-center justify-center p-6">
      <Suspense fallback={<div className="text-neutral-500 text-sm">Loading...</div>}>
        <AuthForm />
      </Suspense>
    </main>
  );
}
