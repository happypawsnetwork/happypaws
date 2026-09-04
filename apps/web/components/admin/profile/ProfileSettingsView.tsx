"use client";

import React, { useState, useTransition, useRef } from "react";
import { motion, AnimatePresence } from "framer-motion";
import {
  UserIcon,
  KeyIcon,
  SmartphoneIcon,
  AwardIcon,
  MailIcon,
  CameraIcon,
  TrashIcon,
  RefreshCwIcon,
} from "../Icons";
import { RoleBadge } from "../users/RoleBadge";
import { PersonalInfoTab } from "./PersonalInfoTab";
import { SecurityTab } from "./SecurityTab";
import { SessionsTab } from "./SessionsTab";
import { RemoveAvatarModal } from "./RemoveAvatarModal";
import type { UserProfile, UserSession } from "@/actions/profile";
import { uploadAvatarAction, deleteAvatarAction } from "@/actions/profile";

interface ProfileSettingsViewProps {
  initialProfile: UserProfile;
  initialSessions: UserSession[];
}

const tabs = [
  { id: "personal", label: "Personal details", icon: UserIcon },
  { id: "security", label: "Security & login", icon: KeyIcon },
  { id: "sessions", label: "Active sessions", icon: SmartphoneIcon },
];

export function ProfileSettingsView({
  initialProfile,
  initialSessions,
}: ProfileSettingsViewProps) {
  const [profile, setProfile] = useState<UserProfile>(initialProfile);
  const [activeTab, setActiveTab] = useState("personal");
  const [isRemoveModalOpen, setIsRemoveModalOpen] = useState(false);
  const [isUploadingAvatar, startAvatarUploadTransition] = useTransition();
  const [isDeletingAvatar, startAvatarDeleteTransition] = useTransition();
  const [message, setMessage] = useState<{
    text: string;
    type: "success" | "error";
  } | null>(null);

  const fileInputRef = useRef<HTMLInputElement>(null);

  const formattedJoined = new Date(profile.createdAt).toLocaleDateString(
    "en-US",
    {
      month: "short",
      day: "numeric",
      year: "numeric",
    },
  );

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    if (!file.type.startsWith("image/")) {
      setMessage({
        text: "Please choose an image file (PNG, JPG, or WebP).",
        type: "error",
      });
      return;
    }

    if (file.size > 5 * 1024 * 1024) {
      setMessage({
        text: "Avatar image must be smaller than 5 MB.",
        type: "error",
      });
      return;
    }

    setMessage(null);
    const formData = new FormData();
    formData.append("file", file);

    startAvatarUploadTransition(async () => {
      try {
        const res = await uploadAvatarAction(formData);
        setProfile((prev) => ({ ...prev, avatarUrl: res.avatarUrl }));
        setMessage({
          text: "Profile picture updated successfully.",
          type: "success",
        });
      } catch (err: unknown) {
        const errMessage =
          err instanceof Error ? err.message : "Failed to upload photo.";
        setMessage({ text: errMessage, type: "error" });
      } finally {
        if (fileInputRef.current) {
          fileInputRef.current.value = "";
        }
      }
    });
  };

  const handleConfirmRemoveAvatar = () => {
    setMessage(null);
    startAvatarDeleteTransition(async () => {
      try {
        const updated = await deleteAvatarAction();
        setProfile(updated);
        setIsRemoveModalOpen(false);
        setMessage({
          text: "Profile photo removed successfully.",
          type: "success",
        });
      } catch (err: unknown) {
        const errMessage =
          err instanceof Error ? err.message : "Failed to remove avatar.";
        setMessage({ text: errMessage, type: "error" });
      }
    });
  };

  const fallbackInitials =
    `${profile.firstName.charAt(0) || ""}${
      profile.lastName.charAt(0) || ""
    }`.toUpperCase() || "HP";

  return (
    <div className="w-full max-w-5xl mx-auto space-y-8">
      {/* Top Title */}
      <div>
        <h1 className="text-3xl font-bold tracking-tight text-slate-900 font-outfit">
          Profile settings
        </h1>
        <p className="text-slate-500 mt-1 text-sm">
          Manage your personal details, access credentials, and security
          preferences.
        </p>
      </div>

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

      {/* Admin Identity Hero Card */}
      <div className="p-6 sm:p-8 rounded-2xl bg-white border border-slate-200/80 shadow-xs relative overflow-hidden">
        <div className="flex flex-col sm:flex-row items-center sm:items-start gap-6">
          {/* Avatar Photo with Hover Remove / Upload */}
          <div className="relative group shrink-0">
            <div className="w-20 h-20 sm:w-24 sm:h-24 rounded-full bg-blue-100 text-blue-700 flex items-center justify-center overflow-hidden border-2 border-blue-200/80 shadow-xs font-bold text-2xl font-outfit select-none">
              {profile.avatarUrl ? (
                // eslint-disable-next-line @next/next/no-img-element
                <img
                  src={profile.avatarUrl}
                  alt={profile.fullName}
                  className="w-full h-full object-cover"
                />
              ) : (
                fallbackInitials
              )}
            </div>

            {/* Hover Dark Overlay with Center Remove Icon if avatar exists */}
            {profile.avatarUrl && !isUploadingAvatar && (
              <div className="absolute inset-0 rounded-full bg-slate-900/60 opacity-0 group-hover:opacity-100 transition-opacity duration-200 flex items-center justify-center">
                <button
                  type="button"
                  onClick={() => setIsRemoveModalOpen(true)}
                  title="Remove profile photo"
                  aria-label="Remove profile photo"
                  className="p-2 rounded-full bg-rose-600/90 text-white hover:bg-rose-700 active:scale-95 transition-all shadow-sm cursor-pointer"
                >
                  <TrashIcon className="w-5 h-5" />
                </button>
              </div>
            )}

            {/* Spinner during upload */}
            {isUploadingAvatar && (
              <div className="absolute inset-0 rounded-full bg-white/75 backdrop-blur-xs flex items-center justify-center">
                <RefreshCwIcon className="w-6 h-6 animate-spin text-blue-600" />
              </div>
            )}
          </div>

          <input
            ref={fileInputRef}
            type="file"
            accept="image/*"
            className="hidden"
            onChange={handleFileChange}
          />

          {/* Profile Overview Details & Photo Controls */}
          <div className="flex-1 text-center sm:text-left space-y-3">
            <div className="flex flex-wrap items-center justify-center sm:justify-start gap-2.5">
              <h2 className="text-2xl font-bold text-slate-900 tracking-tight font-outfit">
                {profile.fullName}
              </h2>
              <div className="flex flex-wrap gap-1">
                {profile.roles.map((r) => (
                  <RoleBadge key={r} role={r} size="md" />
                ))}
              </div>
            </div>

            {profile.tagline && (
              <p className="text-xs italic text-slate-600 font-medium">
                &ldquo;{profile.tagline}&rdquo;
              </p>
            )}

            <div className="flex flex-wrap items-center justify-center sm:justify-start gap-4 text-xs text-slate-500 pt-0.5">
              <div className="flex items-center gap-1.5">
                <MailIcon className="w-3.5 h-3.5 text-slate-400" />
                <span>{profile.email}</span>
              </div>

              <div className="flex items-center gap-1.5">
                <AwardIcon className="w-3.5 h-3.5 text-amber-500" />
                <span className="font-semibold text-slate-700">
                  {profile.reputationPoints} reputation points
                </span>
              </div>

              <div className="flex items-center gap-1.5">
                <span className="text-slate-400">Member since:</span>
                <span className="font-semibold text-slate-700">
                  {formattedJoined}
                </span>
              </div>
            </div>

            {/* Photo Action Controls */}
            <div className="pt-2.5 border-t border-slate-100 flex flex-wrap items-center justify-center sm:justify-start gap-3.5">
              <button
                type="button"
                onClick={() => fileInputRef.current?.click()}
                disabled={isUploadingAvatar}
                className="px-3 py-1.5 bg-blue-50 text-blue-700 hover:bg-blue-100 border border-blue-200/80 rounded-xl text-xs font-semibold shadow-xs transition-colors cursor-pointer flex items-center gap-1.5 shrink-0"
              >
                <CameraIcon className="w-3.5 h-3.5" />
                <span>
                  {isUploadingAvatar ? "Uploading..." : "Choose new photo"}
                </span>
              </button>
              <span className="text-[11px] text-slate-400">
                Recommended format: JPG, PNG, or WebP. Maximum file size 5 MB.
              </span>
            </div>
          </div>
        </div>
      </div>

      {/* Confirmation Modal for Removing Avatar */}
      <RemoveAvatarModal
        isOpen={isRemoveModalOpen}
        avatarUrl={profile.avatarUrl}
        fullName={profile.fullName}
        isDeleting={isDeletingAvatar}
        onClose={() => setIsRemoveModalOpen(false)}
        onConfirm={handleConfirmRemoveAvatar}
      />

      {/* Apple-style Sliding Segmented Tab Navigation */}
      <div className="flex items-center gap-2 bg-slate-100/80 p-1.5 rounded-2xl border border-slate-200/60 max-w-lg">
        {tabs.map((tab) => {
          const isActive = activeTab === tab.id;
          const Icon = tab.icon;

          return (
            <button
              key={tab.id}
              type="button"
              onClick={() => setActiveTab(tab.id)}
              className="relative flex-1 py-2 px-3 text-xs font-semibold rounded-xl flex items-center justify-center gap-2 transition-colors cursor-pointer outline-none focus-visible:ring-2 focus-visible:ring-blue-500"
            >
              {isActive && (
                <motion.div
                  layoutId="profile-active-tab"
                  className="absolute inset-0 bg-white rounded-xl shadow-xs border border-slate-200/80"
                  transition={{ type: "spring", bounce: 0, duration: 0.3 }}
                />
              )}
              <Icon
                className={`w-4 h-4 relative z-10 transition-colors ${
                  isActive ? "text-blue-600" : "text-slate-400"
                }`}
              />
              <span
                className={`relative z-10 transition-colors ${
                  isActive
                    ? "text-blue-900 font-bold"
                    : "text-slate-600 hover:text-slate-900"
                }`}
              >
                {tab.label}
              </span>
            </button>
          );
        })}
      </div>

      {/* Tab Panels */}
      <div className="pt-2">
        <AnimatePresence mode="wait">
          {activeTab === "personal" && (
            <motion.div
              key="personal"
              initial={{ opacity: 0, y: 6 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -6 }}
              transition={{ duration: 0.2 }}
            >
              <PersonalInfoTab
                profile={profile}
                onProfileUpdated={(up) => setProfile(up)}
              />
            </motion.div>
          )}

          {activeTab === "security" && (
            <motion.div
              key="security"
              initial={{ opacity: 0, y: 6 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -6 }}
              transition={{ duration: 0.2 }}
            >
              <SecurityTab
                profile={profile}
                onEmailUpdated={() => setProfile({ ...profile })}
              />
            </motion.div>
          )}

          {activeTab === "sessions" && (
            <motion.div
              key="sessions"
              initial={{ opacity: 0, y: 6 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -6 }}
              transition={{ duration: 0.2 }}
            >
              <SessionsTab initialSessions={initialSessions} />
            </motion.div>
          )}
        </AnimatePresence>
      </div>
    </div>
  );
}
