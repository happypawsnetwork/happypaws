"use client";

import React, { useState, useTransition } from "react";
import {
  KeyIcon,
  MailIcon,
  ShieldCheckIcon,
  RefreshCwIcon,
  EyeIcon,
  EyeOffIcon,
} from "../Icons";
import { EmailChangeModal } from "./EmailChangeModal";
import { changePasswordAction } from "@/actions/profile";
import type { UserProfile } from "@/actions/profile";

interface SecurityTabProps {
  profile: UserProfile;
  onEmailUpdated: () => void;
}

export function SecurityTab({ profile, onEmailUpdated }: SecurityTabProps) {
  const [oldPassword, setOldPassword] = useState("");
  const [newPassword, setNewPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [showOldPassword, setShowOldPassword] = useState(false);
  const [showNewPassword, setShowNewPassword] = useState(false);
  const [isEmailModalOpen, setIsEmailModalOpen] = useState(false);
  const [message, setMessage] = useState<{
    text: string;
    type: "success" | "error";
  } | null>(null);
  const [isPending, startTransition] = useTransition();

  const handlePasswordSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setMessage(null);

    if (!oldPassword || !newPassword || !confirmPassword) {
      setMessage({
        text: "Please fill in all password fields.",
        type: "error",
      });
      return;
    }

    if (newPassword.length < 6) {
      setMessage({
        text: "New password must contain at least 6 characters.",
        type: "error",
      });
      return;
    }

    if (newPassword !== confirmPassword) {
      setMessage({
        text: "New password confirmation does not match.",
        type: "error",
      });
      return;
    }

    startTransition(async () => {
      try {
        await changePasswordAction(oldPassword, newPassword);
        setMessage({
          text: "Password updated successfully. Other active sessions have been revoked.",
          type: "success",
        });
        setOldPassword("");
        setNewPassword("");
        setConfirmPassword("");
      } catch (err: unknown) {
        const errMessage =
          err instanceof Error ? err.message : "Failed to change password.";
        setMessage({ text: errMessage, type: "error" });
      }
    });
  };

  // Calculate password strength
  const hasMinLength = newPassword.length >= 8;
  const hasNumber = /\d/.test(newPassword);
  const hasSpecial = /[!@#$%^&*(),.?":{}|<>]/.test(newPassword);
  const strengthScore = [
    hasMinLength,
    hasNumber,
    hasSpecial,
    newPassword.length >= 12,
  ].filter(Boolean).length;

  return (
    <div className="space-y-6">
      {/* Notification Banner */}
      {message && (
        <div
          className={`p-3.5 rounded-xl text-xs font-semibold flex items-center justify-between border ${
            message.type === "success"
              ? "bg-emerald-50 text-emerald-800 border-emerald-200"
              : "bg-rose-50 text-rose-800 border-rose-200"
          }`}
        >
          <span>{message.text}</span>
          <button
            type="button"
            onClick={() => setMessage(null)}
            className="text-xs underline ml-2 cursor-pointer"
          >
            Dismiss
          </button>
        </div>
      )}

      {/* Two-Factor Authentication Status Card */}
      <div className="p-6 rounded-2xl bg-white border border-slate-200/80 shadow-xs">
        <div className="flex items-start justify-between gap-4">
          <div className="flex items-start gap-3.5">
            <div className="w-10 h-10 rounded-xl bg-emerald-50 text-emerald-600 flex items-center justify-center border border-emerald-100 shrink-0">
              <ShieldCheckIcon className="w-5 h-5" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h2 className="text-base font-bold text-slate-900 leading-tight">
                  Two-factor authentication (2FA)
                </h2>
                <span className="px-2 py-0.5 rounded-full text-[11px] font-semibold bg-emerald-50 text-emerald-700 border border-emerald-200">
                  Enforced
                </span>
              </div>
              <p className="text-xs text-slate-500 mt-1 max-w-xl">
                Every administrator login requires entering a 6-digit OTP code
                dispatched to your registered email address to protect platform
                governance.
              </p>
            </div>
          </div>
        </div>
      </div>

      {/* Email Address Management Card */}
      <div className="p-6 rounded-2xl bg-white border border-slate-200/80 shadow-xs">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div className="flex items-start gap-3.5">
            <div className="w-10 h-10 rounded-xl bg-blue-50 text-blue-600 flex items-center justify-center border border-blue-100 shrink-0">
              <MailIcon className="w-5 h-5" />
            </div>
            <div>
              <h2 className="text-base font-bold text-slate-900 leading-tight">
                Primary email address
              </h2>
              <p className="text-xs text-slate-500 mt-0.5">
                Current email:{" "}
                <span className="font-semibold text-slate-800">
                  {profile.email}
                </span>
              </p>
            </div>
          </div>

          <button
            type="button"
            onClick={() => setIsEmailModalOpen(true)}
            className="px-4 py-2 bg-slate-50 hover:bg-slate-100 text-slate-700 border border-slate-200/80 rounded-xl text-xs font-semibold shadow-xs transition-colors cursor-pointer"
          >
            Change email
          </button>
        </div>
      </div>

      {/* Password Change Form Card */}
      <form
        onSubmit={handlePasswordSubmit}
        className="p-6 rounded-2xl bg-white border border-slate-200/80 shadow-xs space-y-5"
      >
        <div className="flex items-start gap-3.5">
          <div className="w-10 h-10 rounded-xl bg-indigo-50 text-indigo-600 flex items-center justify-center border border-indigo-100 shrink-0">
            <KeyIcon className="w-5 h-5" />
          </div>
          <div>
            <h2 className="text-base font-bold text-slate-900 leading-tight">
              Change password
            </h2>
            <p className="text-xs text-slate-500 mt-0.5">
              Enter your current password and specify a new secure passphrase.
            </p>
          </div>
        </div>

        <div className="space-y-4 max-w-lg">
          <div>
            <label className="block text-xs font-semibold text-slate-700 mb-1">
              Current password <span className="text-rose-500">*</span>
            </label>
            <div className="relative">
              <input
                type={showOldPassword ? "text" : "password"}
                required
                value={oldPassword}
                onChange={(e) => setOldPassword(e.target.value)}
                className="w-full pl-3.5 pr-10 py-2 text-sm rounded-xl border border-slate-200 focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500 outline-none transition-all"
              />
              <button
                type="button"
                onClick={() => setShowOldPassword(!showOldPassword)}
                className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600 cursor-pointer"
              >
                {showOldPassword ? (
                  <EyeOffIcon className="w-4 h-4" />
                ) : (
                  <EyeIcon className="w-4 h-4" />
                )}
              </button>
            </div>
          </div>

          <div>
            <label className="block text-xs font-semibold text-slate-700 mb-1">
              New password <span className="text-rose-500">*</span>
            </label>
            <div className="relative">
              <input
                type={showNewPassword ? "text" : "password"}
                required
                value={newPassword}
                onChange={(e) => setNewPassword(e.target.value)}
                placeholder="At least 6 characters"
                className="w-full pl-3.5 pr-10 py-2 text-sm rounded-xl border border-slate-200 focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500 outline-none transition-all"
              />
              <button
                type="button"
                onClick={() => setShowNewPassword(!showNewPassword)}
                className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600 cursor-pointer"
              >
                {showNewPassword ? (
                  <EyeOffIcon className="w-4 h-4" />
                ) : (
                  <EyeIcon className="w-4 h-4" />
                )}
              </button>
            </div>

            {/* Password strength meter */}
            {newPassword && (
              <div className="mt-2 space-y-1.5">
                <div className="flex gap-1 h-1.5 w-full bg-slate-100 rounded-full overflow-hidden">
                  <div
                    className={`h-full flex-1 transition-all ${strengthScore >= 1 ? "bg-amber-500" : "bg-slate-200"}`}
                  />
                  <div
                    className={`h-full flex-1 transition-all ${strengthScore >= 2 ? "bg-amber-500" : "bg-slate-200"}`}
                  />
                  <div
                    className={`h-full flex-1 transition-all ${strengthScore >= 3 ? "bg-emerald-500" : "bg-slate-200"}`}
                  />
                  <div
                    className={`h-full flex-1 transition-all ${strengthScore >= 4 ? "bg-emerald-600" : "bg-slate-200"}`}
                  />
                </div>
                <div className="flex items-center gap-3 text-[11px] text-slate-500">
                  <span
                    className={
                      hasMinLength ? "text-emerald-600 font-medium" : ""
                    }
                  >
                    8+ chars
                  </span>
                  <span
                    className={hasNumber ? "text-emerald-600 font-medium" : ""}
                  >
                    Number
                  </span>
                  <span
                    className={hasSpecial ? "text-emerald-600 font-medium" : ""}
                  >
                    Symbol
                  </span>
                </div>
              </div>
            )}
          </div>

          <div>
            <label className="block text-xs font-semibold text-slate-700 mb-1">
              Confirm new password <span className="text-rose-500">*</span>
            </label>
            <input
              type={showNewPassword ? "text" : "password"}
              required
              value={confirmPassword}
              onChange={(e) => setConfirmPassword(e.target.value)}
              className="w-full px-3.5 py-2 text-sm rounded-xl border border-slate-200 focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500 outline-none transition-all"
            />
          </div>
        </div>

        <div className="pt-3 border-t border-slate-100 flex justify-end">
          <button
            type="submit"
            disabled={isPending}
            className="px-5 py-2.5 bg-indigo-600 hover:bg-indigo-700 active:scale-[0.98] disabled:bg-slate-300 text-white text-xs font-semibold rounded-xl shadow-xs transition-all flex items-center gap-1.5 cursor-pointer"
          >
            {isPending ? (
              <>
                <RefreshCwIcon className="w-3.5 h-3.5 animate-spin" />
                <span>Updating password...</span>
              </>
            ) : (
              <span>Update password</span>
            )}
          </button>
        </div>
      </form>

      {/* Email Change Modal */}
      <EmailChangeModal
        currentEmail={profile.email}
        isOpen={isEmailModalOpen}
        onClose={() => setIsEmailModalOpen(false)}
        onSuccess={onEmailUpdated}
      />
    </div>
  );
}
