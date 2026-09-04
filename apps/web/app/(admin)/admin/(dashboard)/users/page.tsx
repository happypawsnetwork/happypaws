import { Suspense } from "react";
import { UsersDirectory } from "@/components/admin/users/UsersDirectory";
import { getUsersAction, type AdminUsersListResponse } from "@/actions/users";

export const dynamic = "force-dynamic";

function UsersLoadingSkeleton() {
  return (
    <div className="w-full max-w-7xl mx-auto space-y-8 animate-pulse">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div className="space-y-2">
          <div className="h-8 w-48 bg-slate-200 rounded-xl" />
          <div className="h-4 w-80 bg-slate-100 rounded-lg" />
        </div>
        <div className="h-10 w-32 bg-slate-200 rounded-xl" />
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {[...Array(4)].map((_, i) => (
          <div
            key={i}
            className="h-28 bg-white border border-slate-200/80 rounded-2xl p-5 shadow-xs"
          />
        ))}
      </div>

      <div className="h-96 bg-white border border-slate-200/80 rounded-2xl p-6 shadow-xs" />
    </div>
  );
}

export default async function UsersPage() {
  let initialData: AdminUsersListResponse | undefined;

  try {
    initialData = await getUsersAction({ page: 1, pageSize: 10 });
  } catch (err) {
    console.error("Failed to prefetch users on server:", err);
  }

  return (
    <Suspense fallback={<UsersLoadingSkeleton />}>
      <UsersDirectory initialData={initialData} />
    </Suspense>
  );
}
