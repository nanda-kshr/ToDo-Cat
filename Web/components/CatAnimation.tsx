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

  // Calculate run cycle duration in seconds: 1.0s (slow) down to 0.2s (100% speed)
  const duration = useMemo(() => {
    if (isSleeping) return 0;
    const clamped = Math.max(1, Math.min(100, speedPercent));
    const sec = 1.0 - (clamped / 100) * 0.8;
    return Math.max(0.2, Number(sec.toFixed(3)));
  }, [speedPercent, isSleeping]);

  const frameWidth = size;
  const frameHeight = Math.round((size * 100) / 120);
  const totalWidth = frameWidth * 7;

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
          style={{ width: `${frameWidth}px`, height: `${frameHeight}px` }}
        >
          <Image
            src="/runners/cat/cat_0.png"
            alt="Resting cat"
            width={frameWidth}
            height={frameHeight}
            className="w-full h-full object-contain"
            style={{ imageRendering: "pixelated" }}
            priority
          />
        </div>
      ) : (
        // Running state: 7-frame CSS sprite sheet with dynamic speed
        <div
          className="overflow-hidden"
          style={{
            width: `${frameWidth}px`,
            height: `${frameHeight}px`,
            backgroundImage: "url('/runners/cat/cat-spritesheet.png')",
            backgroundSize: `${totalWidth}px ${frameHeight}px`,
            backgroundRepeat: "no-repeat",
            imageRendering: "pixelated",
            animation: `runcatRun ${duration}s steps(7) infinite`,
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
