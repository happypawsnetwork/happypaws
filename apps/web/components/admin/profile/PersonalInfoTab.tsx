"use client";

import React, { useState, useTransition } from "react";
import { RefreshCwIcon } from "../Icons";
import type { UserProfile } from "@/actions/profile";
import { updateProfileAction } from "@/actions/profile";

interface PersonalInfoTabProps {
  profile: UserProfile;
  onProfileUpdated: (updated: UserProfile) => void;
}

export function PersonalInfoTab({
  profile,
  onProfileUpdated,
}: PersonalInfoTabProps) {
  const [firstName, setFirstName] = useState(profile.firstName);
  const [lastName, setLastName] = useState(profile.lastName);
  const [phoneNumber, setPhoneNumber] = useState(profile.phoneNumber || "");
  const [tagline, setTagline] = useState(profile.tagline || "");
  const [isUpdatingInfo, startInfoTransition] = useTransition();
  const [message, setMessage] = useState<{
    text: string;
    type: "success" | "error";
  } | null>(null);

  const handleInfoSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setMessage(null);

    if (!firstName.trim() || !lastName.trim()) {
      setMessage({ text: "First and last name are required.", type: "error" });
      return;
    }

    startInfoTransition(async () => {
      try {
        const updated = await updateProfileAction({
          firstName: firstName.trim(),
          lastName: lastName.trim(),
          phoneNumber: phoneNumber.trim() || null,
          tagline: tagline.trim() || null,
        });
        onProfileUpdated(updated);
        setMessage({
          text: "Personal details saved successfully.",
          type: "success",
        });
      } catch (err: unknown) {
        const errMessage =
          err instanceof Error ? err.message : "Failed to save changes.";
        setMessage({ text: errMessage, type: "error" });
      }
    });
  };

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

      {/* Personal Details Form */}
      <form
        onSubmit={handleInfoSubmit}
        className="p-6 rounded-2xl bg-white border border-slate-200/80 shadow-xs space-y-5"
      >
        <div>
          <h2 className="text-base font-bold text-slate-900 leading-tight">
            Personal information
          </h2>
          <p className="text-xs text-slate-500 mt-0.5">
            Update your administrator contact details and name.
          </p>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <div>
            <label className="block text-xs font-semibold text-slate-700 mb-1">
              First name <span className="text-rose-500">*</span>
            </label>
            <input
              type="text"
              required
              value={firstName}
              onChange={(e) => setFirstName(e.target.value)}
              className="w-full px-3.5 py-2 text-sm rounded-xl border border-slate-200 focus:border-blue-500 focus:ring-1 focus:ring-blue-500 outline-none transition-all"
            />
          </div>

          <div>
            <label className="block text-xs font-semibold text-slate-700 mb-1">
              Last name <span className="text-rose-500">*</span>
            </label>
            <input
              type="text"
              required
              value={lastName}
              onChange={(e) => setLastName(e.target.value)}
              className="w-full px-3.5 py-2 text-sm rounded-xl border border-slate-200 focus:border-blue-500 focus:ring-1 focus:ring-blue-500 outline-none transition-all"
            />
          </div>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <div>
            <label className="block text-xs font-semibold text-slate-700 mb-1">
              Primary email address
            </label>
            <input
              type="email"
              disabled
              value={profile.email}
              className="w-full px-3.5 py-2 text-sm rounded-xl border border-slate-200 bg-slate-50 text-slate-500 cursor-not-allowed outline-none"
            />
            <p className="text-[11px] text-slate-400 mt-1">
              To update your login email, visit the Security settings tab.
            </p>
          </div>

          <div>
            <label className="block text-xs font-semibold text-slate-700 mb-1">
              Phone number
            </label>
            <input
              type="tel"
              value={phoneNumber}
              onChange={(e) => setPhoneNumber(e.target.value)}
              placeholder="+94 77 123 4567"
              className="w-full px-3.5 py-2 text-sm rounded-xl border border-slate-200 focus:border-blue-500 focus:ring-1 focus:ring-blue-500 outline-none transition-all"
            />
          </div>
        </div>

        <div>
          <label className="block text-xs font-semibold text-slate-700 mb-1">
            Tagline
          </label>
          <input
            type="text"
            maxLength={150}
            value={tagline}
            onChange={(e) => setTagline(e.target.value)}
            placeholder="e.g. Senior administrator & shelter coordinator"
            className="w-full px-3.5 py-2 text-sm rounded-xl border border-slate-200 focus:border-blue-500 focus:ring-1 focus:ring-blue-500 outline-none transition-all"
          />
          <p className="text-[11px] text-slate-400 mt-1 flex justify-between">
            <span>A short headline visible across the platform.</span>
            <span>{tagline.length}/150</span>
          </p>
        </div>

        <div className="pt-3 border-t border-slate-100 flex justify-end">
          <button
            type="submit"
            disabled={isUpdatingInfo}
            className="px-5 py-2.5 bg-blue-600 hover:bg-blue-700 active:scale-[0.98] disabled:bg-slate-300 text-white text-xs font-semibold rounded-xl shadow-xs transition-all flex items-center gap-1.5 cursor-pointer"
          >
            {isUpdatingInfo ? (
              <>
                <RefreshCwIcon className="w-3.5 h-3.5 animate-spin" />
                <span>Saving changes...</span>
              </>
            ) : (
              <span>Save profile</span>
            )}
          </button>
        </div>
      </form>
    </div>
  );
}
