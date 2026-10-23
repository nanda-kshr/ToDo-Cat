import Link from "next/link";
import Image from "next/image";
import type { Metadata } from "next";
import { CoffeeIcon, HeartIcon } from "@/components/Icons";

export const metadata: Metadata = {
  title: "About Developer | TodoCat",
  description: "Learn about Nandakishore P, the creator of TodoCat visual task manager.",
};

export default function AboutPage() {
  return (
    <div className="min-h-screen bg-neutral-950 text-neutral-200 flex flex-col">
      {/* Header Navigation */}
      <header className="border-b border-neutral-900 bg-neutral-950/80 backdrop-blur-md sticky top-0 z-50">
        <div className="max-w-4xl mx-auto px-4 sm:px-6 h-16 flex items-center justify-between">
          <Link href="/" className="flex items-center gap-3">
            <div className="w-8 h-8 relative rounded-xl bg-white p-1.5 shadow-sm">
              <Image src="/logo.svg" alt="TodoCat" fill className="object-contain p-0.5" />
            </div>
            <span className="font-bold text-white text-base">TodoCat</span>
          </Link>
          <div className="flex items-center gap-4 text-xs font-medium">
            <a
              href="https://buymeacoffee.com/nanda_kshr"
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-amber-400 hover:bg-amber-300 text-neutral-950 font-bold transition shadow-sm"
            >
              <CoffeeIcon className="w-4 h-4" />
              <span>Buy Me a Coffee</span>
            </a>
            <Link href="/privacy" className="text-neutral-400 hover:text-white transition hidden sm:inline-block">
              Privacy
            </Link>
            <Link href="/terms" className="text-neutral-400 hover:text-white transition hidden sm:inline-block">
              Terms
            </Link>
            <Link
              href="/auth"
              className="px-3.5 py-1.5 rounded-lg bg-white text-neutral-950 font-medium hover:bg-neutral-200 transition"
            >
              Sign In
            </Link>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="flex-1 max-w-4xl w-full mx-auto px-4 sm:px-6 py-12">
        <div className="space-y-10">
          <div>
            <h1 className="text-3xl font-extrabold tracking-tight text-white sm:text-4xl">
              About the Developer
            </h1>
            <p className="mt-2 text-sm text-neutral-400">
              Meet Nandakishore P, the creator and maintainer of TodoCat.
            </p>
          </div>

          {/* Profile Card */}
          <div className="p-6 sm:p-8 rounded-2xl bg-neutral-900 border border-neutral-800 space-y-6">
            <div className="flex flex-col sm:flex-row items-start sm:items-center gap-5">
              <div className="w-20 h-20 rounded-2xl bg-gradient-to-br from-neutral-800 to-neutral-700 flex items-center justify-center text-3xl font-extrabold text-white border border-neutral-700 shadow-inner">
                NP
              </div>
              <div>
                <h2 className="text-xl sm:text-2xl font-bold text-white">Nandakishore P</h2>
                <p className="text-sm text-neutral-400 mt-0.5">Software Developer &amp; Creator of TodoCat</p>
                <div className="flex flex-wrap items-center gap-3 mt-3">
                  <a
                    href="https://github.com/nanda-kshr"
                    target="_blank"
                    rel="noopener noreferrer"
                    className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-neutral-800 hover:bg-neutral-700 border border-neutral-700 text-xs text-white transition font-medium"
                  >
                    <svg className="w-3.5 h-3.5 fill-current" viewBox="0 0 24 24">
                      <path fillRule="evenodd" clipRule="evenodd" d="M12 2C6.477 2 2 6.484 2 12.017c0 4.425 2.865 8.18 6.839 9.504.5.092.682-.217.682-.483 0-.237-.008-.868-.013-1.703-2.782.605-3.369-1.343-3.369-1.343-.454-1.158-1.11-1.466-1.11-1.466-.908-.62.069-.608.069-.608 1.003.07 1.53 1.032 1.53 1.032.892 1.53 2.341 1.088 2.91.832.092-.647.35-1.088.636-1.338-2.22-.253-4.555-1.113-4.555-4.951 0-1.093.39-1.988 1.029-2.688-.103-.253-.446-1.272.098-2.65 0 0 .84-.27 2.75 1.026A9.564 9.564 0 0112 6.844c.85.004 1.705.115 2.504.337 1.909-1.296 2.747-1.027 2.747-1.027.546 1.379.202 2.398.1 2.651.64.7 1.028 1.595 1.028 2.688 0 3.848-2.339 4.695-4.566 4.943.359.309.678.92.678 1.855 0 1.338-.012 2.419-.012 2.747 0 .268.18.58.688.482A10.019 10.019 0 0022 12.017C22 6.484 17.522 2 12 2z" />
                    </svg>
                    <span>github.com/nanda-kshr</span>
                  </a>
                  <a
                    href="mailto:nandakishorep212@gmail.com"
                    className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-neutral-800 hover:bg-neutral-700 border border-neutral-700 text-xs text-white transition font-medium"
                  >
                    <svg className="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
                    </svg>
                    <span>nandakishorep212@gmail.com</span>
                  </a>
                </div>
              </div>
            </div>

            <div className="border-t border-neutral-800 pt-5 text-sm text-neutral-300 leading-relaxed space-y-3">
              <p>
                Hi! I&apos;m Nandakishore, a developer focused on crafting responsive, intuitive, and delightful applications.
              </p>
              <p>
                I built <strong>TodoCat</strong> to transform mundane to-do lists into an engaging, visual experience. By connecting task completion velocity directly with running cat companion animation frames, TodoCat makes keeping up with daily goals fun across your desktop browser, home screen widgets, and floating overlays.
              </p>
            </div>
          </div>

          {/* Support / Buy Me a Coffee Card */}
          <div className="p-6 sm:p-8 rounded-2xl bg-gradient-to-br from-amber-950/40 via-neutral-900 to-neutral-900 border border-amber-500/30 space-y-4">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-xl bg-amber-400 text-neutral-950 flex items-center justify-center shadow-md">
                <HeartIcon className="w-5 h-5 text-neutral-950" />
              </div>
              <div>
                <h3 className="text-lg font-bold text-white">Support the Project</h3>
                <p className="text-xs text-neutral-400">Help keep TodoCat running and free for everyone</p>
              </div>
            </div>
            <p className="text-sm text-neutral-300 leading-relaxed">
              If TodoCat helps you stay organized, boosts your focus, or just makes you smile when the cat runs faster, consider buying me a coffee! Your support fuels ongoing improvements, server hosting, and new features.
            </p>
            <div className="pt-2">
              <a
                href="https://buymeacoffee.com/nanda_kshr"
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center gap-2 px-5 py-3 rounded-xl bg-amber-400 hover:bg-amber-300 text-neutral-950 font-bold text-sm transition shadow-lg shadow-amber-400/10"
              >
                <CoffeeIcon className="w-4 h-4" />
                <span>Buy Me a Coffee at buymeacoffee.com/nanda_kshr</span>
                <span>&rarr;</span>
              </a>
            </div>
          </div>

          {/* Quick Links */}
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
            <Link
              href="/privacy"
              className="p-4 rounded-xl bg-neutral-900 hover:bg-neutral-800 border border-neutral-800 text-xs transition space-y-1"
            >
              <p className="font-semibold text-white">Privacy Policy</p>
              <p className="text-neutral-400">How we protect your account &amp; task data</p>
            </Link>
            <Link
              href="/terms"
              className="p-4 rounded-xl bg-neutral-900 hover:bg-neutral-800 border border-neutral-800 text-xs transition space-y-1"
            >
              <p className="font-semibold text-white">Terms of Service</p>
              <p className="text-neutral-400">Rules &amp; conditions of service</p>
            </Link>
            <Link
              href="/delete-account"
              className="p-4 rounded-xl bg-neutral-900 hover:bg-neutral-800 border border-neutral-800 text-xs transition space-y-1"
            >
              <p className="font-semibold text-white">Delete Account</p>
              <p className="text-neutral-400">Request full account &amp; data deletion</p>
            </Link>
          </div>
        </div>
      </main>

      {/* Footer */}
      <footer className="border-t border-neutral-900 py-8 px-4 sm:px-6 text-xs text-neutral-500">
        <div className="max-w-4xl mx-auto flex flex-col sm:flex-row items-center justify-between gap-4">
          <p>&copy; 2026 TodoCat by Nandakishore P. All rights reserved.</p>
          <div className="flex items-center gap-4">
            <Link href="/" className="hover:text-neutral-300 transition">Home</Link>
            <Link href="/privacy" className="hover:text-neutral-300 transition">Privacy Policy</Link>
            <Link href="/terms" className="hover:text-neutral-300 transition">Terms</Link>
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
