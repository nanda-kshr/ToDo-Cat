"use client";

import { useMemo, useState, useEffect } from "react";

export type RunnerType = "cat" | "bunny";

export interface RunnerConfig {
  id: RunnerType;
  name: string;
  runFrames: number;
  sleepFrames: number;
}

export const RUNNER_CONFIGS: Record<RunnerType, RunnerConfig> = {
  cat: {
    id: "cat",
    name: "Cat",
    runFrames: 7,
    sleepFrames: 6,
  },
  bunny: {
    id: "bunny",
    name: "Bunny",
    runFrames: 5,
    sleepFrames: 5,
  },
};

export function getGlobalRunner(): RunnerType {
  if (typeof window !== "undefined") {
    try {
      const saved = localStorage.getItem("selected_runner");
      if (saved === "bunny" || saved === "cat") return saved;
    } catch {
      // ignore
    }
  }
  return "cat";
}

export function setGlobalRunner(runner: RunnerType) {
  if (typeof window !== "undefined") {
    try {
      localStorage.setItem("selected_runner", runner);
      window.dispatchEvent(new CustomEvent("todocat_runner_changed", { detail: runner }));
    } catch {
      // ignore
    }
  }
}

interface CatAnimationProps {
  speedPercent: number; // 0 to 100
  size?: number;
  className?: string;
  theme?: "light" | "dark" | "card"; // "card" puts it in a crisp white rounded box
  runner?: RunnerType;
  isWhite?: boolean;
}

export default function CatAnimation({
  speedPercent,
  size = 48,
  className = "",
  theme = "card",
  runner: propRunner,
  isWhite,
}: CatAnimationProps) {
  const [globalRunner, setGlobalRunnerState] = useState<RunnerType>("cat");
  const [frame, setFrame] = useState(0);

  useEffect(() => {
    setGlobalRunnerState(getGlobalRunner());

    const handleRunnerChange = (e: Event) => {
      const customEvent = e as CustomEvent<RunnerType>;
      if (customEvent.detail) {
        setGlobalRunnerState(customEvent.detail);
      } else {
        setGlobalRunnerState(getGlobalRunner());
      }
    };

    window.addEventListener("todocat_runner_changed", handleRunnerChange);
    window.addEventListener("storage", handleRunnerChange);
    return () => {
      window.removeEventListener("todocat_runner_changed", handleRunnerChange);
      window.removeEventListener("storage", handleRunnerChange);
    };
  }, []);

  const currentRunner: RunnerType = propRunner || globalRunner || "cat";
  const config = RUNNER_CONFIGS[currentRunner] || RUNNER_CONFIGS.cat;
  const isSleeping = speedPercent <= 0;

  // Calculate run cycle duration in seconds: 1.0s (slow) down to 0.2s (100% speed)
  const duration = useMemo(() => {
    if (isSleeping) return 1.8;
    const clamped = Math.max(1, Math.min(100, speedPercent));
    const sec = 1.0 - (clamped / 100) * 0.8;
    return Math.max(0.2, Number(sec.toFixed(3)));
  }, [speedPercent, isSleeping]);

  const totalFrames = isSleeping ? config.sleepFrames : config.runFrames;

  // Reset frame index on state / runner switch
  useEffect(() => {
    setFrame(0);
  }, [isSleeping, currentRunner]);

  // Frame tick loop
  useEffect(() => {
    const loopDurationMs = (isSleeping ? 1.8 : duration) * 1000;
    const intervalMs = Math.max(20, Math.round(loopDurationMs / totalFrames));

    const timer = setInterval(() => {
      setFrame((prev) => (prev + 1) % totalFrames);
    }, intervalMs);

    return () => clearInterval(timer);
  }, [isSleeping, duration, totalFrames]);

  const useWhite = isWhite ?? (theme === "dark");
  const folder = `${currentRunner}${useWhite ? "_white" : ""}`;
  const stateFolder = isSleeping ? "sleep" : "run";

  const content = (
    <div
      className="relative flex items-center justify-center select-none"
      style={{ width: `${size}px`, height: `${size}px` }}
      title={
        isSleeping
          ? `${config.name} is resting`
          : `${config.name} speed: ${speedPercent}%`
      }
    >
      <div
        className="relative flex items-center justify-center"
        style={{ width: `${size}px`, height: `${size}px` }}
      >
        {Array.from({ length: totalFrames }).map((_, idx) => (
          <img
            key={`${folder}-${stateFolder}-${idx}`}
            src={`/runners/${folder}/${stateFolder}/${idx}.png`}
            alt={`${config.name} ${stateFolder} frame ${idx}`}
            width={size}
            height={size}
            style={{
              display: idx === (frame % totalFrames) ? "block" : "none",
              width: "100%",
              height: "100%",
              objectFit: "contain",
              imageRendering: "pixelated",
            }}
          />
        ))}
      </div>
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
    return <div className={className}>{content}</div>;
  }

  return <div className={className}>{content}</div>;
}
