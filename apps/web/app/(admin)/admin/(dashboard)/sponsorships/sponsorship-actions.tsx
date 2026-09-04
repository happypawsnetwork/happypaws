"use client";

import { useState, useTransition } from "react";
import {
  reviewSponsorshipAction,
  getSponsorshipDocsAction,
} from "@/actions/community";
import { z } from "zod";

export function SponsorshipActions({
  id,
  status,
}: {
  id: string;
  status: string;
}) {
  const [isPending, startTransition] = useTransition();
  const [isRejectModalOpen, setIsRejectModalOpen] = useState(false);
  const [rejectNotes, setRejectNotes] = useState("");
  const [error, setError] = useState("");

  if (status !== "PendingApproval") {
    return <span className="text-slate-400">-</span>;
  }

  const handleApprove = () => {
    startTransition(async () => {
      await reviewSponsorshipAction(id, true);
    });
  };

  const handleReject = () => {
    const parsed = z
      .string()
      .min(10, "Rejection notes must be at least 10 characters.")
      .safeParse(rejectNotes);
    if (!parsed.success) {
      setError(parsed.error.issues[0].message);
      return;
    }

    startTransition(async () => {
      await reviewSponsorshipAction(id, false, parsed.data);
      setIsRejectModalOpen(false);
    });
  };

  return (
    <>
      <div className="flex gap-2">
        <button
          onClick={handleApprove}
          disabled={isPending}
          className="rounded bg-emerald-50 px-2 py-1 text-xs font-medium text-emerald-700 hover:bg-emerald-100 disabled:opacity-50"
        >
          Approve
        </button>
        <button
          onClick={() => setIsRejectModalOpen(true)}
          disabled={isPending}
          className="rounded bg-rose-50 px-2 py-1 text-xs font-medium text-rose-700 hover:bg-rose-100 disabled:opacity-50"
        >
          Reject
        </button>
      </div>

      {isRejectModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-950/70 backdrop-blur-md p-4">
          <div className="w-full max-w-md rounded-2xl bg-white p-6 shadow-xl">
            <h3 className="text-lg font-semibold text-slate-900">
              Reject sponsorship
            </h3>
            <div className="mt-4">
              <label
                htmlFor={`reject-notes-${id}`}
                className="block text-sm font-medium text-slate-700"
              >
                Rejection notes
              </label>
              <textarea
                id={`reject-notes-${id}`}
                value={rejectNotes}
                onChange={(e) => {
                  setRejectNotes(e.target.value);
                  setError("");
                }}
                className="mt-1.5 block w-full rounded-xl border border-slate-300 p-2.5 text-slate-900 focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
                rows={4}
                placeholder="Reason for rejection..."
              />
              {error && <p className="mt-1 text-xs text-rose-600">{error}</p>}
            </div>
            <div className="mt-6 flex justify-end gap-3">
              <button
                onClick={() => setIsRejectModalOpen(false)}
                className="rounded-xl px-4 py-2 text-sm font-medium text-slate-600 hover:bg-slate-100"
              >
                Cancel
              </button>
              <button
                onClick={handleReject}
                disabled={isPending}
                className="rounded-xl bg-rose-600 px-4 py-2 text-sm font-medium text-white hover:bg-rose-500 disabled:opacity-50"
              >
                {isPending ? "Rejecting..." : "Confirm reject"}
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  );
}

export function ViewDocsButton({ id }: { id: string }) {
  const [isOpen, setIsOpen] = useState(false);
  const [docs, setDocs] = useState<{ url: string; fileName?: string }[]>([]);
  const [isLoading, setIsLoading] = useState(false);

  const handleOpen = async () => {
    setIsOpen(true);
    setIsLoading(true);
    try {
      const data = await getSponsorshipDocsAction(id);
      if (Array.isArray(data?.items)) {
        setDocs(
          data.items.map((item: string | { url: string; fileName?: string }) =>
            typeof item === "string"
              ? { url: item, fileName: item.split("/").pop() || "Document" }
              : item,
          ),
        );
      }
    } catch (e) {
      console.error(e);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <>
      <button
        onClick={handleOpen}
        className="ml-2 rounded text-xs font-medium text-blue-600 hover:text-blue-800 hover:underline"
      >
        View docs
      </button>

      {isOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-950/70 backdrop-blur-md p-4">
          <div className="w-full max-w-lg rounded-2xl bg-white p-6 shadow-xl">
            <h3 className="mb-4 text-lg font-semibold text-slate-900">
              Proof documents
            </h3>
            {isLoading ? (
              <p className="text-sm text-slate-500">Loading documents...</p>
            ) : docs.length > 0 ? (
              <ul className="space-y-3">
                {docs.map((doc, idx) => (
                  <li key={idx}>
                    <a
                      href={doc.url}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="text-sm text-blue-600 hover:underline"
                    >
                      {doc.fileName || doc.url || `Document ${idx + 1}`}
                    </a>
                  </li>
                ))}
              </ul>
            ) : (
              <p className="text-sm text-slate-500">No documents found.</p>
            )}
            <div className="mt-6 flex justify-end">
              <button
                onClick={() => setIsOpen(false)}
                className="rounded-xl bg-slate-100 px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-200"
              >
                Close
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  );
}
