import {
  getAdminRescuesAction,
  type AdminRescueCase,
} from "@/actions/community";
import { CommunityNav } from "@/components/admin/CommunityNav";
import { NoContentPlaceholder } from "@/components/admin/NoContentPlaceholder";
import { OverrideButton } from "./OverrideButton";
import { RescueUrgencyCell } from "./RescueUrgencyCell";

export default async function RescuesPage() {
  const postsResponse = await getAdminRescuesAction();
  const posts: AdminRescueCase[] = postsResponse.items || [];

  return (
    <div className="w-full max-w-7xl mx-auto h-full flex flex-col">
      <header className="mb-6 shrink-0">
        <h1 className="text-3xl font-bold tracking-tight text-slate-900 font-outfit">
          Rescue overrides
        </h1>
        <p className="text-slate-500 mt-1 text-sm">
          Monitor active fostered rescue cases and override assignments if
          necessary.
        </p>
      </header>

      {/* Navigation tabs */}
      <CommunityNav />

      {posts.length === 0 ? (
        <NoContentPlaceholder
          title="No active cases"
          description="There are currently no fostered rescue cases awaiting administrator oversight."
        />
      ) : (
        <div className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-xs">
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-slate-200 text-left text-sm">
              <thead className="bg-slate-50 text-slate-600">
                <tr>
                  <th
                    scope="col"
                    className="px-5 py-3.5 font-semibold text-xs uppercase tracking-wider"
                  >
                    Animal
                  </th>
                  <th
                    scope="col"
                    className="px-5 py-3.5 font-semibold text-xs uppercase tracking-wider"
                  >
                    Urgency
                  </th>
                  <th
                    scope="col"
                    className="px-5 py-3.5 font-semibold text-xs uppercase tracking-wider"
                  >
                    Rescue post
                  </th>
                  <th
                    scope="col"
                    className="px-5 py-3.5 font-semibold text-xs uppercase tracking-wider"
                  >
                    Original poster
                  </th>
                  <th
                    scope="col"
                    className="px-5 py-3.5 font-semibold text-xs uppercase tracking-wider"
                  >
                    Assigned rescuer
                  </th>
                  <th
                    scope="col"
                    className="px-5 py-3.5 font-semibold text-xs uppercase tracking-wider"
                  >
                    Role
                  </th>
                  <th
                    scope="col"
                    className="px-5 py-3.5 font-semibold text-xs uppercase tracking-wider"
                  >
                    Vehicle
                  </th>
                  <th
                    scope="col"
                    className="px-5 py-3.5 font-semibold text-xs uppercase tracking-wider"
                  >
                    Status
                  </th>
                  <th
                    scope="col"
                    className="px-5 py-3.5 font-semibold text-xs uppercase tracking-wider"
                  >
                    Date approved
                  </th>
                  <th
                    scope="col"
                    className="px-5 py-3.5 font-semibold text-xs uppercase tracking-wider text-right"
                  >
                    Actions
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-200 text-slate-900">
                {posts.map((post) => {
                  const summary = post.summary || {};
                  const applicationId = summary.applicationId || "mock-app-id";

                  return (
                    <tr
                      key={post.id}
                      className="hover:bg-slate-50/50 transition-colors"
                    >
                      <td className="px-5 py-4 whitespace-nowrap">
                        <div className="font-medium text-slate-900">
                          {summary.animalName || post.animalName || "Unknown"}
                        </div>
                        <div className="text-slate-500 text-xs">
                          {summary.animalSpecies ||
                            post.animalSpecies ||
                            "Unknown"}
                        </div>
                      </td>
                      <td className="px-5 py-4 whitespace-nowrap">
                        <RescueUrgencyCell post={post} />
                      </td>
                      <td className="px-5 py-4 font-medium text-slate-900 max-w-xs truncate">
                        {post.title}
                      </td>
                      <td className="px-5 py-4 whitespace-nowrap text-slate-600">
                        {post.authorName || "Unknown"}
                      </td>
                      <td className="px-5 py-4 whitespace-nowrap font-medium text-slate-900">
                        {summary.assignedRescuerName || "Unknown"}
                      </td>
                      <td className="px-5 py-4 whitespace-nowrap">
                        <span className="inline-flex items-center rounded-full bg-indigo-50 px-2.5 py-0.5 text-xs font-medium text-indigo-700 ring-1 ring-inset ring-indigo-700/10">
                          {summary.assignedRescuerRole || "Unknown"}
                        </span>
                      </td>
                      <td className="px-5 py-4 whitespace-nowrap text-slate-600">
                        {summary.hasVehicle ? "Yes" : "No"}
                      </td>
                      <td className="px-5 py-4 whitespace-nowrap">
                        <span className="inline-flex items-center rounded-full bg-emerald-50 px-2.5 py-0.5 text-xs font-medium text-emerald-700 ring-1 ring-inset ring-emerald-600/20">
                          {post.status}
                        </span>
                      </td>
                      <td className="px-5 py-4 whitespace-nowrap text-slate-500 text-xs">
                        {summary.dateApproved
                          ? new Date(summary.dateApproved).toLocaleDateString()
                          : "N/A"}
                      </td>
                      <td className="px-5 py-4 whitespace-nowrap text-right">
                        <OverrideButton
                          postId={post.id}
                          applicationId={applicationId}
                        />
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </div>
  );
}
