"use client";

import { useState, useEffect, useRef } from "react";
import { motion, AnimatePresence } from "framer-motion";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { BellIcon, ChevronDownIcon, LogOutIcon, SettingsIcon } from "./Icons";
import { logoutAction } from "@/actions/auth";

export interface AdminUser {
  id: string;
  email: string;
  name: string;
  avatarUrl: string | null;
  roles: string[];
}

interface AdminHeaderProps {
  user: AdminUser;
}

export function AdminHeader({ user }: AdminHeaderProps) {
  const [isOpen, setIsOpen] = useState(false);
  const menuRef = useRef<HTMLDivElement>(null);
  const router = useRouter();

  useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      if (menuRef.current && !menuRef.current.contains(event.target as Node)) {
        setIsOpen(false);
      }
    }
    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  const handleLogout = async () => {
    try {
      await logoutAction();
    } catch (err) {
      console.error("Logout failed", err);
    } finally {
      router.push("/admin/login");
      router.refresh();
    }
  };

  return (
    <header className="h-16 border-b border-slate-200/80 bg-white/70 backdrop-blur-xl flex items-center justify-end px-6 sticky top-0 z-10 shrink-0">
      <div className="flex items-center gap-3">
        <button
          type="button"
          aria-label="Notifications"
          className="p-2 text-slate-500 hover:text-slate-700 transition-colors rounded-full hover:bg-slate-100/80 relative focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-blue-500"
        >
          <BellIcon className="w-5 h-5" />
          <span className="absolute top-2 right-2 w-2 h-2 bg-rose-500 rounded-full border-2 border-white" />
        </button>

        <div className="relative" ref={menuRef}>
          <button
            type="button"
            onClick={() => setIsOpen(!isOpen)}
            className="flex items-center gap-2.5 p-1 pl-2 pr-3 rounded-full hover:bg-slate-100/80 transition-colors border border-transparent hover:border-slate-200/60 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-blue-500 cursor-pointer"
          >
            <div className="w-8 h-8 rounded-full bg-blue-100 text-blue-700 flex items-center justify-center overflow-hidden shrink-0 border border-blue-200/60 font-bold text-xs font-outfit select-none">
              {user.avatarUrl ? (
                // eslint-disable-next-line @next/next/no-img-element
                <img
                  src={user.avatarUrl}
                  alt={user.name}
                  className="w-full h-full object-cover"
                />
              ) : user.name ? (
                user.name
                  .split(" ")
                  .filter(Boolean)
                  .map((n) => n[0])
                  .slice(0, 2)
                  .join("")
                  .toUpperCase()
              ) : (
                "HP"
              )}
            </div>
            <div className="text-left hidden sm:block">
              <p className="text-sm font-semibold text-slate-800 leading-none mb-0.5">
                {user.name}
              </p>
              <p className="text-[11px] text-slate-400 leading-none">Admin</p>
            </div>
            <ChevronDownIcon className="w-4 h-4 text-slate-400 ml-0.5" />
          </button>

          <AnimatePresence>
            {isOpen && (
              <motion.div
                initial={{ opacity: 0, scale: 0.95, y: -4 }}
                animate={{ opacity: 1, scale: 1, y: 0 }}
                exit={{ opacity: 0, scale: 0.95, y: -4 }}
                transition={{ type: "spring", bounce: 0, duration: 0.25 }}
                className="absolute right-0 top-full mt-2 w-60 bg-white/95 backdrop-blur-2xl rounded-2xl shadow-[0_10px_38px_rgba(0,0,0,0.1)] border border-slate-200/80 overflow-hidden origin-top-right z-50 p-1.5"
              >
                <div className="px-3 py-2.5 border-b border-slate-100 mb-1">
                  <p className="text-sm font-semibold text-slate-900 leading-tight">
                    {user.name}
                  </p>
                  <p className="text-xs text-slate-500 truncate mt-0.5">
                    {user.email}
                  </p>
                </div>
                <div className="space-y-0.5">
                  <Link
                    href="/admin/profile"
                    onClick={() => setIsOpen(false)}
                    className="flex items-center gap-2.5 px-3 py-2 text-sm font-medium text-slate-700 hover:text-slate-900 hover:bg-slate-100/80 rounded-xl transition-colors"
                  >
                    <SettingsIcon className="w-4 h-4 text-slate-500" />
                    <span>Profile Settings</span>
                  </Link>
                </div>
                <div className="pt-1 mt-1 border-t border-slate-100">
                  <button
                    type="button"
                    onClick={handleLogout}
                    className="w-full flex items-center gap-2.5 px-3 py-2 text-sm font-medium text-rose-600 hover:bg-rose-50 rounded-xl transition-colors cursor-pointer"
                  >
                    <LogOutIcon className="w-4 h-4 text-rose-500" />
                    <span>Log out</span>
                  </button>
                </div>
              </motion.div>
            )}
          </AnimatePresence>
        </div>
      </div>
    </header>
  );
}
