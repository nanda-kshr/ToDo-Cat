import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "TodoCat",
  description:
    "A customizable to-do list that turns productivity into a visual experience.",
  icons: {
    icon: "/icon.svg",
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
