"use client";

import { useTransition } from "react";
import { approvePostAction, rejectPostAction } from "@/actions/community";

export function ApprovalButtons({ postId }: { postId: string }) {
  const [isPending, startTransition] = useTransition();

  const handleReject = () => {
    startTransition(async () => {
      await rejectPostAction(postId);
    });
  };

  const handleApprove = () => {
    startTransition(async () => {
      await approvePostAction(postId);
    });
  };

  return (
    <div className="flex gap-2 justify-end">
      <button
        type="button"
        onClick={handleReject}
        disabled={isPending}
        className="px-3 py-1 text-sm font-medium text-red-700 bg-red-50 hover:bg-red-100 rounded-md disabled:opacity-50"
      >
        Reject
      </button>
      <button
        type="button"
        onClick={handleApprove}
        disabled={isPending}
        className="px-3 py-1 text-sm font-medium text-emerald-700 bg-emerald-50 hover:bg-emerald-100 rounded-md disabled:opacity-50"
      >
        Approve
      </button>
    </div>
  );
}
