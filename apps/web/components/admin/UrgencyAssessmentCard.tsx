"use client";

import { useTransition } from "react";
import { Sparkles, User, Check } from "lucide-react";
import { updateRescueUrgencyAction } from "@/actions/community";
import { useRouter } from "next/navigation";

interface UrgencyAssessmentCardProps {
  postId: string;
  urgencyLevel?: string | null;
  aiTriageReason?: string | null;
  isUrgencyManuallyOverridden?: boolean | null;
}

export function UrgencyAssessmentCard({
  postId,
  urgencyLevel = "Medium",
  aiTriageReason,
  isUrgencyManuallyOverridden = false,
}: UrgencyAssessmentCardProps) {
  const [isPending, startTransition] = useTransition();
  const router = useRouter();
  const currentUrgency = urgencyLevel || "Medium";

  const handleUpdate = (level: string) => {
    if (level === currentUrgency) return;
    startTransition(async () => {
      try {
        await updateRescueUrgencyAction(postId, level);
        router.refresh();
      } catch (error) {
        console.error("Failed to update urgency:", error);
      }
    });
  };

  const getUrgencyColor = (level: string) => {
    switch (level) {
      case "Critical":
        return "text-red-600";
      case "High":
        return "text-orange-600";
      case "Medium":
        return "text-yellow-600";
      case "Low":
        return "text-emerald-600";
      default:
        return "text-slate-600";
    }
  };

  const options = ["Critical", "High", "Medium", "Low"];

  return (
    <div className="flex flex-col space-y-4">
      <h3 className="text-xl font-bold text-slate-900 font-outfit">
        Urgency assessment
      </h3>

      <div className="bg-[#fff9f0] border border-orange-200 rounded-2xl p-6">
        <div className="flex items-center text-slate-400 mb-3 text-sm font-medium">
          {isUrgencyManuallyOverridden ? (
            <>
              <User className="w-4 h-4 mr-2" />
              Admin assessed
            </>
          ) : (
            <>
              <Sparkles className="w-4 h-4 mr-2" />
              AI assessed
            </>
          )}
        </div>

        <h4
          className={`text-2xl font-bold mb-3 ${getUrgencyColor(currentUrgency)}`}
        >
          {currentUrgency} urgency
        </h4>

        <p className="text-slate-700 leading-relaxed">
          {aiTriageReason || "No specific reason provided."}
        </p>
      </div>

      <div className="pt-2">
        <p className="text-slate-500 text-sm mb-3">Not right? Adjust below.</p>
        <div className="flex flex-wrap gap-2">
          {options.map((option) => {
            const isSelected = option === currentUrgency;
            return (
              <button
                key={option}
                disabled={isPending}
                onClick={() => handleUpdate(option)}
                className={`flex items-center px-4 py-2 rounded-lg text-sm font-medium border transition-colors ${
                  isSelected
                    ? "bg-[#d8ece9] text-[#2c5f58] border-transparent"
                    : "bg-white text-slate-700 border-slate-200 hover:bg-slate-50"
                } ${isPending ? "opacity-50 cursor-not-allowed" : ""}`}
              >
                {isSelected && <Check className="w-4 h-4 mr-2" />}
                {option}
              </button>
            );
          })}
        </div>
      </div>
    </div>
  );
}
