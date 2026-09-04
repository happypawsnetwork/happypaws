"use client";

import React, { useState, useTransition } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { XIcon, MailIcon, RefreshCwIcon, CheckCircleIcon } from "../Icons";
import {
  sendEmailUpdateCodeAction,
  verifyEmailUpdateCodeAction,
} from "@/actions/profile";

interface EmailChangeModalProps {
  currentEmail: string;
  isOpen: boolean;
  onClose: () => void;
  onSuccess: () => void;
}

export function EmailChangeModal({
  currentEmail,
  isOpen,
  onClose,
  onSuccess,
}: EmailChangeModalProps) {
  const [step, setStep] = useState<"request" | "verify" | "success">("request");
  const [newEmail, setNewEmail] = useState("");
  const [verificationToken, setVerificationToken] = useState("");
  const [otpCode, setOtpCode] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [isPending, startTransition] = useTransition();

  if (!isOpen) return null;

  const handleSendCode = (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);

    if (
      !newEmail.trim() ||
      newEmail.trim().toLowerCase() === currentEmail.toLowerCase()
    ) {
      setError("Please provide a new and distinct email address.");
      return;
    }

    startTransition(async () => {
      try {
        const res = await sendEmailUpdateCodeAction(newEmail.trim());
        setVerificationToken(res.verificationToken);
        setStep("verify");
      } catch (err: unknown) {
        const message =
          err instanceof Error
            ? err.message
            : "Failed to dispatch verification code.";
        setError(message);
      }
    });
  };

  const handleVerifyCode = (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);

    if (!otpCode || otpCode.trim().length !== 6) {
      setError("Please enter the complete 6-digit verification code.");
      return;
    }

    startTransition(async () => {
      try {
        await verifyEmailUpdateCodeAction(verificationToken, otpCode.trim());
        setStep("success");
        setTimeout(() => {
          onSuccess();
          onClose();
        }, 1500);
      } catch (err: unknown) {
        const message =
          err instanceof Error
            ? err.message
            : "Verification code is incorrect or expired.";
        setError(message);
      }
    });
  };

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
              <div className="w-8 h-8 rounded-xl bg-blue-50 text-blue-600 flex items-center justify-center border border-blue-100">
                <MailIcon className="w-4 h-4" />
              </div>
              <div>
                <h2 className="text-base font-bold text-slate-900 leading-tight">
                  Update email address
                </h2>
                <p className="text-xs text-slate-500">
                  Secure two-step email verification.
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

          {/* Step 1: Request OTP */}
          {step === "request" && (
            <form onSubmit={handleSendCode} className="p-6 space-y-4">
              {error && (
                <div className="p-3 rounded-xl bg-rose-50 border border-rose-200 text-xs font-semibold text-rose-800">
                  {error}
                </div>
              )}

              <div className="p-3.5 rounded-xl bg-slate-50 border border-slate-200/70">
                <span className="text-xs text-slate-500 font-medium">
                  Current active email
                </span>
                <p className="text-sm font-bold text-slate-800 truncate">
                  {currentEmail}
                </p>
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-700 mb-1">
                  New email address
                </label>
                <input
                  type="email"
                  required
                  value={newEmail}
                  onChange={(e) => setNewEmail(e.target.value)}
                  placeholder="new.address@happypaws.org"
                  className="w-full px-3 py-2 text-sm rounded-xl border border-slate-200 focus:border-blue-500 focus:ring-1 focus:ring-blue-500 outline-none transition-all"
                />
              </div>

              <div className="p-3 rounded-xl bg-blue-50/70 border border-blue-200/70 text-xs text-blue-900">
                A 6-digit confirmation code will be sent to the new email
                address to verify ownership.
              </div>

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
                  className="px-4 py-2 bg-blue-600 hover:bg-blue-700 disabled:bg-slate-300 text-white text-xs font-semibold rounded-xl shadow-xs transition-colors flex items-center gap-1.5 cursor-pointer"
                >
                  {isPending ? (
                    <>
                      <RefreshCwIcon className="w-3.5 h-3.5 animate-spin" />
                      <span>Sending code...</span>
                    </>
                  ) : (
                    <span>Send verification code</span>
                  )}
                </button>
              </div>
            </form>
          )}

          {/* Step 2: Verify OTP */}
          {step === "verify" && (
            <form onSubmit={handleVerifyCode} className="p-6 space-y-4">
              {error && (
                <div className="p-3 rounded-xl bg-rose-50 border border-rose-200 text-xs font-semibold text-rose-800">
                  {error}
                </div>
              )}

              <div className="p-3.5 rounded-xl bg-slate-50 border border-slate-200/70">
                <span className="text-xs text-slate-500 font-medium">
                  Verifying new email
                </span>
                <p className="text-sm font-bold text-slate-800 truncate">
                  {newEmail}
                </p>
                <button
                  type="button"
                  onClick={() => setStep("request")}
                  className="mt-1 text-xs text-blue-600 hover:underline cursor-pointer"
                >
                  Change email address
                </button>
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-700 mb-1">
                  6-digit verification code
                </label>
                <input
                  type="text"
                  maxLength={6}
                  required
                  value={otpCode}
                  onChange={(e) =>
                    setOtpCode(e.target.value.replace(/\D/g, ""))
                  }
                  placeholder="123456"
                  className="w-full px-3 py-2 text-center text-xl font-mono tracking-widest rounded-xl border border-slate-200 focus:border-blue-500 focus:ring-1 focus:ring-blue-500 outline-none transition-all"
                />
              </div>

              <div className="pt-3 border-t border-slate-100 flex items-center justify-end gap-2">
                <button
                  type="button"
                  onClick={() => setStep("request")}
                  className="px-4 py-2 text-xs font-semibold text-slate-600 hover:text-slate-900 rounded-xl hover:bg-slate-100 transition-colors cursor-pointer"
                >
                  Back
                </button>
                <button
                  type="submit"
                  disabled={isPending}
                  className="px-4 py-2 bg-blue-600 hover:bg-blue-700 disabled:bg-slate-300 text-white text-xs font-semibold rounded-xl shadow-xs transition-colors flex items-center gap-1.5 cursor-pointer"
                >
                  {isPending ? (
                    <>
                      <RefreshCwIcon className="w-3.5 h-3.5 animate-spin" />
                      <span>Verifying code...</span>
                    </>
                  ) : (
                    <span>Confirm new email</span>
                  )}
                </button>
              </div>
            </form>
          )}

          {/* Step 3: Success Banner */}
          {step === "success" && (
            <div className="p-8 text-center space-y-3">
              <div className="w-12 h-12 rounded-full bg-emerald-100 text-emerald-600 mx-auto flex items-center justify-center">
                <CheckCircleIcon className="w-6 h-6" />
              </div>
              <h3 className="text-base font-bold text-slate-900">
                Email updated successfully
              </h3>
              <p className="text-xs text-slate-500">
                Your login email has been updated.
              </p>
            </div>
          )}
        </motion.div>
      </div>
    </AnimatePresence>
  );
}
