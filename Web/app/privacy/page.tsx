import Link from "next/link";
import Image from "next/image";
import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Privacy Policy | TodoCat",
  description: "Privacy Policy for TodoCat task management platform and mobile application.",
};

export default function PrivacyPage() {
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
            <Link href="/terms" className="text-neutral-400 hover:text-white transition">
              Terms & Conditions
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
              Privacy Policy
            </h1>
            <p className="mt-2 text-sm text-neutral-400">
              Last updated: October 17, 2026
            </p>
          </div>

          <div className="prose prose-invert max-w-none text-neutral-300 space-y-6 text-sm leading-relaxed">
            <section className="space-y-3">
              <h2 className="text-lg font-semibold text-white">1. Introduction</h2>
              <p>
                Welcome to TodoCat (&ldquo;we,&rdquo; &ldquo;our,&rdquo; or &ldquo;us&rdquo;). We respect your privacy and are committed to protecting the personal data you share with us. This Privacy Policy explains how we collect, use, and safeguard your information when you visit our website at{" "}
                <a href="https://todocat.instaroid.page" className="text-white underline">
                  https://todocat.instaroid.page
                </a>{" "}
                and use the TodoCat mobile application.
              </p>
            </section>

            <section className="space-y-3">
              <h2 className="text-lg font-semibold text-white">2. Information We Collect</h2>
              <p>We collect information directly from you and automatically through your use of TodoCat:</p>
              <ul className="list-disc pl-5 space-y-1.5 text-neutral-400">
                <li>
                  <strong className="text-neutral-200">Account Information:</strong> When you register via email and password, we collect your email address, password hash, and optional display name.
                </li>
                <li>
                  <strong className="text-neutral-200">Google Authentication Data:</strong> If you choose to continue with Google, we receive your name, email address, Google profile ID, and avatar URL as authorized via OAuth consent.
                </li>
                <li>
                  <strong className="text-neutral-200">Task Data:</strong> We store the tasks, titles, descriptions, due dates, priority levels, categories, and completion states you create.
                </li>
                <li>
                  <strong className="text-neutral-200">Technical Information:</strong> Standard server logs, device identifiers, and session tokens necessary to authenticate requests and secure your account.
                </li>
              </ul>
            </section>

            <section className="space-y-3">
              <h2 className="text-lg font-semibold text-white">3. How We Use Your Information</h2>
              <p>We use your information exclusively to provide and improve TodoCat:</p>
              <ul className="list-disc pl-5 space-y-1.5 text-neutral-400">
                <li>To authenticate your identity and maintain active sessions.</li>
                <li>To store, update, and synchronize your tasks in real time across the web and mobile app.</li>
                <li>To secure our services against unauthorized access, abuse, and fraudulent activity.</li>
                <li>To communicate important updates regarding your account or service changes.</li>
              </ul>
              <p>We do not sell, rent, or trade your personal data to advertisers or third parties.</p>
            </section>

            <section className="space-y-3">
              <h2 className="text-lg font-semibold text-white">4. Google API Services User Data Policy</h2>
              <p>
                TodoCat&apos;s use and transfer to any other app of information received from Google APIs will adhere to the{" "}
                <a
                  href="https://developers.google.com/terms/api-services-user-data-policy"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-white underline"
                >
                  Google API Services User Data Policy
                </a>
                , including the Limited Use requirements.
              </p>
            </section>

            <section className="space-y-3">
              <h2 className="text-lg font-semibold text-white">5. Data Storage and Security</h2>
              <p>
                Your data is stored in secured cloud databases with industry-standard encryption in transit (HTTPS/TLS) and at rest. Passwords are cryptographically hashed using salted bcrypt before storage. Access tokens are short-lived JWTs.
              </p>
            </section>

            <section className="space-y-3">
              <h2 className="text-lg font-semibold text-white">6. Your Rights and Data Deletion</h2>
              <p>
                You have full control over your data. You may edit or delete individual tasks at any time directly through the app or dashboard. If you wish to delete your entire account and all associated data, you can request full deletion through our{" "}
                <Link href="/delete-account" className="text-white underline">
                  Account Deletion Portal
                </Link>{" "}
                or by contacting developer Nandakishore P at{" "}
                <a href="mailto:nandakishorep212@gmail.com" className="text-white underline">
                  nandakishorep212@gmail.com
                </a>
                . All data will be permanently wiped upon verification.
              </p>
            </section>

            <section className="space-y-3">
              <h2 className="text-lg font-semibold text-white">7. Changes to This Policy</h2>
              <p>
                We may update this Privacy Policy periodically. We will notify you of any material changes by updating the &ldquo;Last updated&rdquo; date at the top of this page.
              </p>
            </section>

            <section className="space-y-3">
              <h2 className="text-lg font-semibold text-white">8. Contact Us</h2>
              <p>
                If you have questions or concerns about this Privacy Policy, please contact the developer:
              </p>
              <div className="p-4 rounded-xl bg-neutral-900 border border-neutral-800 text-neutral-300">
                <p className="font-medium text-white">TodoCat Support &amp; Privacy</p>
                <p className="text-xs text-neutral-400 mt-1">
                  Email:{" "}
                  <a href="mailto:nandakishorep212@gmail.com" className="text-white hover:underline">
                    nandakishorep212@gmail.com
                  </a>
                </p>
                <p className="text-xs text-neutral-400 mt-0.5">
                  GitHub:{" "}
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
          <div className="flex flex-wrap items-center gap-4">
            <Link href="/" className="hover:text-neutral-300 transition">Home</Link>
            <Link href="/about" className="hover:text-neutral-300 transition">About Developer</Link>
            <Link href="/terms" className="hover:text-neutral-300 transition">Terms &amp; Conditions</Link>
            <Link href="/delete-account" className="hover:text-neutral-300 transition">Delete Account</Link>
            <a
              href="https://buymeacoffee.com/nanda_kshr"
              target="_blank"
              rel="noopener noreferrer"
              className="text-amber-400 hover:text-amber-300 transition"
            >
              Buy Me a Coffee
            </a>
            <Link href="/auth" className="hover:text-neutral-300 transition">Sign In</Link>
          </div>
        </div>
      </footer>
    </div>
  );
}
