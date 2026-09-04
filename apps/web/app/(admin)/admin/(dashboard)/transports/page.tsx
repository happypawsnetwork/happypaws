import { Suspense } from "react";
import Link from "next/link";
import { getTransportsAction } from "@/actions/community";
import { CommunityNav } from "@/components/admin/CommunityNav";

interface TransportTask {
  id: string;
  parentPostTitle: string;
  requesterDisplayName: string;
  transporterDisplayName?: string;
  pickupAddress: string;
  dropoffAddress: string;
  pickupWindowStart?: string;
  pickupWindowEnd?: string;
  status: string;
  createdAt: string;
}

const statusColors: Record<string, string> = {
  Open: "bg-slate-100 text-slate-700",
  Accepted: "bg-blue-100 text-blue-700",
  PickedUp: "bg-amber-100 text-amber-700",
  InTransit: "bg-orange-100 text-orange-700",
  Delivered: "bg-purple-100 text-purple-700",
  Completed: "bg-green-100 text-green-700",
  Cancelled: "bg-rose-100 text-rose-700",
};

interface TransportsPageProps {
  searchParams: Promise<{ [key: string]: string | string[] | undefined }>;
}

export default async function TransportsPage({
  searchParams,
}: TransportsPageProps) {
  const resolvedParams = await searchParams;
  const status = resolvedParams?.status;
  const filterStatus = typeof status === "string" ? status : "All";

  return (
    <div className="w-full max-w-7xl mx-auto h-full flex flex-col">
      <header className="mb-6 shrink-0">
        <h1 className="text-3xl font-bold tracking-tight text-slate-900 font-outfit">
          Transport tasks
        </h1>
        <p className="mt-1 text-sm text-slate-500">
          Monitor animal transport requests and track delivery stages across
          volunteers.
        </p>
      </header>

      {/* Navigation tabs */}
      <CommunityNav />

      <div className="mb-6 flex gap-2 overflow-x-auto pb-2">
        {[
          "All",
          "Open",
          "Accepted",
          "In Progress",
          "Completed",
          "Cancelled",
        ].map((s) => {
          const isActive = filterStatus === s;
          return (
            <Link
              key={s}
              href={`/admin/transports?status=${s}`}
              className={`rounded-full border px-4 py-1.5 text-xs font-medium transition ${
                isActive
                  ? "bg-slate-900 border-slate-900 text-white"
                  : "bg-white border-slate-200 text-slate-600 hover:bg-slate-50"
              }`}
            >
              {s}
            </Link>
          );
        })}
      </div>

      <div className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-xs">
        <Suspense
          fallback={
            <div className="p-12 text-center text-sm text-slate-500">
              Loading transports...
            </div>
          }
        >
          <TransportsTable status={filterStatus} />
        </Suspense>
      </div>
    </div>
  );
}

async function TransportsTable({ status }: { status: string }) {
  const { items } = await getTransportsAction({ status });
  const tasks: TransportTask[] = items || [];

  if (tasks.length === 0) {
    return (
      <div className="p-12 text-center">
        <p className="text-sm font-medium text-slate-900">
          No transport tasks found.
        </p>
        <p className="mt-1 text-sm text-slate-500">
          No tasks match the &quot;{status}&quot; filter.
        </p>
      </div>
    );
  }

  return (
    <div className="overflow-x-auto">
      <table className="min-w-full divide-y divide-slate-200 text-left text-sm">
        <thead className="bg-slate-50 text-slate-600">
          <tr>
            <th
              scope="col"
              className="px-5 py-3.5 text-xs font-semibold uppercase tracking-wider"
            >
              Task ID
            </th>
            <th
              scope="col"
              className="px-5 py-3.5 text-xs font-semibold uppercase tracking-wider"
            >
              Parent case
            </th>
            <th
              scope="col"
              className="px-5 py-3.5 text-xs font-semibold uppercase tracking-wider"
            >
              Requester
            </th>
            <th
              scope="col"
              className="px-5 py-3.5 text-xs font-semibold uppercase tracking-wider"
            >
              Transporter
            </th>
            <th
              scope="col"
              className="px-5 py-3.5 text-xs font-semibold uppercase tracking-wider"
            >
              Pickup and dropoff
            </th>
            <th
              scope="col"
              className="px-5 py-3.5 text-xs font-semibold uppercase tracking-wider"
            >
              Window
            </th>
            <th
              scope="col"
              className="px-5 py-3.5 text-xs font-semibold uppercase tracking-wider"
            >
              Status
            </th>
            <th
              scope="col"
              className="px-5 py-3.5 text-xs font-semibold uppercase tracking-wider"
            >
              Created at
            </th>
          </tr>
        </thead>
        <tbody className="divide-y divide-slate-200 bg-white">
          {tasks.map((task) => (
            <tr key={task.id} className="transition hover:bg-slate-50/75">
              <td className="whitespace-nowrap px-5 py-4 font-mono text-xs text-slate-900">
                {task.id.slice(0, 8)}
              </td>
              <td className="px-5 py-4 text-sm font-medium text-slate-900 max-w-xs truncate">
                {task.parentPostTitle}
              </td>
              <td className="whitespace-nowrap px-5 py-4 text-sm text-slate-600">
                {task.requesterDisplayName}
              </td>
              <td className="whitespace-nowrap px-5 py-4 text-sm text-slate-600">
                {task.transporterDisplayName || (
                  <span className="italic text-slate-400">Unassigned</span>
                )}
              </td>
              <td className="max-w-xs px-5 py-4 text-xs text-slate-500">
                <div className="truncate font-medium text-slate-900">
                  From: {task.pickupAddress}
                </div>
                <div className="mt-0.5 truncate text-slate-500">
                  To: {task.dropoffAddress}
                </div>
              </td>
              <td className="whitespace-nowrap px-5 py-4 text-xs text-slate-500">
                {task.pickupWindowStart
                  ? new Date(task.pickupWindowStart).toLocaleDateString()
                  : "N/A"}
              </td>
              <td className="whitespace-nowrap px-5 py-4">
                <span
                  className={`inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium ${
                    statusColors[task.status] || "bg-slate-100 text-slate-800"
                  }`}
                >
                  {task.status}
                </span>
              </td>
              <td className="whitespace-nowrap px-5 py-4 text-xs text-slate-500">
                {new Date(task.createdAt).toLocaleDateString()}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
