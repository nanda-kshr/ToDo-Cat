import Link from "next/link";
import Image from "next/image";
import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Terms and Conditions | TodoCat",
  description: "Terms and Conditions for using the TodoCat web and mobile task management application.",
};

export default function TermsPage() {
  return (
    <div className="min-h-screen bg-neutral-950 text-neutral-200 flex flex-col">
      {/* Navigation */}
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
            <Link href="/delete-account" className="text-neutral-400 hover:text-white transition">
              Delete Account
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
        <div className="space-y-8">
          <div>
            <h1 className="text-3xl font-extrabold tracking-tight text-white sm:text-4xl">
              Terms and Conditions
            </h1>
            <p className="mt-2 text-sm text-neutral-400">
              Last updated: October 17, 2026
            </p>
          </div>

          <div className="prose prose-invert max-w-none text-neutral-300 space-y-6 text-sm leading-relaxed">
            <section className="space-y-3">
              <h2 className="text-lg font-semibold text-white">1. Agreement to Terms</h2>
              <p>
                By accessing or using the TodoCat website (
                <a href="https://to-do-cat.vercel.app" className="text-white underline">
                  https://to-do-cat.vercel.app
                </a>
                ) and associated mobile applications, you agree to be bound by these Terms and Conditions. If you do not agree with any part of these terms, you must not use our service.
              </p>
            </section>

            <section className="space-y-3">
              <h2 className="text-lg font-semibold text-white">2. User Accounts and Security</h2>
              <p>
                When creating an account, you must provide accurate, complete, and current information. You are solely responsible for safeguarding the credentials associated with your account and for all activities that occur under your account.
              </p>
              <p>
                Notify us immediately upon becoming aware of any breach of security or unauthorized use of your account.
              </p>
            </section>

            <section className="space-y-3">
              <h2 className="text-lg font-semibold text-white">3. Acceptable Use</h2>
              <p>You agree not to use TodoCat to:</p>
              <ul className="list-disc pl-5 space-y-1.5 text-neutral-400">
                <li>Violate any applicable local, national, or international law or regulation.</li>
                <li>Attempt to gain unauthorized access to our servers, user accounts, or computer systems.</li>
                <li>Transmit viruses, malware, or any other code of a destructive or disruptive nature.</li>
                <li>Interfere with or disrupt the integrity or performance of the service.</li>
              </ul>
            </section>

            <section className="space-y-3">
              <h2 className="text-lg font-semibold text-white">4. Intellectual Property</h2>
              <p>
                TodoCat, its original features, visual styling, source code, and design assets are the exclusive property of the developer and are protected by applicable intellectual property laws.
              </p>
              <p>
                You retain full ownership and intellectual rights to the task titles, descriptions, and content you create and store within TodoCat.
              </p>
            </section>

            <section className="space-y-3">
              <h2 className="text-lg font-semibold text-white">5. Termination</h2>
              <p>
                We reserve the right to suspend or terminate your access to TodoCat immediately, without prior notice or liability, for any reason, including without limitation if you breach these Terms and Conditions.
              </p>
              <p>
                You may discontinue using TodoCat at any time and request deletion of your account and personal data.
              </p>
            </section>

            <section className="space-y-3">
              <h2 className="text-lg font-semibold text-white">6. Limitation of Liability</h2>
              <p>
                To the maximum extent permitted by applicable law, TodoCat is provided on an &ldquo;AS IS&rdquo; and &ldquo;AS AVAILABLE&rdquo; basis without warranties of any kind, whether express or implied.
              </p>
              <p>
                In no event shall TodoCat or its developer be liable for any indirect, incidental, special, consequential, or punitive damages arising out of your access to, use of, or inability to use the service.
              </p>
            </section>

            <section className="space-y-3">
              <h2 className="text-lg font-semibold text-white">7. Governing Law and Changes</h2>
              <p>
                We reserve the right to modify or replace these Terms at any time. We will indicate the date of the latest update at the top of this document. Your continued use of the service after any revisions constitutes your acceptance of the new terms.
              </p>
            </section>

            <section className="space-y-3">
              <h2 className="text-lg font-semibold text-white">8. Contact Information</h2>
              <p>
                If you have any questions about these Terms and Conditions, please contact us:
              </p>
              <div className="p-4 rounded-xl bg-neutral-900 border border-neutral-800 text-neutral-300">
                <p className="font-medium text-white">TodoCat Inquiries &ndash; Nandakishore P</p>
                <p className="text-xs text-neutral-400 mt-1">
                  Developer Email:{" "}
                  <a href="mailto:nandakishorep212@gmail.com" className="text-white hover:underline">
                    nandakishorep212@gmail.com
                  </a>
                </p>
                <p className="text-xs text-neutral-400 mt-0.5">
                  GitHub Repository:{" "}
                  <a
                    href="https://github.com/nanda-kshr/ToDo-Cat"
                    target="_blank"
                    rel="noopener noreferrer"
                    className="text-white hover:underline"
                  >
                    https://github.com/nanda-kshr/ToDo-Cat
                  </a>
                </p>
              </div>
            </section>
          </div>
        </div>
      </main>

      {/* Footer */}
      <footer className="border-t border-neutral-900 py-8 px-4 sm:px-6 text-xs text-neutral-500">
        <div className="max-w-4xl mx-auto flex flex-col sm:flex-row items-center justify-between gap-4">
          <p>&copy; 2026 TodoCat. All rights reserved.</p>
          <div className="flex items-center gap-4">
            <Link href="/" className="hover:text-neutral-300 transition">Home</Link>
            <Link href="/privacy" className="hover:text-neutral-300 transition">Privacy Policy</Link>
            <Link href="/delete-account" className="hover:text-neutral-300 transition">Delete Account</Link>
            <Link href="/auth" className="hover:text-neutral-300 transition">Sign In</Link>
          </div>
        </div>
      </footer>
    </div>
  );
}
