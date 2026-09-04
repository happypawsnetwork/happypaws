import Link from "next/link";
import { CommunityNav } from "@/components/admin/CommunityNav";
import { NoContentPlaceholder } from "@/components/admin/NoContentPlaceholder";
import {
  getCommunityPostsAction,
  type AdminCommunityPost,
} from "@/actions/community";
import { CommunityTable } from "./CommunityTable";
import { Search } from "lucide-react";

interface PageProps {
  searchParams: Promise<{
    type?: string;
    status?: string;
    search?: string;
    includeDeleted?: string;
  }>;
}

const POST_TYPES = [
  "All",
  "Rescue",
  "Update",
  "Find Home",
  "Highlight",
  "Transport",
  "Treatment",
  "Sponsor",
];

const POST_STATUSES = [
  "All",
  "Active",
  "Fostered",
  "Assigned",
  "Completed",
  "PendingApproval",
  "Funded",
  "Rejected",
  "Cancelled",
];

export default async function CommunityPage({ searchParams }: PageProps) {
  const params = await searchParams;
  const currentType =
    params.type && POST_TYPES.includes(params.type) ? params.type : "All";
  const currentStatus =
    params.status && POST_STATUSES.includes(params.status)
      ? params.status
      : "All";
  const currentSearch = params.search || "";
  const includeDeleted = params.includeDeleted === "true";

  const postsResponse = await getCommunityPostsAction({
    type: currentType,
    status: currentStatus,
    search: currentSearch,
    includeDeleted,
  });

  const posts: AdminCommunityPost[] = postsResponse.items || [];

  return (
    <div className="w-full max-w-7xl mx-auto h-full flex flex-col">
      <header className="mb-6 shrink-0">
        <h1 className="text-3xl font-bold tracking-tight text-slate-900 font-outfit">
          Community management
        </h1>
        <p className="text-slate-500 mt-1 text-sm">
          Moderate community posts across all post types, inspect attached
          media, and review cases.
        </p>
      </header>

      {/* Navigation tabs */}
      <CommunityNav />

      {/* Filters and search toolbar */}
      <div className="mb-6 space-y-4 rounded-2xl border border-slate-200 bg-white p-5 shadow-xs">
        <div className="flex flex-col md:flex-row gap-4 justify-between items-start md:items-center">
          {/* Search form */}
          <form className="relative w-full md:w-80">
            {currentType !== "All" && (
              <input type="hidden" name="type" value={currentType} />
            )}
            {currentStatus !== "All" && (
              <input type="hidden" name="status" value={currentStatus} />
            )}
            {includeDeleted && (
              <input type="hidden" name="includeDeleted" value="true" />
            )}
            <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
            <input
              type="text"
              name="search"
              defaultValue={currentSearch}
              placeholder="Search posts or authors..."
              className="w-full pl-10 pr-4 py-2 text-sm rounded-xl border border-slate-200 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent text-slate-900 placeholder:text-slate-400"
            />
          </form>

          {/* Deleted items toggle */}
          <div className="flex items-center gap-2">
            {(() => {
              const toggleParams = new URLSearchParams();
              if (currentType !== "All") toggleParams.set("type", currentType);
              if (currentStatus !== "All")
                toggleParams.set("status", currentStatus);
              if (currentSearch) toggleParams.set("search", currentSearch);
              if (!includeDeleted) toggleParams.set("includeDeleted", "true");
              const query = toggleParams.toString();

              return (
                <Link
                  href={query ? `?${query}` : "/admin/community"}
                  className={`text-xs px-3 py-1.5 rounded-lg border font-medium transition-colors ${
                    includeDeleted
                      ? "bg-rose-50 border-rose-200 text-rose-700"
                      : "bg-slate-50 border-slate-200 text-slate-600 hover:bg-slate-100"
                  }`}
                >
                  {includeDeleted
                    ? "Showing deleted posts"
                    : "Show deleted posts"}
                </Link>
              );
            })()}
          </div>
        </div>

        {/* Type filter chips */}
        <div className="flex flex-wrap items-center gap-1.5 pt-2 border-t border-slate-100">
          <span className="text-xs font-semibold text-slate-500 mr-2">
            Type:
          </span>
          {POST_TYPES.map((t) => {
            const queryParams = new URLSearchParams();
            if (t !== "All") queryParams.set("type", t);
            if (currentStatus !== "All")
              queryParams.set("status", currentStatus);
            if (currentSearch) queryParams.set("search", currentSearch);
            if (includeDeleted) queryParams.set("includeDeleted", "true");
            const query = queryParams.toString();

            return (
              <Link
                key={t}
                href={query ? `?${query}` : "/admin/community"}
                className={`px-3 py-1 text-xs rounded-full font-medium transition-colors ${
                  currentType === t
                    ? "bg-slate-900 text-white"
                    : "bg-slate-100 text-slate-700 hover:bg-slate-200"
                }`}
              >
                {t}
              </Link>
            );
          })}
        </div>

        {/* Status filter chips */}
        <div className="flex flex-wrap items-center gap-1.5">
          <span className="text-xs font-semibold text-slate-500 mr-2">
            Status:
          </span>
          {POST_STATUSES.map((s) => {
            const queryParams = new URLSearchParams();
            if (currentType !== "All") queryParams.set("type", currentType);
            if (s !== "All") queryParams.set("status", s);
            if (currentSearch) queryParams.set("search", currentSearch);
            if (includeDeleted) queryParams.set("includeDeleted", "true");
            const query = queryParams.toString();

            return (
              <Link
                key={s}
                href={query ? `?${query}` : "/admin/community"}
                className={`px-3 py-1 text-xs rounded-full font-medium transition-colors ${
                  currentStatus === s
                    ? "bg-slate-900 text-white"
                    : "bg-slate-100 text-slate-700 hover:bg-slate-200"
                }`}
              >
                {s}
              </Link>
            );
          })}
        </div>
      </div>

      {/* Post Table */}
      {posts.length === 0 ? (
        <NoContentPlaceholder
          title="No community posts found"
          description="There are currently no community posts matching the selected filters."
        />
      ) : (
        <CommunityTable posts={posts} />
      )}
    </div>
  );
}
