import React from "react";
import Link from "next/link";
import { ArrowRight, Shield, CheckCircle2, XCircle } from "lucide-react";
import type { AdminUserSummary } from "@/actions/users";

interface RecentUsersTableProps {
  users?: AdminUserSummary[];
}

export function RecentUsersTable({ users = [] }: RecentUsersTableProps) {
  return (
    <section className="bg-white border border-slate-200/80 rounded-2xl p-6 shadow-xs space-y-5">
      <div className="flex items-center justify-between border-b border-slate-100 pb-4">
        <div>
          <h2 className="text-lg font-bold text-slate-900 font-outfit">
            Recent registrations
          </h2>
          <p className="text-xs text-slate-500 mt-0.5">
            Latest accounts created in the system.
          </p>
        </div>
        <Link
          href="/admin/users"
          className="inline-flex items-center gap-1.5 text-xs font-semibold text-blue-600 hover:text-blue-700 transition-colors"
        >
          View all users
          <ArrowRight className="w-3.5 h-3.5" />
        </Link>
      </div>

      {users.length === 0 ? (
        <div className="text-center py-8 text-sm text-slate-500">
          No registered users found in the database.
        </div>
      ) : (
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm text-slate-600">
            <thead className="text-xs uppercase bg-slate-50/80 text-slate-400 font-semibold border-b border-slate-100">
              <tr>
                <th scope="col" className="px-4 py-3 rounded-l-xl">
                  User
                </th>
                <th scope="col" className="px-4 py-3">
                  Roles
                </th>
                <th scope="col" className="px-4 py-3">
                  Status
                </th>
                <th scope="col" className="px-4 py-3">
                  Reputation
                </th>
                <th scope="col" className="px-4 py-3 rounded-r-xl">
                  Joined
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {users.map((user) => {
                const fullName = `${user.firstName} ${user.lastName}`.trim();
                const initials = fullName
                  ? fullName
                      .split(" ")
                      .map((n) => n[0])
                      .join("")
                      .slice(0, 2)
                      .toUpperCase()
                  : "U";
                const formattedDate = new Date(
                  user.createdAt,
                ).toLocaleDateString("en-US", {
                  month: "short",
                  day: "numeric",
                  year: "numeric",
                });

                return (
                  <tr
                    key={user.id}
                    className="hover:bg-slate-50/50 transition-colors"
                  >
                    <td className="px-4 py-3.5 flex items-center gap-3">
                      <div className="w-9 h-9 rounded-full bg-blue-100 text-blue-700 font-semibold text-xs flex items-center justify-center overflow-hidden shrink-0 border border-blue-200/60">
                        {user.avatarUrl ? (
                          // eslint-disable-next-line @next/next/no-img-element
                          <img
                            src={user.avatarUrl}
                            alt={fullName}
                            className="w-full h-full object-cover"
                          />
                        ) : (
                          initials
                        )}
                      </div>
                      <div>
                        <div className="font-semibold text-slate-900 leading-tight flex items-center gap-1.5">
                          {fullName || "Unnamed User"}
                          {user.roles.includes("Administrator") && (
                            <Shield className="w-3.5 h-3.5 text-purple-600 inline shrink-0" />
                          )}
                        </div>
                        <div className="text-xs text-slate-400 truncate max-w-[200px]">
                          {user.email}
                        </div>
                      </div>
                    </td>
                    <td className="px-4 py-3.5">
                      <div className="flex flex-wrap gap-1">
                        {user.roles.length === 0 ? (
                          <span className="text-xs text-slate-400">None</span>
                        ) : (
                          user.roles.map((r) => (
                            <span
                              key={r}
                              className="px-2 py-0.5 rounded-md text-[11px] font-medium bg-slate-100 text-slate-700 border border-slate-200/60"
                            >
                              {r}
                            </span>
                          ))
                        )}
                      </div>
                    </td>
                    <td className="px-4 py-3.5">
                      {user.isActive && !user.isDeleted ? (
                        <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-semibold bg-emerald-50 text-emerald-700 border border-emerald-100">
                          <CheckCircle2 className="w-3 h-3" />
                          Active
                        </span>
                      ) : (
                        <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-semibold bg-rose-50 text-rose-700 border border-rose-100">
                          <XCircle className="w-3 h-3" />
                          {user.isDeleted ? "Deactivated" : "Suspended"}
                        </span>
                      )}
                    </td>
                    <td className="px-4 py-3.5 font-mono text-slate-700 font-medium">
                      {user.reputationPoints.toLocaleString()}
                    </td>
                    <td className="px-4 py-3.5 text-xs text-slate-500">
                      {formattedDate}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      )}
    </section>
  );
}
