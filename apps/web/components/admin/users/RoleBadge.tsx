import React from "react";

interface RoleBadgeProps {
  role: string;
  size?: "sm" | "md";
}

const roleStyles: Record<string, { bg: string; text: string; border: string }> =
  {
    Administrator: {
      bg: "bg-indigo-50/90",
      text: "text-indigo-700",
      border: "border-indigo-200/70",
    },
    Veterinarian: {
      bg: "bg-teal-50/90",
      text: "text-teal-700",
      border: "border-teal-200/70",
    },
    Transporter: {
      bg: "bg-amber-50/90",
      text: "text-amber-700",
      border: "border-amber-200/70",
    },
    Foster: {
      bg: "bg-emerald-50/90",
      text: "text-emerald-700",
      border: "border-emerald-200/70",
    },
    Sponsor: {
      bg: "bg-purple-50/90",
      text: "text-purple-700",
      border: "border-purple-200/70",
    },
    Adopter: {
      bg: "bg-slate-100/90",
      text: "text-slate-700",
      border: "border-slate-200/70",
    },
  };

export function RoleBadge({ role, size = "sm" }: RoleBadgeProps) {
  const style = roleStyles[role] || {
    bg: "bg-slate-100/90",
    text: "text-slate-700",
    border: "border-slate-200/70",
  };

  const sizeClasses =
    size === "sm"
      ? "px-2 py-0.5 text-[11px]"
      : "px-2.5 py-1 text-xs font-semibold";

  return (
    <span
      className={`inline-flex items-center font-medium rounded-md border ${style.bg} ${style.text} ${style.border} ${sizeClasses}`}
    >
      {role}
    </span>
  );
}
