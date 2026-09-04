import { NoContentPlaceholder } from "@/components/admin/NoContentPlaceholder";
import {
  getVerificationsAction,
  type AdminVerification,
  type AdminVerificationDocument,
} from "@/actions/verifications";
import { VerificationActionButtons } from "./VerificationActionButtons";
import Link from "next/link";

interface PageProps {
  searchParams: Promise<{ role?: string; status?: string }>;
}

const ROLES = [
  "All",
  "Adopter",
  "Foster",
  "Transporter",
  "Veterinarian",
  "Sponsor",
];
const STATUSES = ["All", "Pending", "Approved", "Rejected"];

export default async function VerificationsPage({ searchParams }: PageProps) {
  const { role, status } = await searchParams;

  const currentRole = role && ROLES.includes(role) ? role : "All";
  const currentStatus = status && STATUSES.includes(status) ? status : "All";

  const response = await getVerificationsAction({
    role: currentRole,
    status: currentStatus,
  });

  const verifications = response.items || [];

  return (
    <div className="w-full max-w-6xl mx-auto h-full flex flex-col">
      <div className="mb-8 shrink-0">
        <h1 className="text-3xl font-bold tracking-tight text-slate-900 font-outfit">
          Verifications
        </h1>
        <p className="text-slate-500 mt-1 text-sm">
          Review and approve new shelters, volunteers, and foster applications.
        </p>
      </div>

      <div className="mb-6 flex flex-wrap gap-4 items-center justify-between">
        <div className="flex flex-wrap items-center gap-2">
          <span className="text-sm font-medium text-slate-700">Role:</span>
          {ROLES.map((r) => {
            const params = new URLSearchParams();
            if (r !== "All") params.set("role", r);
            if (currentStatus !== "All") params.set("status", currentStatus);
            const query = params.toString();
            return (
              <Link
                key={r}
                href={`?${query}`}
                className={`px-3 py-1 text-sm rounded-full transition-colors ${
                  currentRole === r
                    ? "bg-slate-900 text-white"
                    : "bg-slate-100 text-slate-700 hover:bg-slate-200"
                }`}
              >
                {r}
              </Link>
            );
          })}
        </div>

        <div className="flex flex-wrap items-center gap-2">
          <span className="text-sm font-medium text-slate-700">Status:</span>
          {STATUSES.map((s) => {
            const params = new URLSearchParams();
            if (currentRole !== "All") params.set("role", currentRole);
            if (s !== "All") params.set("status", s);
            const query = params.toString();
            return (
              <Link
                key={s}
                href={`?${query}`}
                className={`px-3 py-1 text-sm rounded-full transition-colors ${
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

      {verifications.length === 0 ? (
        <NoContentPlaceholder
          title="No requests found"
          description="There are currently no verification requests matching your filters."
        />
      ) : (
        <div className="overflow-x-auto rounded-xl border border-slate-200 bg-white">
          <table className="min-w-full divide-y divide-slate-200 text-left text-sm">
            <thead className="bg-slate-50 text-slate-600">
              <tr>
                <th scope="col" className="px-6 py-3 font-semibold">
                  User
                </th>
                <th scope="col" className="px-6 py-3 font-semibold">
                  Requested Role
                </th>
                <th scope="col" className="px-6 py-3 font-semibold">
                  Documents
                </th>
                <th scope="col" className="px-6 py-3 font-semibold">
                  Status
                </th>
                <th scope="col" className="px-6 py-3 font-semibold text-right">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-200 text-slate-900">
              {verifications.map((v: AdminVerification) => (
                <tr key={v.id} className="hover:bg-slate-50/50">
                  <td className="px-6 py-4 font-medium">
                    <Link
                      href={`/admin/users/${v.userId}`}
                      target="_blank"
                      className="text-blue-600 hover:underline"
                    >
                      {v.userName}
                    </Link>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <span className="inline-flex items-center rounded-full bg-indigo-50 px-2.5 py-0.5 text-xs font-medium text-indigo-700 ring-1 ring-inset ring-indigo-700/10">
                      {v.requestedRole}
                    </span>
                  </td>
                  <td className="px-6 py-4">
                    <div className="flex flex-wrap gap-2">
                      {v.documents.map(
                        (doc: AdminVerificationDocument, i: number) => (
                          <a
                            key={i}
                            href={doc.presignedUrl}
                            target="_blank"
                            rel="noreferrer"
                            className="inline-flex items-center gap-1 rounded bg-slate-100 px-2 py-1 text-xs font-medium text-slate-700 hover:bg-slate-200"
                          >
                            <svg
                              className="w-3 h-3"
                              fill="none"
                              stroke="currentColor"
                              viewBox="0 0 24 24"
                            >
                              <path
                                strokeLinecap="round"
                                strokeLinejoin="round"
                                strokeWidth="2"
                                d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14"
                              ></path>
                            </svg>
                            {doc.documentType}
                          </a>
                        ),
                      )}
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <span
                      className={`inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium ring-1 ring-inset ${
                        v.status === "Approved"
                          ? "bg-green-50 text-green-700 ring-green-600/20"
                          : v.status === "Rejected"
                            ? "bg-red-50 text-red-700 ring-red-600/10"
                            : "bg-amber-50 text-amber-700 ring-amber-600/20"
                      }`}
                    >
                      {v.status}
                    </span>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-right">
                    <VerificationActionButtons id={v.id} status={v.status} />
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
