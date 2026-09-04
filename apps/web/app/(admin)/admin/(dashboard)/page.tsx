import { Suspense } from "react";
import { UserGrowthChart } from "@/components/admin/UserGrowthChart";
import { RoleDistribution } from "@/components/admin/RoleDistribution";
import { RecentUsersTable } from "@/components/admin/RecentUsersTable";
import {
  getUserGrowthAnalyticsAction,
  getRoleDistributionAction,
} from "@/actions/analytics";
import { getUsersAction } from "@/actions/users";

export const dynamic = "force-dynamic";

export default async function AdminDashboardPage() {
  const [analyticsResult, roleResult, usersResult] = await Promise.allSettled([
    getUserGrowthAnalyticsAction("30d", "daily"),
    getRoleDistributionAction(),
    getUsersAction({ page: 1, pageSize: 5 }),
  ]);

  const initialAnalytics =
    analyticsResult.status === "fulfilled" ? analyticsResult.value : undefined;
  const roleData =
    roleResult.status === "fulfilled" ? roleResult.value : undefined;
  const recentUsers =
    usersResult.status === "fulfilled" ? usersResult.value.items : [];

  return (
    <div className="w-full max-w-7xl mx-auto space-y-8">
      <div>
        <h1 className="text-3xl font-bold tracking-tight text-slate-900 font-outfit">
          Overview
        </h1>
        <p className="text-slate-500 mt-1 text-sm">
          Key metrics, user growth analytics, and platform scale across Happy
          Paws.
        </p>
      </div>

      <Suspense
        fallback={
          <div className="w-full h-[500px] bg-white border border-slate-200/80 rounded-2xl p-6 shadow-xs animate-pulse space-y-6">
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
              {[...Array(4)].map((_, i) => (
                <div key={i} className="h-28 bg-slate-100 rounded-2xl" />
              ))}
            </div>
            <div className="h-80 bg-slate-100 rounded-2xl" />
          </div>
        }
      >
        <UserGrowthChart initialData={initialAnalytics} />
      </Suspense>

      <RoleDistribution data={roleData} />

      <RecentUsersTable users={recentUsers} />
    </div>
  );
}
