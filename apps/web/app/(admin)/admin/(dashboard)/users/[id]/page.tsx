import { getUserByIdAction } from "@/actions/users";
import { notFound } from "next/navigation";
import Image from "next/image";
import Link from "next/link";
import { RoleBadge } from "@/components/admin/users/RoleBadge";

interface PageProps {
  params: Promise<{ id: string }>;
}

export default async function UserProfilePage({ params }: PageProps) {
  const { id } = await params;

  if (!id || isNaN(Number(id))) {
    notFound();
  }

  try {
    const user = await getUserByIdAction(Number(id));
    if (!user) {
      notFound();
    }

    return (
      <div className="w-full max-w-4xl mx-auto flex flex-col h-full">
        {/* Back navigation */}
        <div className="mb-6">
          <Link
            href="/admin/users"
            className="text-sm text-slate-500 hover:text-slate-800 flex items-center gap-1 w-fit"
          >
            <svg
              className="w-4 h-4"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth="2"
                d="M10 19l-7-7m0 0l7-7m-7 7h18"
              />
            </svg>
            Back to Users
          </Link>
        </div>

        {/* Profile Header Card */}
        <div className="bg-white rounded-xl border border-slate-200 overflow-hidden shadow-sm mb-6">
          <div className="h-32 bg-slate-100 w-full relative">
            {/* Pattern/Background */}
            <div
              className="absolute inset-0"
              style={{
                backgroundImage: "url('/pattern-pet-paws.jpg')",
                backgroundSize: "150px",
                backgroundRepeat: "repeat",
                opacity: 0.24,
              }}
            ></div>
          </div>
          <div className="px-6 pb-6 relative">
            <div className="flex flex-col sm:flex-row sm:items-end justify-between gap-4">
              <div className="flex flex-col sm:flex-row gap-4 sm:gap-6 sm:items-end -mt-12">
                <div className="w-24 h-24 rounded-full border-4 border-white bg-slate-100 flex items-center justify-center shrink-0 overflow-hidden relative z-10 shadow-sm">
                  {user.avatarUrl ? (
                    <Image
                      src={user.avatarUrl}
                      alt={user.fullName}
                      fill
                      unoptimized
                      className="object-cover"
                    />
                  ) : (
                    <span className="text-3xl font-bold text-slate-400">
                      {user.fullName.charAt(0).toUpperCase()}
                    </span>
                  )}
                </div>
                <div className="pb-1">
                  <h1 className="text-2xl font-bold text-slate-900 font-outfit flex items-center gap-2">
                    {user.fullName}
                    {user.roles.some((r) => r.isVerified) && (
                      <svg
                        className="w-6 h-6 text-blue-500"
                        viewBox="0 0 24 24"
                        fill="currentColor"
                      >
                        <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z" />
                      </svg>
                    )}
                  </h1>
                  <p className="text-slate-500">{user.email}</p>
                </div>
              </div>

              {/* Status Badges & Actions */}
              <div className="flex flex-col sm:flex-row gap-4 items-end pb-2">
                <div className="flex gap-2">
                  {user.isActive ? (
                    <span className="px-3 py-1 bg-green-50 text-green-700 text-xs font-medium rounded-full ring-1 ring-inset ring-green-600/20">
                      Active
                    </span>
                  ) : (
                    <span className="px-3 py-1 bg-red-50 text-red-700 text-xs font-medium rounded-full ring-1 ring-inset ring-red-600/10">
                      Inactive
                    </span>
                  )}
                  {user.isDeleted && (
                    <span className="px-3 py-1 bg-slate-100 text-slate-700 text-xs font-medium rounded-full ring-1 ring-inset ring-slate-500/20">
                      Deleted
                    </span>
                  )}
                </div>
                <Link
                  href={`/admin/messages?userId=${user.id}`}
                  className="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white text-sm font-medium rounded-lg shadow-sm transition-colors flex items-center gap-2"
                >
                  <svg
                    className="w-4 h-4"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth="2"
                      d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"
                    />
                  </svg>
                  Message User
                </Link>
              </div>
            </div>

            {user.tagline && (
              <div className="mt-4 pt-4 border-t border-slate-100 text-center">
                <p className="text-slate-700 italic">
                  &ldquo;{user.tagline}&rdquo;
                </p>
              </div>
            )}
          </div>
        </div>

        {/* Details Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
          {/* Roles */}
          <div className="bg-white rounded-xl border border-slate-200 p-6 shadow-sm">
            <h2 className="text-lg font-semibold text-slate-900 mb-4">
              Roles & Permissions
            </h2>
            {user.roles.length > 0 ? (
              <div className="flex flex-wrap gap-2">
                {user.roles.map((role, idx) => (
                  <RoleBadge key={idx} role={role.name} size="md" />
                ))}
              </div>
            ) : (
              <p className="text-slate-500 text-sm">No roles assigned.</p>
            )}
          </div>

          {/* Account Info */}
          <div className="bg-white rounded-xl border border-slate-200 p-6 shadow-sm">
            <h2 className="text-lg font-semibold text-slate-900 mb-4">
              Account Metrics
            </h2>
            <dl className="space-y-4">
              <div className="flex justify-between border-b border-slate-100 pb-2">
                <dt className="text-sm text-slate-500">Reputation Points</dt>
                <dd className="text-sm font-medium text-slate-900">
                  {user.reputationPoints}
                </dd>
              </div>
              <div className="flex justify-between border-b border-slate-100 pb-2">
                <dt className="text-sm text-slate-500">Active Sessions</dt>
                <dd className="text-sm font-medium text-slate-900">
                  {user.activeSessionsCount}
                </dd>
              </div>
              <div className="flex justify-between border-b border-slate-100 pb-2">
                <dt className="text-sm text-slate-500">Total Posts</dt>
                <dd className="text-sm font-medium text-slate-900">
                  {user.totalPosts ?? 0}
                </dd>
              </div>
              <div className="flex justify-between">
                <dt className="text-sm text-slate-500">Member Since</dt>
                <dd className="text-sm font-medium text-slate-900">
                  {new Date(user.createdAt).toLocaleDateString()}
                </dd>
              </div>
            </dl>
          </div>
        </div>
      </div>
    );
  } catch (error) {
    console.error(error);
    notFound();
  }
}
