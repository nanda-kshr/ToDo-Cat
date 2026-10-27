import React from "react";

export function CoffeeIcon({
  className = "w-4 h-4",
  ...props
}: React.SVGProps<SVGSVGElement>) {
  return (
    <svg
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
      className={className}
      {...props}
    >
      <path d="M10 2v2" />
      <path d="M14 2v2" />
      <path d="M16 8a1 1 0 0 1 1 1v8a4 4 0 0 1-4 4H7a4 4 0 0 1-4-4V9a1 1 0 0 1 1-1h12Z" />
      <path d="M6 2v2" />
      <path d="M17 8h1a4 4 0 0 1 4 4v1a4 4 0 0 1-4 4h-1" />
    </svg>
  );
}

export function HeartIcon({
  className = "w-4 h-4",
  ...props
}: React.SVGProps<SVGSVGElement>) {
  return (
    <svg
      viewBox="0 0 24 24"
      fill="currentColor"
      className={className}
      {...props}
    >
      <path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z" />
    </svg>
  );
}

export function PawIcon({
  className = "w-4 h-4",
  ...props
}: React.SVGProps<SVGSVGElement>) {
  return (
    <svg
      viewBox="0 0 24 24"
      fill="currentColor"
      className={className}
      {...props}
    >
      <path d="M12 11.5c1.66 0 3-1.34 3-3s-1.34-3-3-3-3 1.34-3 3 1.34 3 3 3zm-6-2c1.38 0 2.5-1.12 2.5-2.5S7.38 4.5 6 4.5 3.5 5.62 3.5 7 4.62 9.5 6 9.5zm12 0c1.38 0 2.5-1.12 2.5-2.5S19.38 4.5 18 4.5 15.5 5.62 15.5 7s1.12 2.5 2.5 2.5zm-6 3.5c-3.1 0-5.5 1.9-5.5 4.5 0 1.9 1.6 3.5 3.5 3.5.7 0 1.4-.2 2-.6.6.4 1.3.6 2 .6 1.9 0 3.5-1.6 3.5-3.5 0-2.6-2.4-4.5-5.5-4.5z" />
    </svg>
  );
}
