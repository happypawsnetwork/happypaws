"use client";

import { useState } from "react";
import { UrgencyAssessmentCard } from "@/components/admin/UrgencyAssessmentCard";

interface RescueUrgencyCellProps {
  post: {
    id: string | number;
    urgencyLevel?: string | null;
    aiTriageReason?: string | null;
    isUrgencyManuallyOverridden?: boolean | null;
  };
}

export function RescueUrgencyCell({ post }: RescueUrgencyCellProps) {
  const [isOpen, setIsOpen] = useState(false);

  const urgencyColors: Record<string, string> = {
    Critical: "bg-red-50 text-red-700 ring-red-600/20",
    High: "bg-orange-50 text-orange-700 ring-orange-600/20",
    Medium: "bg-yellow-50 text-yellow-700 ring-yellow-600/20",
    Low: "bg-emerald-50 text-emerald-700 ring-emerald-600/20",
  };

  const level = post.urgencyLevel || "Medium";
  const colorClass =
    urgencyColors[level] || "bg-slate-50 text-slate-700 ring-slate-600/20";

  return (
    <>
      <button
        onClick={() => setIsOpen(true)}
        className={`inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium ring-1 ring-inset ${colorClass} hover:opacity-80 transition-opacity`}
      >
        {level}
      </button>

      {isOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/50 p-4">
          <div className="bg-white rounded-2xl shadow-xl w-full max-w-md p-6 relative">
            <button
              onClick={() => setIsOpen(false)}
              className="absolute top-4 right-4 text-slate-400 hover:text-slate-600"
            >
              <svg
                xmlns="http://www.w3.org/2000/svg"
                width="24"
                height="24"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2"
                strokeLinecap="round"
                strokeLinejoin="round"
              >
                <line x1="18" y1="6" x2="6" y2="18"></line>
                <line x1="6" y1="6" x2="18" y2="18"></line>
              </svg>
            </button>
            <UrgencyAssessmentCard
              postId={String(post.id)}
              urgencyLevel={post.urgencyLevel}
              aiTriageReason={post.aiTriageReason}
              isUrgencyManuallyOverridden={post.isUrgencyManuallyOverridden}
            />
          </div>
        </div>
      )}
    </>
  );
}
