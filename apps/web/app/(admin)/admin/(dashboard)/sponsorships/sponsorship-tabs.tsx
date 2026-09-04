"use client";

import Link from "next/link";
import { usePathname, useSearchParams } from "next/navigation";

const tabs = ["PendingApproval", "Active", "Funded", "Rejected", "Closed"];

export function SponsorshipTabs({ currentStatus }: { currentStatus: string }) {
  const pathname = usePathname();
  const searchParams = useSearchParams();

  return (
    <div className="border-b border-slate-200">
      <nav className="-mb-px flex space-x-8" aria-label="Tabs">
        {tabs.map((tab) => {
          // create a new params object
          const params = new URLSearchParams(searchParams.toString());
          params.set("status", tab);
          return (
            <Link
              key={tab}
              href={`${pathname}?${params.toString()}`}
              className={`whitespace-nowrap border-b-2 px-1 py-4 text-sm font-medium ${
                currentStatus === tab
                  ? "border-blue-500 text-blue-600"
                  : "border-transparent text-slate-500 hover:border-slate-300 hover:text-slate-700"
              }`}
            >
              {tab.replace(/([A-Z])/g, " $1").trim()}
            </Link>
          );
        })}
      </nav>
    </div>
  );
}
