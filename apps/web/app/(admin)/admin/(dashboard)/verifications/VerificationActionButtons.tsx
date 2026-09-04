"use client";

import { useState } from "react";
import {
  approveVerificationAction,
  rejectVerificationAction,
} from "@/actions/verifications";
import { ConfirmModal } from "@/components/admin/ConfirmModal";
import { useRouter } from "next/navigation";

export function VerificationActionButtons({
  id,
  status,
}: {
  id: number;
  status: string;
}) {
  const [isApproving, setIsApproving] = useState(false);
  const [isRejecting, setIsRejecting] = useState(false);
  const [isRejectConfirmOpen, setIsRejectConfirmOpen] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const router = useRouter();

  if (status !== "Pending") {
    return null;
  }

  const handleApprove = async () => {
    try {
      setIsApproving(true);
      setError(null);
      await approveVerificationAction(id);
      router.refresh();
    } catch (err) {
      console.error(err);
      setError("Failed to approve verification.");
    } finally {
      setIsApproving(false);
    }
  };

  const handleConfirmReject = async () => {
    try {
      setIsRejecting(true);
      setError(null);
      await rejectVerificationAction(id);
      setIsRejectConfirmOpen(false);
      router.refresh();
    } catch (err) {
      console.error(err);
      setError("Failed to reject verification.");
    } finally {
      setIsRejecting(false);
    }
  };

  return (
    <>
      <div className="flex items-center justify-end gap-2">
        <button
          type="button"
          onClick={() => {
            setError(null);
            setIsRejectConfirmOpen(true);
          }}
          disabled={isApproving || isRejecting}
          className="px-3 py-1.5 text-xs font-semibold rounded-lg text-rose-600 bg-rose-50 hover:bg-rose-100 disabled:opacity-50 transition-colors cursor-pointer"
        >
          {isRejecting ? "Wait..." : "Reject"}
        </button>
        <button
          type="button"
          onClick={handleApprove}
          disabled={isApproving || isRejecting}
          className="px-3 py-1.5 text-xs font-semibold rounded-lg text-white bg-blue-600 hover:bg-blue-700 disabled:opacity-50 transition-colors cursor-pointer"
        >
          {isApproving ? "Wait..." : "Approve"}
        </button>
      </div>

      <ConfirmModal
        isOpen={isRejectConfirmOpen}
        title="Reject verification request"
        description="Are you sure you want to reject this volunteer verification request? The user will be notified that their verification was denied."
        confirmLabel="Reject verification"
        variant="danger"
        isPending={isRejecting}
        error={error}
        onConfirm={handleConfirmReject}
        onClose={() => {
          if (!isRejecting) {
            setIsRejectConfirmOpen(false);
            setError(null);
          }
        }}
      />
    </>
  );
}
