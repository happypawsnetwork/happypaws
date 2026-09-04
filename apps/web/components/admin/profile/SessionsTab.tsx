"use client";

import React, { useState, useTransition, useCallback, useEffect } from "react";
import { SmartphoneIcon, TrashIcon, RefreshCwIcon } from "../Icons";
import type { UserSession } from "@/actions/profile";
import {
  getActiveSessionsAction,
  revokeSessionAction,
  revokeOtherSessionsAction,
} from "@/actions/profile";

interface SessionsTabProps {
  initialSessions?: UserSession[];
}

export function SessionsTab({ initialSessions }: SessionsTabProps) {
  const [sessions, setSessions] = useState<UserSession[]>(
    initialSessions || [],
  );
  const [message, setMessage] = useState<{
    text: string;
    type: "success" | "error";
  } | null>(null);
  const [isPending, startTransition] = useTransition();

  const fetchSessions = useCallback(() => {
    startTransition(async () => {
      try {
        const data = await getActiveSessionsAction();
        setSessions(data);
      } catch (err) {
        console.error("Failed to fetch sessions:", err);
      }
    });
  }, []);

  useEffect(() => {
    if (!initialSessions) {
      fetchSessions();
    }
  }, [fetchSessions, initialSessions]);

  const handleRevokeSingle = (sessionId: string) => {
    startTransition(async () => {
      try {
        await revokeSessionAction(sessionId);
        setMessage({ text: "Session successfully revoked.", type: "success" });
        setSessions((prev: UserSession[]) =>
          prev.filter((s: UserSession) => s.id !== sessionId),
        );
      } catch (err: unknown) {
        const errMessage =
          err instanceof Error ? err.message : "Failed to revoke session.";
        setMessage({ text: errMessage, type: "error" });
      }
    });
  };

  const handleRevokeOthers = () => {
    startTransition(async () => {
      try {
        await revokeOtherSessionsAction();
        setMessage({
          text: "All other sessions have been terminated.",
          type: "success",
        });
        fetchSessions();
      } catch (err: unknown) {
        const errMessage =
          err instanceof Error
            ? err.message
            : "Failed to terminate other sessions.";
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

      {/* Sessions Overview Card */}
      <div className="p-6 rounded-2xl bg-white border border-slate-200/80 shadow-xs">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div className="flex items-start gap-3.5">
            <div className="w-10 h-10 rounded-xl bg-sky-50 text-sky-600 flex items-center justify-center border border-sky-100 shrink-0">
              <SmartphoneIcon className="w-5 h-5" />
            </div>
            <div>
              <h2 className="text-base font-bold text-slate-900 leading-tight">
                Active login sessions
              </h2>
              <p className="text-xs text-slate-500 mt-0.5">
                Devices and IP addresses with authorized refresh token grants.
              </p>
            </div>
          </div>

          <div className="flex items-center gap-2">
            <button
              type="button"
              onClick={fetchSessions}
              disabled={isPending}
              className="p-2 bg-white hover:bg-slate-50 border border-slate-200/80 rounded-xl text-slate-600 shadow-xs transition-colors cursor-pointer"
              title="Refresh sessions list"
            >
              <RefreshCwIcon
                className={`w-4 h-4 ${isPending ? "animate-spin text-blue-600" : ""}`}
              />
            </button>

            {sessions.length > 1 && (
              <button
                type="button"
                onClick={handleRevokeOthers}
                disabled={isPending}
                className="px-3.5 py-2 bg-rose-50 hover:bg-rose-100 text-rose-700 border border-rose-200/80 rounded-xl text-xs font-semibold shadow-xs transition-colors cursor-pointer"
              >
                Sign out all other sessions
              </button>
            )}
          </div>
        </div>

        {/* Sessions List */}
        <div className="mt-6 divide-y divide-slate-100 border-t border-slate-100">
          {sessions.length === 0 ? (
            <div className="py-12 text-center text-slate-400 text-xs">
              No other active device sessions found.
            </div>
          ) : (
            sessions.map((session: UserSession, index: number) => {
              const formattedCreated = new Date(
                session.createdAt,
              ).toLocaleDateString("en-US", {
                month: "short",
                day: "numeric",
                year: "numeric",
                hour: "2-digit",
                minute: "2-digit",
              });

              const isCurrentSession = index === 0;

              return (
                <div
                  key={session.id}
                  className="py-4 flex flex-col sm:flex-row sm:items-center justify-between gap-3"
                >
                  <div className="flex items-start gap-3">
                    <div className="w-8 h-8 rounded-lg bg-slate-100 text-slate-600 flex items-center justify-center shrink-0 mt-0.5">
                      <SmartphoneIcon className="w-4 h-4" />
                    </div>

                    <div>
                      <div className="flex items-center gap-2">
                        <span className="text-xs font-bold text-slate-900 font-mono">
                          IP: {session.ipAddress}
                        </span>
                        {isCurrentSession && (
                          <span className="px-2 py-0.5 rounded-full text-[10px] font-semibold bg-emerald-50 text-emerald-700 border border-emerald-200">
                            Current session
                          </span>
                        )}
                      </div>
                      <p className="text-[11px] text-slate-400 mt-0.5">
                        Logged in: {formattedCreated}
                      </p>
                    </div>
                  </div>

                  {!isCurrentSession && (
                    <button
                      type="button"
                      onClick={() => handleRevokeSingle(session.id)}
                      disabled={isPending}
                      className="self-end sm:self-center px-3 py-1.5 bg-white hover:bg-rose-50 text-slate-600 hover:text-rose-700 border border-slate-200/80 hover:border-rose-200 rounded-lg text-xs font-semibold shadow-xs transition-colors flex items-center gap-1.5 cursor-pointer"
                    >
                      <TrashIcon className="w-3.5 h-3.5" />
                      <span>Revoke</span>
                    </button>
                  )}
                </div>
              );
            })
          )}
        </div>
      </div>
    </div>
  );
}
