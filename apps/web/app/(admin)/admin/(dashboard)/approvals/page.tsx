import { getCommunityPostsAction } from "@/actions/community";
import { NoContentPlaceholder } from "@/components/admin/NoContentPlaceholder";
import { ApprovalButtons } from "./ApprovalButtons";
import { RescueUrgencyCell } from "../rescues/RescueUrgencyCell";

export default async function ApprovalsPage() {
  const postsResponse = await getCommunityPostsAction({
    status: "PendingApproval",
  });

  const posts = postsResponse.items || [];

  return (
    <div className="w-full max-w-6xl mx-auto h-full flex flex-col">
      <div className="mb-8 shrink-0">
        <h1 className="text-3xl font-bold tracking-tight text-slate-900 font-outfit">
          Pending Approvals
        </h1>
        <p className="text-slate-500 mt-1 text-sm">
          Review community submissions before they become publicly active.
        </p>
      </div>

      {posts.length === 0 ? (
        <NoContentPlaceholder
          title="No pending posts"
          description="You're all caught up! There are no community submissions awaiting approval."
        />
      ) : (
        <div className="overflow-x-auto rounded-xl border border-slate-200 bg-white">
          <table className="min-w-full divide-y divide-slate-200 text-left text-sm">
            <thead className="bg-slate-50 text-slate-600">
              <tr>
                <th scope="col" className="px-6 py-3 font-semibold">
                  Type
                </th>
                <th scope="col" className="px-6 py-3 font-semibold">
                  Urgency
                </th>
                <th scope="col" className="px-6 py-3 font-semibold">
                  Title
                </th>
                <th scope="col" className="px-6 py-3 font-semibold">
                  Author
                </th>
                <th scope="col" className="px-6 py-3 font-semibold">
                  Date Submitted
                </th>
                <th scope="col" className="px-6 py-3 font-semibold text-right">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-200 text-slate-900">
              {posts.map((post: any) => {
                return (
                  <tr
                    key={post.id}
                    className="hover:bg-slate-50 transition-colors"
                  >
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span className="inline-flex items-center rounded-md bg-blue-50 px-2 py-1 text-xs font-medium text-blue-700 ring-1 ring-inset ring-blue-700/10">
                        {post.type}
                      </span>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      {post.type === "RescueAlert" ? (
                        <RescueUrgencyCell post={post} />
                      ) : (
                        <span className="text-slate-400">-</span>
                      )}
                    </td>
                    <td className="px-6 py-4 font-medium">{post.title}</td>
                    <td className="px-6 py-4 whitespace-nowrap text-slate-600">
                      {post.authorDisplayName}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-slate-500">
                      {new Date(post.createdAt).toLocaleDateString()}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-right">
                      <ApprovalButtons postId={post.id} />
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
