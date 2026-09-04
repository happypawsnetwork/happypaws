"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { Users, ShieldAlert, Truck, HeartHandshake } from "lucide-react";

interface TabItem {
  name: string;
  href: string;
  icon: typeof Users;
  description: string;
}

const TABS: TabItem[] = [
  {
    name: "All posts",
    href: "/admin/community",
    icon: Users,
    description: "Moderate community feed and listings",
  },
  {
    name: "Rescues",
    href: "/admin/rescues",
    icon: ShieldAlert,
    description: "Monitor fostered cases and overrides",
  },
  {
    name: "Transports",
    href: "/admin/transports",
    icon: Truck,
    description: "Track transport tasks and animal movement",
  },
  {
    name: "Sponsorships",
    href: "/admin/sponsorships",
    icon: HeartHandshake,
    description: "Review funding requests and proof documents",
  },
];

export function CommunityNav() {
  const pathname = usePathname();

  return (
    <nav
      aria-label="Community administration sections"
      className="mb-8 border-b border-slate-200"
    >
      <div className="flex flex-wrap gap-2 sm:gap-6 -mb-px">
        {TABS.map((tab) => {
          const isActive = pathname === tab.href;
          const Icon = tab.icon;

          return (
            <Link
              key={tab.href}
              href={tab.href}
              className={`group inline-flex items-center gap-2.5 border-b-2 px-3 py-3 text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-blue-500 rounded-t-lg ${
                isActive
                  ? "border-blue-600 text-blue-600"
                  : "border-transparent text-slate-500 hover:border-slate-300 hover:text-slate-800"
              }`}
              aria-current={isActive ? "page" : undefined}
            >
              <Icon
                className={`h-4 w-4 transition-colors ${
                  isActive
                    ? "text-blue-600"
                    : "text-slate-400 group-hover:text-slate-600"
                }`}
                aria-hidden="true"
              />
              <span>{tab.name}</span>
            </Link>
          );
        })}
      </div>
    </nav>
  );
}
