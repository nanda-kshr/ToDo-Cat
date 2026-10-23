"use client";

import Link from "next/link";
import Image from "next/image";
import { useState } from "react";

export default function DeleteAccountPage() {
  const [email, setEmail] = useState("");
  const [reason, setReason] = useState("");
  const [status, setStatus] = useState<"idle" | "submitting" | "success" | "error">("idle");
  const [errorMessage, setErrorMessage] = useState("");

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email) return;

    setStatus("submitting");
    setErrorMessage("");

    try {
      // Create mailto fallback or simulated receipt
      window.location.href = `mailto:nandakishorep212@gmail.com?subject=TodoCat%20Account%20Deletion%20Request&body=Please%20delete%20my%20TodoCat%20account%20associated%20with%20email:%20${encodeURIComponent(
        email
      )}.%20Reason:%20${encodeURIComponent(reason || "None specified")}`;
      setStatus("success");
    } catch {
      setStatus("error");
      setErrorMessage("Could not launch email client. Please send an email directly to nandakishorep212@gmail.com.");
    }
  };

  return (
    <div className="min-h-screen bg-neutral-950 text-neutral-200 flex flex-col">
      {/* Header */}
      <header className="border-b border-neutral-900 bg-neutral-950/80 backdrop-blur-md sticky top-0 z-50">
        <div className="max-w-4xl mx-auto px-4 sm:px-6 h-16 flex items-center justify-between">
          <Link href="/" className="flex items-center gap-3">
            <div className="w-8 h-8 relative rounded-xl bg-white p-1.5 shadow-sm">
              <Image src="/logo.svg" alt="TodoCat" fill className="object-contain p-0.5" />
            </div>
            <span className="font-bold text-white text-base">TodoCat</span>
          </Link>
          <div className="flex items-center gap-4 text-xs font-medium">
            <Link href="/privacy" className="text-neutral-400 hover:text-white transition">
              Privacy Policy
            </Link>
            <Link href="/terms" className="text-neutral-400 hover:text-white transition">
              Terms &amp; Conditions
            </Link>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="flex-1 max-w-4xl w-full mx-auto px-4 sm:px-6 py-12">
        <div className="space-y-8">
          <div>
            <h1 className="text-3xl font-extrabold tracking-tight text-white sm:text-4xl">
              Account &amp; Data Deletion
            </h1>
            <p className="mt-2 text-sm text-neutral-400">
              Information on how to request the deletion of your TodoCat account and associated personal data.
            </p>
          </div>

          <div className="prose prose-invert max-w-none text-neutral-300 space-y-6 text-sm leading-relaxed">
            {/* Overview */}
            <section className="space-y-3">
              <h2 className="text-lg font-semibold text-white">1. Overview</h2>
              <p>
                In compliance with Google Play Developer Policies and global data privacy standards, TodoCat allows users to permanently delete their account and all associated personal data at any time.
              </p>
            </section>

            {/* What is deleted */}
            <section className="space-y-3">
              <h2 className="text-lg font-semibold text-white">2. What Data is Deleted</h2>
              <p>When your account is deleted, the following data is permanently purged from our databases:</p>
              <ul className="list-disc pl-5 space-y-1.5 text-neutral-400">
                <li>
                  <strong className="text-neutral-200">User Profile:</strong> Your email address, display name, password hash, and Google account identifier.
                </li>
                <li>
                  <strong className="text-neutral-200">Tasks &amp; Notes:</strong> All tasks, descriptions, priorities, due dates, and completion history.
                </li>
                <li>
                  <strong className="text-neutral-200">Analytics &amp; Statistics:</strong> All completion counts, historical records, and activity logs.
                </li>
                <li>
                  <strong className="text-neutral-200">Authentication Tokens:</strong> All active sessions and refresh tokens are immediately invalidated.
                </li>
              </ul>
              <p className="text-neutral-400 mt-2">
                <strong className="text-white">Data Retention:</strong> We do not retain any copies or backups of your personal data after account deletion. Deletion is irrevocable.
              </p>
            </section>

            {/* How to delete */}
            <section className="space-y-3">
              <h2 className="text-lg font-semibold text-white">3. How to Request Deletion</h2>
              <p>You can request account deletion using either of the following methods:</p>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4 not-prose mt-4">
                {/* Method 1: Email Request */}
                <div className="p-5 rounded-2xl bg-neutral-900 border border-neutral-800 space-y-3">
                  <div className="flex items-center gap-2.5 text-white font-semibold">
                    <svg className="w-5 h-5 text-neutral-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
                    </svg>
                    <span>Direct Email Request</span>
                  </div>
                  <p className="text-xs text-neutral-400 leading-relaxed">
                    Send an email from your registered account address to developer Nandakishore P:
                  </p>
                  <a
                    href="mailto:nandakishorep212@gmail.com?subject=TodoCat%20Account%20Deletion%20Request"
                    className="inline-flex items-center gap-1.5 text-xs text-white font-medium bg-neutral-800 hover:bg-neutral-700 px-3 py-2 rounded-lg transition"
                  >
                    nandakishorep212@gmail.com &rarr;
                  </a>
                  <p className="text-[11px] text-neutral-500">
                    Requests submitted via email are verified and processed within 48 hours.
                  </p>
                </div>

                {/* Method 2: Web / App Deletion */}
                <div className="p-5 rounded-2xl bg-neutral-900 border border-neutral-800 space-y-3">
                  <div className="flex items-center gap-2.5 text-white font-semibold">
                    <svg className="w-5 h-5 text-neutral-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                    </svg>
                    <span>Signed-In Users</span>
                  </div>
                  <p className="text-xs text-neutral-400 leading-relaxed">
                    If you are currently signed in, you can access your dashboard to delete your account immediately.
                  </p>
                  <Link
                    href="/dashboard"
                    className="inline-flex items-center gap-1.5 text-xs text-white font-medium bg-neutral-800 hover:bg-neutral-700 px-3 py-2 rounded-lg transition"
                  >
                    Go to Dashboard &rarr;
                  </Link>
                </div>
              </div>
            </section>

            {/* Quick Request Form */}
            <section className="space-y-4 pt-4">
              <h2 className="text-lg font-semibold text-white">4. Submit Deletion Request Online</h2>
              <p className="text-neutral-400">
                You can also use this form to generate an official account deletion request:
              </p>

              <form onSubmit={handleSubmit} className="not-prose max-w-lg space-y-4 p-5 rounded-2xl bg-neutral-900/60 border border-neutral-800">
                <div>
                  <label htmlFor="email" className="block text-xs font-medium text-neutral-300 mb-1.5">
                    Registered Email Address *
                  </label>
                  <input
                    id="email"
                    type="email"
                    required
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    placeholder="you@example.com"
                    className="w-full px-3.5 py-2.5 rounded-xl bg-neutral-800 border border-neutral-700 text-white placeholder-neutral-500 text-sm focus:outline-none focus:border-neutral-500"
                  />
                </div>

                <div>
                  <label htmlFor="reason" className="block text-xs font-medium text-neutral-300 mb-1.5">
                    Reason for Deletion (Optional)
                  </label>
                  <textarea
                    id="reason"
                    rows={3}
                    value={reason}
                    onChange={(e) => setReason(e.target.value)}
                    placeholder="Let us know why you are leaving (optional)..."
                    className="w-full px-3.5 py-2.5 rounded-xl bg-neutral-800 border border-neutral-700 text-white placeholder-neutral-500 text-sm focus:outline-none focus:border-neutral-500"
                  />
                </div>

                {status === "success" && (
                  <div className="p-3 rounded-lg bg-emerald-950/60 border border-emerald-800 text-emerald-300 text-xs">
                    Your email client has been opened with your deletion request. Send the email to complete the submission.
                  </div>
                )}

                {status === "error" && (
                  <div className="p-3 rounded-lg bg-red-950/60 border border-red-800 text-red-300 text-xs">
                    {errorMessage}
                  </div>
                )}

                <button
                  type="submit"
                  disabled={status === "submitting"}
                  className="w-full py-2.5 px-4 rounded-xl bg-red-600 hover:bg-red-500 text-white font-medium text-sm transition disabled:opacity-50"
                >
                  {status === "submitting" ? "Submitting..." : "Send Account Deletion Request"}
                </button>
              </form>
            </section>
          </div>
        </div>
      </main>

      {/* Footer */}
      <footer className="border-t border-neutral-900 py-8 px-4 sm:px-6 text-xs text-neutral-500">
        <div className="max-w-4xl mx-auto flex flex-col sm:flex-row items-center justify-between gap-4">
          <p>&copy; 2026 TodoCat. All rights reserved.</p>
          <div className="flex flex-wrap items-center gap-4">
            <Link href="/" className="hover:text-neutral-300 transition">Home</Link>
            <Link href="/about" className="hover:text-neutral-300 transition">About Developer</Link>
            <Link href="/privacy" className="hover:text-neutral-300 transition">Privacy Policy</Link>
            <Link href="/terms" className="hover:text-neutral-300 transition">Terms &amp; Conditions</Link>
            <a
              href="https://buymeacoffee.com/nanda_kshr"
              target="_blank"
              rel="noopener noreferrer"
              className="text-amber-400 hover:text-amber-300 transition"
            >
              Buy Me a Coffee
            </a>
          </div>
        </div>
      </footer>
    </div>
  );
}
