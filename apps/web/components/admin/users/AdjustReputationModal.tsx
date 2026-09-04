"use client";

import React, { useState, useTransition } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { XIcon, AwardIcon, RefreshCwIcon } from "../Icons";
import type { AdminUserSummary } from "@/actions/users";
import { adjustUserReputationAction } from "@/actions/users";

interface AdjustReputationModalProps {
  user: AdminUserSummary | null;
  isOpen: boolean;
  onClose: () => void;
  onSuccess: () => void;
}

const quickOptions = [
  { label: "+5 Pts (Helpful)", value: 5 },
  { label: "+10 Pts (Rescue)", value: 10 },
  { label: "+25 Pts (Foster)", value: 25 },
  { label: "+50 Pts (Hero)", value: 50 },
  { label: "-10 Pts (Warning)", value: -10 },
  { label: "-25 Pts (Dispute)", value: -25 },
];

export function AdjustReputationModal({
  user,
  isOpen,
  onClose,
  onSuccess,
}: AdjustReputationModalProps) {
  const [delta, setDelta] = useState<number>(10);
  const [reason, setReason] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [isPending, startTransition] = useTransition();

  if (!isOpen || !user) return null;

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);

    if (delta === 0) {
      setError("Points adjustment cannot be zero.");
      return;
    }

    startTransition(async () => {
      try {
        await adjustUserReputationAction(
          user.id,
          delta,
          reason.trim() || undefined,
        );
        onSuccess();
        onClose();
      } catch (err: unknown) {
        const message =
          err instanceof Error
            ? err.message
            : "Failed to adjust reputation points.";
        setError(message);
      }
    });
  };

  const resultingPoints = Math.max(user.reputationPoints + delta, 0);

  return (
    <AnimatePresence>
      <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
        {/* Backdrop */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          transition={{ duration: 0.2 }}
          onClick={onClose}
          className="fixed inset-0 bg-slate-950/70 backdrop-blur-md"
        />

        {/* Modal Window */}
        <motion.div
          initial={{ opacity: 0, scale: 0.95, y: 8 }}
          animate={{ opacity: 1, scale: 1, y: 0 }}
          exit={{ opacity: 0, scale: 0.95, y: 8 }}
          transition={{ type: "spring", bounce: 0, duration: 0.28 }}
          className="relative w-full max-w-md bg-white rounded-2xl shadow-2xl border border-slate-200/90 overflow-hidden z-10"
        >
          {/* Header */}
          <div className="px-6 py-4 border-b border-slate-100 flex items-center justify-between bg-slate-50/50">
            <div className="flex items-center gap-2.5">
              <div className="w-8 h-8 rounded-xl bg-amber-50 text-amber-600 flex items-center justify-center border border-amber-100">
                <AwardIcon className="w-4 h-4" />
              </div>
              <div>
                <h2 className="text-base font-bold text-slate-900 leading-tight">
                  Adjust reputation
                </h2>
                <p className="text-xs text-slate-500">
                  Reward contributions or settle disputes.
                </p>
              </div>
            </div>

            <button
              type="button"
              onClick={onClose}
              className="p-1 rounded-full text-slate-400 hover:text-slate-700 hover:bg-slate-100 transition-colors cursor-pointer"
            >
              <XIcon className="w-5 h-5" />
            </button>
          </div>

          {/* Form */}
          <form onSubmit={handleSubmit} className="p-6 space-y-4">
            {error && (
              <div className="p-3 rounded-xl bg-rose-50 border border-rose-200 text-xs font-semibold text-rose-800">
                {error}
              </div>
            )}

            {/* Current vs Resulting Calculation */}
            <div className="p-4 rounded-xl bg-slate-50 border border-slate-200/70 flex items-center justify-between">
              <div>
                <span className="text-xs text-slate-500 font-medium">
                  Target user
                </span>
                <p className="text-sm font-bold text-slate-900 truncate">
                  {user.firstName} {user.lastName}
                </p>
              </div>

              <div className="text-right">
                <span className="text-xs text-slate-500 font-medium">
                  New score
                </span>
                <p className="text-base font-bold font-mono text-blue-600">
                  {user.reputationPoints} → {resultingPoints}
                </p>
              </div>
            </div>

            {/* Quick Increment Preset Pills */}
            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1.5">
                Preset adjustments
              </label>
              <div className="grid grid-cols-2 sm:grid-cols-3 gap-2">
                {quickOptions.map((opt) => (
                  <button
                    key={opt.label}
                    type="button"
                    onClick={() => setDelta(opt.value)}
                    className={`px-2.5 py-1.5 rounded-lg text-xs font-semibold border transition-all cursor-pointer ${
                      delta === opt.value
                        ? "bg-amber-50 border-amber-300 text-amber-900 shadow-xs"
                        : "bg-white border-slate-200 text-slate-700 hover:bg-slate-50"
                    }`}
                  >
                    {opt.label}
                  </button>
                ))}
              </div>
            </div>

            {/* Custom Points Delta Input */}
            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1">
                Custom points adjustment (+ or -)
              </label>
              <input
                type="number"
                required
                value={delta}
                onChange={(e) => setDelta(parseInt(e.target.value, 10) || 0)}
                className="w-full px-3 py-2 text-sm font-mono rounded-xl border border-slate-200 focus:border-amber-500 focus:ring-1 focus:ring-amber-500 outline-none transition-all"
              />
            </div>

            {/* Reason for Audit */}
            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1">
                Reason / administrative note
              </label>
              <textarea
                rows={2}
                value={reason}
                onChange={(e) => setReason(e.target.value)}
                placeholder="e.g. Awarded for successful emergency foster placement or dispute penalty"
                className="w-full px-3 py-2 text-sm rounded-xl border border-slate-200 focus:border-amber-500 focus:ring-1 focus:ring-amber-500 outline-none transition-all"
              />
            </div>

            {/* Actions */}
            <div className="pt-3 border-t border-slate-100 flex items-center justify-end gap-2">
              <button
                type="button"
                onClick={onClose}
                className="px-4 py-2 text-xs font-semibold text-slate-600 hover:text-slate-900 rounded-xl hover:bg-slate-100 transition-colors cursor-pointer"
              >
                Cancel
              </button>
              <button
                type="submit"
                disabled={isPending}
                className="px-4 py-2 bg-amber-500 hover:bg-amber-600 disabled:bg-slate-300 text-white text-xs font-semibold rounded-xl shadow-xs transition-colors flex items-center gap-1.5 cursor-pointer"
              >
                {isPending ? (
                  <>
                    <RefreshCwIcon className="w-3.5 h-3.5 animate-spin" />
                    <span>Applying changes...</span>
                  </>
                ) : (
                  <span>Apply adjustment</span>
                )}
              </button>
            </div>
          </form>
        </motion.div>
      </div>
    </AnimatePresence>
  );
}
