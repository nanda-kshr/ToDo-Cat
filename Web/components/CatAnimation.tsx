"use client";

import { useMemo } from "react";
import Image from "next/image";

interface CatAnimationProps {
  speedPercent: number; // 0 to 100
  size?: number;
  className?: string;
  theme?: "light" | "dark" | "card"; // "card" puts it in a crisp white rounded box
}

export default function CatAnimation({
  speedPercent,
  size = 48,
  className = "",
  theme = "card",
}: CatAnimationProps) {
  const isSleeping = speedPercent <= 0;

  // Calculate run cycle duration in seconds: 1.0s (slow) down to 0.15s (100% speed)
  const duration = useMemo(() => {
    if (isSleeping) return 0;
    const clamped = Math.max(1, Math.min(100, speedPercent));
    const sec = 1.0 - (clamped / 100) * 0.85;
    return Math.max(0.15, Number(sec.toFixed(3)));
  }, [speedPercent, isSleeping]);

  const totalWidth = size * 5;

  const content = (
    <div
      className="relative flex items-center justify-center select-none"
      style={{ width: `${size}px`, height: `${size}px` }}
      title={isSleeping ? "Cat is resting" : `Cat speed: ${speedPercent}%`}
    >
      {isSleeping ? (
        // Resting frame (cat_0.png)
        <div
          className="relative"
          style={{ width: `${size}px`, height: `${size}px` }}
        >
          <Image
            src="/runners/cat/cat_0.png"
            alt="Resting cat"
            width={size}
            height={size}
            className="w-full h-full object-contain"
            style={{ imageRendering: "pixelated" }}
            priority
          />
        </div>
      ) : (
        // Running state: 5-frame CSS sprite sheet with dynamic speed
        <div
          className="w-full h-full overflow-hidden"
          style={{
            width: `${size}px`,
            height: `${size}px`,
            backgroundImage: "url('/runners/cat/cat-spritesheet.png')",
            backgroundSize: `${totalWidth}px ${size}px`,
            backgroundRepeat: "no-repeat",
            imageRendering: "pixelated",
            animation: `runcatRun ${duration}s steps(5) infinite`,
          }}
        />
      )}

      <style jsx>{`
        @keyframes runcatRun {
          from {
            background-position-x: 0px;
          }
          to {
            background-position-x: -${totalWidth}px;
          }
        }
      `}</style>
    </div>
  );

  if (theme === "card") {
    return (
      <div
        className={`bg-white rounded-xl shadow-sm p-1.5 flex items-center justify-center shrink-0 ${className}`}
      >
        {content}
      </div>
    );
  }

  if (theme === "dark") {
    // Invert black pixels to white for dark background
    return <div className={`filter invert ${className}`}>{content}</div>;
  }

  return <div className={className}>{content}</div>;
}
