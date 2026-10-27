"use client";

import { Suspense, useState, useEffect } from "react";
import { useSearchParams, useRouter } from "next/navigation";
import Link from "next/link";
import Image from "next/image";

function ResetPasswordForm() {
  const searchParams = useSearchParams();
  const router = useRouter();

  const tokenFromUrl = searchParams.get("token") || "";
  const [token, setToken] = useState(tokenFromUrl);
  const [mode, setMode] = useState<"link" | "request" | "otp">(
    tokenFromUrl ? "link" : "request"
  );

  useEffect(() => {
    if (tokenFromUrl) {
      setToken(tokenFromUrl);
      setMode("link");
    }
  }, [tokenFromUrl]);

  const [email, setEmail] = useState("");
  const [otp, setOtp] = useState("");
  const [newPassword, setNewPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");

  const [loading, setLoading] = useState(false);
  const [statusMessage, setStatusMessage] = useState<string | null>(null);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [isSuccess, setIsSuccess] = useState(false);

  // Request Reset Email / OTP
  const handleRequestReset = async (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMessage(null);
    setStatusMessage(null);
    setLoading(true);

    try {
      const res = await fetch("/api/auth/forgot-password", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email }),
      });
      const data = await res.json();

      if (!res.ok) {
        throw new Error(data.message || "Failed to send reset email");
      }

      setStatusMessage("Check your inbox! We've sent you a 6-digit OTP code and a reset link.");
      setMode("otp"); // switch directly to OTP input so user can enter the code
    } catch (err: unknown) {
      setErrorMessage(err instanceof Error ? err.message : "Something went wrong.");
    } finally {
      setLoading(false);
    }
  };

  // Submit New Password (via Link Token OR via OTP)
  const handleResetPassword = async (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMessage(null);
    setStatusMessage(null);

    if (newPassword.length < 6) {
      setErrorMessage("Password must be at least 6 characters.");
      return;
    }

    if (newPassword !== confirmPassword) {
      setErrorMessage("Passwords do not match.");
      return;
    }

    setLoading(true);

    try {
      const payload: Record<string, string> = { newPassword };
      if (mode === "link" && token) {
        payload.token = token;
      } else {
        payload.email = email;
        payload.otp = otp.trim();
      }

      const res = await fetch("/api/auth/reset-password", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
      });
      const data = await res.json();

      if (!res.ok) {
        throw new Error(data.message || "Failed to reset password.");
      }

      setIsSuccess(true);
      setStatusMessage(data.message || "Password successfully reset!");
      setTimeout(() => {
        router.push("/auth?action=login");
      }, 2500);
    } catch (err: unknown) {
      setErrorMessage(err instanceof Error ? err.message : "Failed to reset password.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="w-full max-w-md bg-[#18181b] border border-zinc-800 rounded-3xl p-8 shadow-2xl backdrop-blur-xl">
      {/* Brand header */}
      <div className="flex flex-col items-center mb-8">
        <Link href="/" className="flex items-center gap-2 mb-3">
          <Image
            src="/icon.png"
            alt="TodoCat Logo"
            width={44}
            height={44}
            className="rounded-xl"
            onError={(e) => {
              // fallback if icon.png not present
              e.currentTarget.style.display = "none";
            }}
          />
          <span className="text-2xl font-bold tracking-tight text-white font-mono">
            TodoCat
          </span>
        </Link>
        <h1 className="text-xl font-bold text-white">
          {isSuccess
            ? "Password Reset Complete!"
            : mode === "request"
            ? "Forgot your password?"
            : mode === "otp"
            ? "Enter OTP & New Password"
            : "Set New Password"}
        </h1>
        <p className="text-xs text-zinc-400 mt-1 text-center">
          {isSuccess
            ? "Redirecting you to login..."
            : mode === "request"
            ? "Enter your email to receive an OTP code and reset link."
            : mode === "otp"
            ? "Enter the 6-digit code sent to your email and your new password."
            : "Enter and confirm your new secure password."}
        </p>
      </div>

      {/* Mode navigation tabs (if not already using a token from link) */}
      {!tokenFromUrl && !isSuccess && (
        <div className="grid grid-cols-2 p-1 bg-zinc-900 border border-zinc-800 rounded-2xl mb-6">
          <button
            type="button"
            onClick={() => {
              setMode("request");
              setErrorMessage(null);
            }}
            className={`py-2 text-xs font-semibold rounded-xl transition-all ${
              mode === "request"
                ? "bg-zinc-800 text-white shadow-sm"
                : "text-zinc-400 hover:text-zinc-200"
            }`}
          >
            Request Code
          </button>
          <button
            type="button"
            onClick={() => {
              setMode("otp");
              setErrorMessage(null);
            }}
            className={`py-2 text-xs font-semibold rounded-xl transition-all ${
              mode === "otp"
                ? "bg-zinc-800 text-white shadow-sm"
                : "text-zinc-400 hover:text-zinc-200"
            }`}
          >
            Enter OTP Code
          </button>
        </div>
      )}

      {/* Alert Messages */}
      {errorMessage && (
        <div className="mb-5 p-3 rounded-xl bg-red-950/50 border border-red-800/80 text-red-200 text-xs flex items-center gap-2">
          <span>⚠️</span>
          <span>{errorMessage}</span>
        </div>
      )}

      {statusMessage && (
        <div className="mb-5 p-3 rounded-xl bg-emerald-950/50 border border-emerald-800/80 text-emerald-200 text-xs flex items-center gap-2">
          <span>✅</span>
          <span>{statusMessage}</span>
        </div>
      )}

      {isSuccess ? (
        <div className="text-center py-4">
          <div className="w-12 h-12 mx-auto mb-3 rounded-full bg-emerald-500/10 border border-emerald-500/20 flex items-center justify-center text-emerald-400">
            <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M5 13l4 4L19 7" />
            </svg>
          </div>
          <Link
            href="/auth?action=login"
            className="inline-block w-full py-3 px-4 bg-white text-black font-bold text-sm rounded-xl hover:bg-zinc-200 transition-colors"
          >
            Go to Login Now
          </Link>
        </div>
      ) : mode === "request" ? (
        /* Form 1: Request Code */
        <form onSubmit={handleRequestReset} className="space-y-4">
          <div>
            <label className="block text-xs font-medium text-zinc-300 mb-1.5">
              Email Address
            </label>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="you@example.com"
              required
              className="w-full px-4 py-2.5 bg-zinc-900 border border-zinc-800 rounded-xl text-white placeholder-zinc-500 text-sm focus:outline-none focus:border-zinc-500 transition-colors"
            />
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full mt-2 py-3 px-4 bg-white text-black font-bold text-sm rounded-xl hover:bg-zinc-200 disabled:opacity-50 transition-colors"
          >
            {loading ? "Sending Code..." : "Send Reset Link & OTP"}
          </button>
        </form>
      ) : (
        /* Form 2: Reset with OTP or Link */
        <form onSubmit={handleResetPassword} className="space-y-4">
          {mode === "otp" && (
            <>
              <div>
                <label className="block text-xs font-medium text-zinc-300 mb-1.5">
                  Email Address
                </label>
                <input
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="you@example.com"
                  required
                  className="w-full px-4 py-2.5 bg-zinc-900 border border-zinc-800 rounded-xl text-white placeholder-zinc-500 text-sm focus:outline-none focus:border-zinc-500 transition-colors"
                />
              </div>

              <div>
                <label className="block text-xs font-medium text-zinc-300 mb-1.5">
                  6-Digit OTP Code
                </label>
                <input
                  type="text"
                  maxLength={6}
                  value={otp}
                  onChange={(e) => setOtp(e.target.value.replace(/\D/g, ""))}
                  placeholder="123456"
                  required
                  className="w-full px-4 py-2.5 bg-zinc-900 border border-zinc-800 rounded-xl text-white placeholder-zinc-500 text-center tracking-[6px] font-mono font-bold text-lg focus:outline-none focus:border-zinc-500 transition-colors"
                />
              </div>
            </>
          )}

          <div>
            <label className="block text-xs font-medium text-zinc-300 mb-1.5">
              New Password
            </label>
            <input
              type="password"
              value={newPassword}
              onChange={(e) => setNewPassword(e.target.value)}
              placeholder="••••••••"
              required
              minLength={6}
              className="w-full px-4 py-2.5 bg-zinc-900 border border-zinc-800 rounded-xl text-white placeholder-zinc-500 text-sm focus:outline-none focus:border-zinc-500 transition-colors"
            />
          </div>

          <div>
            <label className="block text-xs font-medium text-zinc-300 mb-1.5">
              Confirm New Password
            </label>
            <input
              type="password"
              value={confirmPassword}
              onChange={(e) => setConfirmPassword(e.target.value)}
              placeholder="••••••••"
              required
              minLength={6}
              className="w-full px-4 py-2.5 bg-zinc-900 border border-zinc-800 rounded-xl text-white placeholder-zinc-500 text-sm focus:outline-none focus:border-zinc-500 transition-colors"
            />
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full mt-2 py-3 px-4 bg-white text-black font-bold text-sm rounded-xl hover:bg-zinc-200 disabled:opacity-50 transition-colors"
          >
            {loading ? "Updating Password..." : "Update Password"}
          </button>
        </form>
      )}

      {/* Footer Back Link */}
      <div className="mt-8 text-center text-xs text-zinc-400">
        Remembered your password?{" "}
        <Link
          href="/auth?action=login"
          className="text-white font-medium hover:underline"
        >
          Back to Login
        </Link>
      </div>
    </div>
  );
}

export default function ResetPasswordPage() {
  return (
    <div className="min-h-screen bg-black text-white flex flex-col justify-center items-center p-4">
      <Suspense fallback={<div className="text-zinc-500 text-sm">Loading reset portal...</div>}>
        <ResetPasswordForm />
      </Suspense>
    </div>
  );
}
