"use client";

import { useState, useTransition } from "react";
import { overrideRescueAction } from "@/actions/community";
import { ConfirmModal } from "@/components/admin/ConfirmModal";

export function OverrideButton({
  postId,
  applicationId,
}: {
  postId: string;
  applicationId: string;
}) {
  const [isConfirmOpen, setIsConfirmOpen] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [isPending, startTransition] = useTransition();

  const handleOpenConfirm = () => {
    setError(null);
    setIsConfirmOpen(true);
  };

  const handleCloseConfirm = () => {
    if (!isPending) {
      setIsConfirmOpen(false);
      setError(null);
    }
  };

  const handleConfirmOverride = () => {
    setError(null);
    startTransition(async () => {
      try {
        await overrideRescueAction(postId, applicationId);
        setIsConfirmOpen(false);
      } catch (err) {
        console.error("Failed to override rescue assignment:", err);
        const message =
          err instanceof Error
            ? err.message
            : "Failed to override rescue assignment.";
        setError(message);
      }
    });
  };

  return (
    <>
      <button
        type="button"
        onClick={handleOpenConfirm}
        disabled={isPending}
        className="text-sm font-medium text-rose-600 hover:text-rose-700 transition disabled:opacity-50 cursor-pointer"
      >
        {isPending ? "Working..." : "Override"}
      </button>

      <ConfirmModal
        isOpen={isConfirmOpen}
        title="Override rescue assignment"
        description="Are you sure you want to override this rescue assignment? This will reassign the rescue case and update the assignment status immediately."
        confirmLabel="Override assignment"
        variant="warning"
        isPending={isPending}
        error={error}
        onConfirm={handleConfirmOverride}
        onClose={handleCloseConfirm}
      />
    </>
  );
}
