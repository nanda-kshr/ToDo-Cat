import React from "react";
import { AppColors } from "@/lib/theme/colors";

interface IconProps extends React.SVGProps<SVGSVGElement> {
  size?: number | string;
}

export function CompletedIcon({ size = 16, className, ...props }: IconProps) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth={2.2}
      strokeLinecap="round"
      strokeLinejoin="round"
      className={className}
      {...props}
    >
      <circle cx={12} cy={12} r={9} />
      <path d="M8.5 12.5l2.5 2.5 5-5" />
    </svg>
  );
}

export function PendingIcon({ size = 16, className, ...props }: IconProps) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth={2.2}
      strokeLinecap="round"
      strokeLinejoin="round"
      className={className}
      {...props}
    >
      <circle cx={12} cy={12} r={9} />
      <polyline points="12 7 12 12 15 15" />
    </svg>
  );
}

export function PriorityHighIcon({ size = 14, className, ...props }: IconProps) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth={2.2}
      strokeLinecap="round"
      strokeLinejoin="round"
      className={className}
      {...props}
    >
      <path d="M12 2c.5 3.5 2.5 5 4.5 7 2 2 3 5 2 8-1 3-4 5-6.5 5S6 20 5 17c-1-3 0-6 2-8 0 2 1.5 3 3 3 0-3 1-6 2-10z" />
    </svg>
  );
}

export function PriorityMediumIcon({ size = 14, className, ...props }: IconProps) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth={2.2}
      strokeLinecap="round"
      strokeLinejoin="round"
      className={className}
      {...props}
    >
      <path d="M5 9.5h14" />
      <path d="M5 14.5h14" />
    </svg>
  );
}

export function PriorityLowIcon({ size = 14, className, ...props }: IconProps) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth={2.2}
      strokeLinecap="round"
      strokeLinejoin="round"
      className={className}
      {...props}
    >
      <path d="M7 10l5 5 5-5" />
    </svg>
  );
}

export function SharedFriendsIcon({ size = 14, className, ...props }: IconProps) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth={2.2}
      strokeLinecap="round"
      strokeLinejoin="round"
      className={className}
      {...props}
    >
      <circle cx={9} cy={7} r={4} />
      <path d="M3 21v-2a4 4 0 0 1 4-4h4a4 4 0 0 1 4 4v2" />
      <path d="M16 3.13a4 4 0 0 1 0 7.75" />
      <path d="M21 21v-2a4 4 0 0 0-3-3.85" />
    </svg>
  );
}

export function CalendarOutlinedIcon({ size = 14, className, ...props }: IconProps) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth={2.2}
      strokeLinecap="round"
      strokeLinejoin="round"
      className={className}
      {...props}
    >
      <rect x={3} y={4} width={18} height={18} rx={3} />
      <path d="M16 2v4M8 2v4M3 10h18" />
    </svg>
  );
}

export function RecurrenceOutlinedIcon({ size = 14, className, ...props }: IconProps) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth={2.2}
      strokeLinecap="round"
      strokeLinejoin="round"
      className={className}
      {...props}
    >
      <path d="M17 2l4 4-4 4" />
      <path d="M3 11V9a4 4 0 0 1 4-4h14" />
      <path d="M7 22l-4-4 4-4" />
      <path d="M21 13v2a4 4 0 0 1-4 4H3" />
    </svg>
  );
}

/**
 * Outlined Status Badge without text.
 */
export function TaskStatusBadge({
  isDone,
  isDark = true,
}: {
  isDone: boolean;
  isDark?: boolean;
}) {
  const palette = isDark ? AppColors.dark : AppColors.light;
  const color = isDone ? palette.completed : palette.pending;
  const bg = isDone ? palette.completedBg : palette.pendingBg;
  const border = isDone ? palette.completedBorder : palette.pendingBorder;

  return (
    <span
      title={isDone ? "Completed" : "Pending"}
      className="inline-flex items-center justify-center p-1 rounded-full transition-colors"
      style={{
        backgroundColor: bg,
        borderColor: border,
        borderWidth: 1.2,
        borderStyle: "solid",
        color: color,
      }}
    >
      {isDone ? <CompletedIcon size={13} /> : <PendingIcon size={13} />}
    </span>
  );
}

/**
 * Outlined Priority Badge without text.
 */
export function TaskPriorityBadge({
  priority,
  isDark = true,
}: {
  priority: string;
  isDark?: boolean;
}) {
  const palette = isDark ? AppColors.dark : AppColors.light;
  const p = (priority || "").toLowerCase();

  let color = palette.priorityMedium;
  let bg = palette.priorityMediumBg;
  let border = palette.priorityMediumBorder;
  let icon = <PriorityMediumIcon size={13} />;
  let title = "Medium Priority";

  if (p === "high") {
    color = palette.priorityHigh;
    bg = palette.priorityHighBg;
    border = palette.priorityHighBorder;
    icon = <PriorityHighIcon size={13} />;
    title = "High Priority";
  } else if (p === "low") {
    color = palette.priorityLow;
    bg = palette.priorityLowBg;
    border = palette.priorityLowBorder;
    icon = <PriorityLowIcon size={13} />;
    title = "Low Priority";
  }

  return (
    <span
      title={title}
      className="inline-flex items-center justify-center px-2 py-1 rounded-lg transition-colors"
      style={{
        backgroundColor: bg,
        borderColor: border,
        borderWidth: 1.2,
        borderStyle: "solid",
        color: color,
      }}
    >
      {icon}
    </span>
  );
}
