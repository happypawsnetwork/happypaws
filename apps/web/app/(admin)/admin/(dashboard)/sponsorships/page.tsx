import { Suspense } from "react";
import { getSponsorshipsAction } from "@/actions/community";
import { CommunityNav } from "@/components/admin/CommunityNav";
import { SponsorshipTabs } from "./sponsorship-tabs";
import { SponsorshipActions, ViewDocsButton } from "./sponsorship-actions";

export const dynamic = "force-dynamic";

export default async function AdminSponsorshipsPage(props: {
  searchParams?: Promise<{ [key: string]: string | string[] | undefined }>;
}) {
  const searchParams = await props.searchParams;
  const status =
    typeof searchParams?.status === "string"
      ? searchParams.status
      : "PendingApproval";

  const data = await getSponsorshipsAction({ status });
  const sponsorships = data?.items || [];

  return (
    <div className="w-full max-w-7xl mx-auto h-full flex flex-col">
      <header className="mb-6 shrink-0">
        <h1 className="text-3xl font-bold tracking-tight text-slate-900 font-outfit">
          Sponsorship requests
        </h1>
        <p className="mt-1 text-sm text-slate-500">
          Review community sponsorship funding requests, verify proof documents,
          and manage approval status.
        </p>
      </header>

      {/* Navigation tabs */}
      <CommunityNav />

      <SponsorshipTabs currentStatus={status} />

      <div className="mt-6 overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-xs">
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-slate-200 text-left text-sm">
            <thead className="bg-slate-50 text-slate-600">
              <tr>
                <th
                  scope="col"
                  className="px-5 py-3.5 text-xs font-semibold uppercase tracking-wider"
                >
                  Title
                </th>
                <th
                  scope="col"
                  className="px-5 py-3.5 text-xs font-semibold uppercase tracking-wider"
                >
                  Author
                </th>
                <th
                  scope="col"
                  className="px-5 py-3.5 text-xs font-semibold uppercase tracking-wider"
                >
                  Goal
                </th>
                <th
                  scope="col"
                  className="px-5 py-3.5 text-xs font-semibold uppercase tracking-wider"
                >
                  Amount (LKR)
                </th>
                <th
                  scope="col"
                  className="px-5 py-3.5 text-xs font-semibold uppercase tracking-wider"
                >
                  Media
                </th>
                <th
                  scope="col"
                  className="px-5 py-3.5 text-xs font-semibold uppercase tracking-wider"
                >
                  Submitted
                </th>
                <th
                  scope="col"
                  className="px-5 py-3.5 text-xs font-semibold uppercase tracking-wider text-right"
                >
                  Actions
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-200 bg-white">
              {sponsorships.length === 0 ? (
                <tr>
                  <td
                    colSpan={7}
                    className="px-6 py-12 text-center text-sm text-slate-500"
                  >
                    No sponsorship requests found for status &quot;{status}
                    &quot;.
                  </td>
                </tr>
              ) : (
                sponsorships.map((sponsorship: any) => {
                  const goalDescription =
                    sponsorship.sponsorshipDetails?.goalDescription ||
                    sponsorship.goalDescription ||
                    sponsorship.body;
                  const estimatedAmount =
                    sponsorship.sponsorshipDetails?.estimatedAmountLkr ||
                    sponsorship.estimatedAmount;
                  const photoCount =
                    sponsorship.photoCount || sponsorship.media?.length || 0;
                  const proofDocsCount =
                    sponsorship.sponsorshipDetails?.proofDocumentsCount ||
                    sponsorship.proofDocumentsCount ||
                    0;
                  const authorName =
                    sponsorship.authorDisplayName ||
                    sponsorship.authorName ||
                    sponsorship.author?.name ||
                    "Unknown";

                  return (
                    <tr
                      key={sponsorship.id}
                      className="hover:bg-slate-50/75 transition-colors"
                    >
                      <td className="whitespace-nowrap px-5 py-4 text-sm font-medium text-slate-900 max-w-xs truncate">
                        {sponsorship.title}
                      </td>
                      <td className="whitespace-nowrap px-5 py-4 text-sm text-slate-600">
                        {authorName}
                      </td>
                      <td
                        className="max-w-xs px-5 py-4 text-xs text-slate-500"
                        title={goalDescription}
                      >
                        {goalDescription?.length > 80
                          ? `${goalDescription.substring(0, 80)}...`
                          : goalDescription}
                      </td>
                      <td className="whitespace-nowrap px-5 py-4 text-sm font-medium text-slate-900">
                        {estimatedAmount
                          ? estimatedAmount.toLocaleString()
                          : "N/A"}
                      </td>
                      <td className="whitespace-nowrap px-5 py-4 text-xs text-slate-500">
                        <div>Photos: {photoCount}</div>
                        <div>
                          Docs: {proofDocsCount}
                          {proofDocsCount > 0 && (
                            <ViewDocsButton id={sponsorship.id} />
                          )}
                        </div>
                      </td>
                      <td className="whitespace-nowrap px-5 py-4 text-xs text-slate-500">
                        {new Date(
                          sponsorship.submittedAt ||
                            sponsorship.createdAt ||
                            new Date(),
                        ).toLocaleDateString()}
                      </td>
                      <td className="whitespace-nowrap px-5 py-4 text-sm text-right">
                        <SponsorshipActions
                          id={sponsorship.id}
                          status={status}
                        />
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
