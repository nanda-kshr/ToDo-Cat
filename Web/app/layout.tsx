import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  metadataBase: new URL("https://todocat.instaroid.page"),
  title: {
    default: "TodoCat — Visual Task Management",
    template: "%s | TodoCat",
  },
  description:
    "TodoCat turns productivity into a visual experience powered by RunCat animation frames. Keep your tasks on track and watch your cat rest or sprint based on your workload.",
  keywords: ["TodoCat", "Todo list", "RunCat", "Productivity", "Task manager", "Flutter app", "Visual to-do"],
  authors: [{ name: "Nandakishore", url: "https://github.com/nanda-kshr/ToDo-Cat" }],
  icons: {
    icon: [
      { url: "/favicon.ico", sizes: "any" },
      { url: "/icon.svg", type: "image/svg+xml" },
      { url: "/favicon-32x32.png", type: "image/png", sizes: "32x32" },
      { url: "/favicon-16x16.png", type: "image/png", sizes: "16x16" },
      { url: "/logo.png" },
    ],
    apple: [{ url: "/apple-touch-icon.png" }],
  },
  manifest: "/manifest.json",
  openGraph: {
    title: "TodoCat — Visual Task Management",
    description: "Visual to-do list powered by RunCat animation frames.",
    url: "https://todocat.instaroid.page",
    siteName: "TodoCat",
    images: [
      {
        url: "/logo.png",
        width: 1200,
        height: 1200,
        alt: "TodoCat Logo",
      },
    ],
    locale: "en_US",
    type: "website",
  },
  twitter: {
    card: "summary_large_image",
    title: "TodoCat — Visual Task Management",
    description: "Visual to-do list powered by RunCat animation frames.",
    images: ["/logo.png"],
  },
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className="min-h-screen bg-neutral-950 text-neutral-100 antialiased flex flex-col font-sans selection:bg-neutral-800">
        {children}
      </body>
    </html>
  );
}
