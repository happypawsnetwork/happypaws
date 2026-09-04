"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { motion } from "framer-motion";
import { AdminLogo } from "./AdminLogo";
import {
  LayoutDashboardIcon,
  MapIcon,
  FileCheck2Icon,
  UsersIcon,
  UsersRoundIcon,
  MessageSquareIcon,
} from "./Icons";
import { useMessaging } from "@/providers/MessagingProvider";

const navItems = [
  { name: "Dashboard", path: "/admin", icon: LayoutDashboardIcon },
  { name: "Rescue map", path: "/admin/rescue-map", icon: MapIcon },
  { name: "Verifications", path: "/admin/verifications", icon: FileCheck2Icon },
  { name: "Community", path: "/admin/community", icon: UsersIcon },
  { name: "Messages", path: "/admin/messages", icon: MessageSquareIcon },
  { name: "Pending approvals", path: "/admin/approvals", icon: FileCheck2Icon },
  { name: "Users", path: "/admin/users", icon: UsersRoundIcon },
];

export function AdminSidebar() {
  const pathname = usePathname();
  const { unreadCount } = useMessaging();

  return (
    <aside className="w-64 h-screen border-r border-slate-200/80 bg-white/70 backdrop-blur-xl flex flex-col pt-6 pb-4 px-4 sticky top-0 shrink-0 z-20">
      <Link
        href="/admin"
        aria-label="Happy Paws Admin"
        className="px-2 mb-8 flex items-center focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-blue-500 rounded-lg"
      >
        <AdminLogo className="h-8 w-auto" />
      </Link>

      <nav className="flex-1 flex flex-col gap-1.5">
        {navItems.map((item) => {
          const isActive =
            item.path === "/admin"
              ? pathname === "/admin"
              : pathname === item.path ||
                (item.path === "/admin/community" &&
                  (pathname.startsWith("/admin/rescues") ||
                    pathname.startsWith("/admin/transports") ||
                    pathname.startsWith("/admin/sponsorships")));

          return (
            <Link
              key={item.path}
              href={item.path}
              className="relative px-3.5 py-2.5 rounded-xl flex items-center gap-3 text-sm font-medium transition-colors outline-none focus-visible:ring-2 focus-visible:ring-blue-500 group"
            >
              {isActive && (
                <motion.div
                  layoutId="sidebar-active"
                  className="absolute inset-0 bg-blue-50/90 border border-blue-100/80 rounded-xl shadow-xs"
                  initial={false}
                  transition={{ type: "spring", bounce: 0, duration: 0.35 }}
                />
              )}
              <item.icon
                className={`w-4 h-4 relative z-10 transition-colors ${
                  isActive
                    ? "text-blue-600"
                    : "text-slate-400 group-hover:text-slate-600"
                }`}
              />
              <span
                className={`relative z-10 transition-colors ${
                  isActive
                    ? "text-blue-900 font-semibold"
                    : "text-slate-600 group-hover:text-slate-900"
                }`}
              >
                {item.name}
              </span>

              {item.path === "/admin/messages" && unreadCount > 0 && (
                <span className="relative z-10 ml-auto min-w-5 h-5 px-1.5 rounded-full bg-emerald-600 text-white text-[11px] font-bold flex items-center justify-center shadow-xs">
                  {unreadCount > 99 ? "99+" : unreadCount}
                </span>
              )}
            </Link>
          );
        })}
      </nav>

      <div className="px-3 pt-4 border-t border-slate-100">
        <p className="text-xs font-light text-slate-400">
          Admin dashboard version 1.0
        </p>
      </div>
    </aside>
  );
}
