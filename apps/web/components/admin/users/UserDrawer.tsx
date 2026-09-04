"use client";

import React, { useState, useEffect, useTransition } from "react";
import { motion, AnimatePresence } from "framer-motion";
import {
  XIcon,
  ShieldCheckIcon,
  AwardIcon,
  SmartphoneIcon,
  MailIcon,
  PhoneIcon,
  KeyIcon,
  UserIcon,
  CheckIcon,
  RefreshCwIcon,
} from "../Icons";
import { StatusBadge } from "./StatusBadge";
import { ConfirmModal } from "../ConfirmModal";
import type { AdminUserDetail, AdminUserSummary } from "@/actions/users";
import {
  getUserByIdAction,
  updateUserStatusAction,
  updateUserRolesAction,
} from "@/actions/users";

const availableRoles = [
  "Adopter",
  "Foster",
  "Transporter",
  "Veterinarian",
  "Sponsor",
  "Administrator",
];

interface UserDrawerProps {
  user: AdminUserSummary | null;
  isOpen: boolean;
  onClose: () => void;
  onUserUpdated: () => void;
  onOpenReputationModal: (user: AdminUserSummary) => void;
  onOpenResetPasswordModal: (user: AdminUserSummary) => void;
}

export function UserDrawer({
  user,
  isOpen,
  onClose,
  onUserUpdated,
  onOpenReputationModal,
  onOpenResetPasswordModal,
}: UserDrawerProps) {
  const [detail, setDetail] = useState<AdminUserDetail | null>(null);
  const [selectedRoles, setSelectedRoles] = useState<string[]>([]);
  const [isUpdatingRoles, startRoleTransition] = useTransition();
  const [isUpdatingStatus, startStatusTransition] = useTransition();
  const [copied, setCopied] = useState(false);
  const [message, setMessage] = useState<{
    text: string;
    type: "success" | "error";
  } | null>(null);
  const [confirmConfig, setConfirmConfig] = useState<{
    title: string;
    description: string;
    confirmLabel: string;
    variant: "danger" | "success" | "warning";
    onConfirm: () => void;
  } | null>(null);

  useEffect(() => {
    let ignore = false;

    if (user && isOpen) {
      getUserByIdAction(user.id)
        .then((data) => {
          if (!ignore) {
            setDetail(data);
            setSelectedRoles(data.roles.map((r) => r.name));
          }
        })
        .catch(() => {
          if (!ignore) {
            setDetail(null);
            setSelectedRoles(user.roles);
          }
        });
    }

    return () => {
      ignore = true;
    };
  }, [user, isOpen]);

  if (!user) return null;

  const handleClose = () => {
    setDetail(null);
    setMessage(null);
    setSelectedRoles([]);
    onClose();
  };

  const handleCopyId = () => {
    navigator.clipboard.writeText(user.id.toString());
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  const handleRoleToggle = (role: string) => {
    if (selectedRoles.includes(role)) {
      if (selectedRoles.length === 1) {
        setMessage({
          text: "User must maintain at least one assigned role.",
          type: "error",
        });
        return;
      }
      setSelectedRoles(selectedRoles.filter((r) => r !== role));
    } else {
      setSelectedRoles([...selectedRoles, role]);
    }
  };

  const handleSaveRoles = () => {
    startRoleTransition(async () => {
      try {
        await updateUserRolesAction(user.id, selectedRoles);
        setMessage({
          text: "User roles updated successfully.",
          type: "success",
        });
        onUserUpdated();
      } catch (err: unknown) {
        const error =
          err instanceof Error ? err.message : "Failed to update roles.";
        setMessage({ text: error, type: "error" });
      }
    });
  };

  const handleToggleActive = (newActiveState: boolean) => {
    startStatusTransition(async () => {
      try {
        await updateUserStatusAction(user.id, { isActive: newActiveState });
        setMessage({
          text: newActiveState
            ? "User account activated."
            : "User account suspended.",
          type: "success",
        });
        if (detail) setDetail({ ...detail, isActive: newActiveState });
        onUserUpdated();
      } catch (err: unknown) {
        const error =
          err instanceof Error ? err.message : "Failed to update status.";
        setMessage({ text: error, type: "error" });
      }
    });
  };

  const handleToggleDelete = (newDeleteState: boolean) => {
    startStatusTransition(async () => {
      try {
        await updateUserStatusAction(user.id, { isDeleted: newDeleteState });
        setMessage({
          text: newDeleteState
            ? "User account deactivated."
            : "User account restored.",
          type: "success",
        });
        if (detail) setDetail({ ...detail, isDeleted: newDeleteState });
        onUserUpdated();
      } catch (err: unknown) {
        const error =
          err instanceof Error
            ? err.message
            : "Failed to modify account state.";
        setMessage({ text: error, type: "error" });
      }
    });
  };

  const formattedCreated = new Date(user.createdAt).toLocaleDateString(
    "en-US",
    {
      month: "short",
      day: "numeric",
      year: "numeric",
    },
  );

  const formattedUpdated = new Date(user.updatedAt).toLocaleDateString(
    "en-US",
    {
      month: "short",
      day: "numeric",
      year: "numeric",
    },
  );

  return (
    <AnimatePresence>
      {isOpen && (
        <>
          {/* Translucent Backdrop */}
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            transition={{ duration: 0.2 }}
            onClick={handleClose}
            className="fixed inset-0 bg-slate-950/70 backdrop-blur-md z-40"
          />

          {/* Slide-over Drawer */}
          <motion.div
            initial={{ x: "100%" }}
            animate={{ x: 0 }}
            exit={{ x: "100%" }}
            transition={{ type: "spring", bounce: 0, duration: 0.35 }}
            className="fixed inset-y-0 right-0 w-full max-w-xl bg-white shadow-2xl z-50 flex flex-col border-l border-slate-200/80 overflow-hidden"
          >
            {/* Header Bar */}
            <div className="px-6 py-4 border-b border-slate-100 flex items-center justify-between bg-white/80 backdrop-blur-md sticky top-0 z-10">
              <div className="flex items-center gap-2">
                <span className="text-xs font-semibold uppercase tracking-wider text-slate-400">
                  User inspector
                </span>
                <span className="text-slate-300">•</span>
                <button
                  type="button"
                  onClick={handleCopyId}
                  className="inline-flex items-center gap-1 px-2 py-0.5 rounded-md bg-slate-100 hover:bg-slate-200 text-[11px] font-mono text-slate-600 transition-colors cursor-pointer"
                  title="Copy User ID"
                >
                  <span>ID: #{user.id}</span>
                  {copied ? (
                    <CheckIcon className="w-3 h-3 text-emerald-600" />
                  ) : null}
                </button>
              </div>

              <button
                type="button"
                onClick={handleClose}
                aria-label="Close user inspector"
                className="p-1.5 rounded-full text-slate-400 hover:text-slate-700 hover:bg-slate-100 transition-colors cursor-pointer"
              >
                <XIcon className="w-5 h-5" />
              </button>
            </div>

            {/* Scrollable Content */}
            <div className="flex-1 overflow-y-auto p-6 space-y-6">
              {/* Notification Banner */}
              {message && (
                <div
                  className={`p-3.5 rounded-xl text-sm flex items-center justify-between border ${
                    message.type === "success"
                      ? "bg-emerald-50 text-emerald-800 border-emerald-200"
                      : "bg-rose-50 text-rose-800 border-rose-200"
                  }`}
                >
                  <span>{message.text}</span>
                  <button
                    type="button"
                    onClick={() => setMessage(null)}
                    className="text-xs font-semibold underline ml-2 cursor-pointer"
                  >
                    Dismiss
                  </button>
                </div>
              )}

              {/* User Hero Section */}
              <div className="flex items-start gap-4 p-5 rounded-2xl bg-slate-50 border border-slate-200/80">
                <div className="w-16 h-16 rounded-2xl bg-blue-100 text-blue-700 flex items-center justify-center overflow-hidden shrink-0 border border-blue-200/70 shadow-xs">
                  {user.avatarUrl ? (
                    // eslint-disable-next-line @next/next/no-img-element
                    <img
                      src={user.avatarUrl}
                      alt={`${user.firstName} ${user.lastName}`}
                      className="w-full h-full object-cover"
                    />
                  ) : (
                    <UserIcon className="w-8 h-8" />
                  )}
                </div>

                <div className="flex-1 min-w-0">
                  <div className="flex flex-wrap items-center gap-2">
                    <h2 className="text-xl font-bold text-slate-900 tracking-tight truncate">
                      {user.firstName} {user.lastName}
                    </h2>
                    <StatusBadge
                      isActive={detail ? detail.isActive : user.isActive}
                      isDeleted={detail ? detail.isDeleted : user.isDeleted}
                    />
                  </div>

                  <div className="mt-2 space-y-1 text-xs text-slate-600">
                    <div className="flex items-center gap-2 truncate">
                      <MailIcon className="w-3.5 h-3.5 text-slate-400 shrink-0" />
                      <span className="truncate">{user.email}</span>
                    </div>
                    {user.phoneNumber && (
                      <div className="flex items-center gap-2">
                        <PhoneIcon className="w-3.5 h-3.5 text-slate-400 shrink-0" />
                        <span>{user.phoneNumber}</span>
                      </div>
                    )}
                  </div>
                </div>
              </div>

              {/* Quick Metrics Grid */}
              <div className="grid grid-cols-2 sm:grid-cols-3 gap-3">
                <div className="p-3.5 rounded-xl bg-white border border-slate-200/80 shadow-xs">
                  <div className="flex items-center justify-between text-slate-400 mb-1">
                    <span className="text-xs font-medium">Reputation</span>
                    <AwardIcon className="w-4 h-4 text-amber-500" />
                  </div>
                  <div className="flex items-baseline justify-between">
                    <span className="text-lg font-bold text-slate-900 font-mono">
                      {detail ? detail.reputationPoints : user.reputationPoints}
                    </span>
                    <button
                      type="button"
                      onClick={() => onOpenReputationModal(user)}
                      className="text-xs font-semibold text-blue-600 hover:text-blue-700 hover:underline cursor-pointer"
                    >
                      Adjust
                    </button>
                  </div>
                </div>

                <div className="p-3.5 rounded-xl bg-white border border-slate-200/80 shadow-xs">
                  <div className="flex items-center justify-between text-slate-400 mb-1">
                    <span className="text-xs font-medium">Active sessions</span>
                    <SmartphoneIcon className="w-4 h-4 text-sky-500" />
                  </div>
                  <span className="text-lg font-bold text-slate-900 font-mono">
                    {detail ? detail.activeSessionsCount : "—"}
                  </span>
                </div>

                <div className="p-3.5 rounded-xl bg-white border border-slate-200/80 shadow-xs col-span-2 sm:col-span-1">
                  <div className="text-xs font-medium text-slate-400 mb-1">
                    Registered
                  </div>
                  <span className="text-xs font-semibold text-slate-700">
                    {formattedCreated}
                  </span>
                </div>
              </div>

              {/* Roles Management Section */}
              <div className="p-5 rounded-2xl bg-white border border-slate-200/80 shadow-xs space-y-4">
                <div className="flex items-center justify-between">
                  <div>
                    <h3 className="text-sm font-bold text-slate-900 flex items-center gap-2">
                      <ShieldCheckIcon className="w-4 h-4 text-blue-600" />
                      Role privileges
                    </h3>
                    <p className="text-xs text-slate-500 mt-0.5">
                      Assign elevated capabilities and operational roles to this
                      account.
                    </p>
                  </div>
                </div>

                <div className="grid grid-cols-2 sm:grid-cols-3 gap-2">
                  {availableRoles.map((role) => {
                    const isAssigned = selectedRoles.includes(role);
                    return (
                      <button
                        key={role}
                        type="button"
                        onClick={() => handleRoleToggle(role)}
                        className={`px-3 py-2.5 rounded-xl text-xs font-semibold flex items-center justify-between border transition-all cursor-pointer ${
                          isAssigned
                            ? "bg-blue-50/80 border-blue-200 text-blue-900 shadow-xs"
                            : "bg-slate-50/60 border-slate-200/80 text-slate-600 hover:bg-slate-100 hover:border-slate-300"
                        }`}
                      >
                        <span>{role}</span>
                        {isAssigned && (
                          <CheckIcon className="w-3.5 h-3.5 text-blue-600" />
                        )}
                      </button>
                    );
                  })}
                </div>

                <div className="flex justify-end pt-2">
                  <button
                    type="button"
                    disabled={isUpdatingRoles}
                    onClick={handleSaveRoles}
                    className="px-4 py-2 bg-blue-600 hover:bg-blue-700 disabled:bg-slate-300 text-white text-xs font-semibold rounded-xl shadow-xs transition-colors flex items-center gap-1.5 cursor-pointer"
                  >
                    {isUpdatingRoles ? (
                      <>
                        <RefreshCwIcon className="w-3.5 h-3.5 animate-spin" />
                        <span>Saving roles...</span>
                      </>
                    ) : (
                      <span>Save role changes</span>
                    )}
                  </button>
                </div>
              </div>

              {/* Account Security & Actions */}
              <div className="p-5 rounded-2xl bg-white border border-slate-200/80 shadow-xs space-y-4">
                <div>
                  <h3 className="text-sm font-bold text-slate-900 flex items-center gap-2">
                    <KeyIcon className="w-4 h-4 text-indigo-600" />
                    Security & governance
                  </h3>
                  <p className="text-xs text-slate-500 mt-0.5">
                    Account suspension, password reset, and account lifecycle
                    management.
                  </p>
                </div>

                <div className="space-y-2.5">
                  {/* Reset Password Action */}
                  <div className="p-3.5 rounded-xl bg-slate-50 border border-slate-200/70 flex items-center justify-between">
                    <div>
                      <p className="text-xs font-bold text-slate-800">
                        Password override
                      </p>
                      <p className="text-[11px] text-slate-500">
                        Set a new temporary password for this user.
                      </p>
                    </div>
                    <button
                      type="button"
                      onClick={() => onOpenResetPasswordModal(user)}
                      className="px-3 py-1.5 bg-white border border-slate-200 hover:bg-slate-50 text-slate-700 text-xs font-semibold rounded-lg shadow-xs transition-colors cursor-pointer"
                    >
                      Reset password
                    </button>
                  </div>

                  {/* Account Status Toggle (Active / Suspended) */}
                  <div className="p-3.5 rounded-xl bg-slate-50 border border-slate-200/70 flex items-center justify-between">
                    <div>
                      <p className="text-xs font-bold text-slate-800">
                        Account status
                      </p>
                      <p className="text-[11px] text-slate-500">
                        {user.isActive
                          ? "Account is active and able to authenticate."
                          : "Account is currently suspended."}
                      </p>
                    </div>

                    <button
                      type="button"
                      disabled={isUpdatingStatus}
                      onClick={() => {
                        if (user.isActive) {
                          setConfirmConfig({
                            title: "Suspend user account",
                            description: `Are you sure you want to suspend ${user.fullName}? The user will be immediately logged out and unable to access their account until reactivated.`,
                            confirmLabel: "Suspend account",
                            variant: "danger",
                            onConfirm: () => handleToggleActive(false),
                          });
                        } else {
                          setConfirmConfig({
                            title: "Activate user account",
                            description: `Are you sure you want to activate ${user.fullName}? The user will regain access to their account.`,
                            confirmLabel: "Activate account",
                            variant: "success",
                            onConfirm: () => handleToggleActive(true),
                          });
                        }
                      }}
                      className={`px-3 py-1.5 text-xs font-semibold rounded-lg shadow-xs transition-colors cursor-pointer ${
                        user.isActive
                          ? "bg-rose-50 text-rose-700 border border-rose-200 hover:bg-rose-100"
                          : "bg-emerald-50 text-emerald-700 border border-emerald-200 hover:bg-emerald-100"
                      }`}
                    >
                      {user.isActive ? "Suspend account" : "Activate account"}
                    </button>
                  </div>

                  {/* Deactivate / Soft Delete */}
                  <div className="p-3.5 rounded-xl bg-slate-50 border border-slate-200/70 flex items-center justify-between">
                    <div>
                      <p className="text-xs font-bold text-slate-800">
                        Deactivation state
                      </p>
                      <p className="text-[11px] text-slate-500">
                        {user.isDeleted
                          ? "Account is marked as deactivated."
                          : "Account is active in directory."}
                      </p>
                    </div>

                    <button
                      type="button"
                      disabled={isUpdatingStatus}
                      onClick={() => {
                        if (user.isDeleted) {
                          setConfirmConfig({
                            title: "Restore user account",
                            description: `Are you sure you want to restore ${user.fullName}? The account will return to active status in the directory.`,
                            confirmLabel: "Restore account",
                            variant: "success",
                            onConfirm: () => handleToggleDelete(false),
                          });
                        } else {
                          setConfirmConfig({
                            title: "Deactivate user account",
                            description: `Are you sure you want to deactivate ${user.fullName}? The account will be marked as deactivated in the user directory.`,
                            confirmLabel: "Deactivate account",
                            variant: "danger",
                            onConfirm: () => handleToggleDelete(true),
                          });
                        }
                      }}
                      className={`px-3 py-1.5 text-xs font-semibold rounded-lg shadow-xs transition-colors cursor-pointer ${
                        user.isDeleted
                          ? "bg-blue-50 text-blue-700 border border-blue-200 hover:bg-blue-100"
                          : "bg-slate-200 hover:bg-slate-300 text-slate-700 border border-slate-300"
                      }`}
                    >
                      {user.isDeleted
                        ? "Restore account"
                        : "Deactivate account"}
                    </button>
                  </div>
                </div>
              </div>

              {/* Audit Details */}
              <div className="text-[11px] text-slate-400 space-y-1 px-1">
                <p>Created: {formattedCreated}</p>
                <p>Last modified: {formattedUpdated}</p>
              </div>
            </div>
          </motion.div>

          <ConfirmModal
            isOpen={confirmConfig !== null}
            title={confirmConfig?.title || ""}
            description={confirmConfig?.description || ""}
            confirmLabel={confirmConfig?.confirmLabel}
            variant={confirmConfig?.variant}
            isPending={isUpdatingStatus}
            onConfirm={() => {
              const action = confirmConfig?.onConfirm;
              setConfirmConfig(null);
              if (action) action();
            }}
            onClose={() => setConfirmConfig(null)}
          />
        </>
      )}
    </AnimatePresence>
  );
}
