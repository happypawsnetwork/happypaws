"use client";

import {
  useState,
  useEffect,
  useSyncExternalStore,
  useTransition,
} from "react";
import { createPortal } from "react-dom";
import Image from "next/image";
import { useRouter } from "next/navigation";
import {
  X,
  MapPin,
  AlertTriangle,
  Calendar,
  User,
  PawPrint,
  Trash2,
  RotateCcw,
  CheckCircle,
  XCircle,
} from "lucide-react";
import {
  deletePostAction,
  restorePostAction,
  approvePostAction,
  rejectPostAction,
  permanentDeletePostAction,
  type AdminCommunityPost,
} from "@/actions/community";
import {
  ConfirmModal,
  type ConfirmCheckbox,
} from "@/components/admin/ConfirmModal";
import {
  getTypeBadgeColor,
  getTypeDisplayLabel,
  getStatusBadgeColor,
} from "./CommunityTable";

const emptySubscribe = () => () => {};

interface PostDetailModalProps {
  post: AdminCommunityPost;
  isOpen: boolean;
  onClose: () => void;
}

type ModerationAction =
  "delete" | "restore" | "approve" | "reject" | "permanentDelete";

export function PostDetailModal({
  post,
  isOpen,
  onClose,
}: PostDetailModalProps) {
  const router = useRouter();
  const [isPending, startTransition] = useTransition();
  const [confirmAction, setConfirmAction] = useState<ModerationAction | null>(
    null,
  );
  const [error, setError] = useState<string | null>(null);

  const mounted = useSyncExternalStore(
    emptySubscribe,
    () => true,
    () => false,
  );

  useEffect(() => {
    if (!isOpen) return;
    const handleKeyDown = (event: KeyboardEvent) => {
      if (event.key === "Escape" && !isPending && !confirmAction) {
        onClose();
      }
    };
    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [isOpen, isPending, confirmAction, onClose]);

  if (!isOpen || !mounted) return null;

  const handleOpenConfirm = (action: ModerationAction) => {
    setError(null);
    setConfirmAction(action);
  };

  const handleCloseConfirm = () => {
    if (!isPending) {
      setConfirmAction(null);
      setError(null);
    }
  };

  const handleExecuteModeration = () => {
    if (!confirmAction) return;
    setError(null);

    startTransition(async () => {
      try {
        if (confirmAction === "delete") {
          await deletePostAction(post.id);
        } else if (confirmAction === "restore") {
          await restorePostAction(post.id);
        } else if (confirmAction === "approve") {
          await approvePostAction(post.id);
        } else if (confirmAction === "reject") {
          await rejectPostAction(post.id);
        } else if (confirmAction === "permanentDelete") {
          await permanentDeletePostAction(post.id);
        }
        setConfirmAction(null);
        onClose();
        router.refresh();
      } catch (err) {
        console.error("Failed to execute moderation action:", err);
        const fallback =
          confirmAction === "delete"
            ? "Failed to delete post. Please try again."
            : confirmAction === "restore"
              ? "Failed to restore post. Please try again."
              : confirmAction === "approve"
                ? "Failed to approve post. Please try again."
                : confirmAction === "permanentDelete"
                  ? "Failed to permanently delete post. Please try again."
                  : "Failed to reject post. Please try again.";
        setError(err instanceof Error ? err.message : fallback);
      }
    });
  };

  const getConfirmModalConfig = (): {
    title: string;
    description: string;
    confirmLabel: string;
    variant: "danger" | "success" | "warning" | "primary";
    checkboxes?: ConfirmCheckbox[];
  } => {
    switch (confirmAction) {
      case "delete":
        return {
          title: "Delete post",
          description:
            "Are you sure you want to delete this post? It will be hidden from the public community feed immediately. You can restore it later.",
          confirmLabel: "Delete post",
          variant: "danger",
        };
      case "permanentDelete":
        return {
          title: "Permanently delete post",
          description:
            "This action deletes the post and all associated media from the database forever. You cannot undo this action or restore the post later.",
          confirmLabel: "Delete permanently",
          variant: "danger",
          checkboxes: [
            {
              id: "irreversible",
              label:
                "I understand this post will be removed permanently and cannot be restored.",
            },
            {
              id: "data-loss",
              label:
                "I understand that all photos, likes, and linked records for this post will be deleted.",
            },
          ],
        };
      case "restore":
        return {
          title: "Restore post",
          description:
            "Are you sure you want to restore this post? It will become active and visible in the public community feed again.",
          confirmLabel: "Restore post",
          variant: "success",
        };
      case "approve":
        return {
          title: "Approve post",
          description:
            "Are you sure you want to approve this post? It will become visible in the public community feed immediately.",
          confirmLabel: "Approve post",
          variant: "primary",
        };
      case "reject":
        return {
          title: "Reject post",
          description:
            "Are you sure you want to reject this post? It will not be published to the community feed.",
          confirmLabel: "Reject post",
          variant: "danger",
        };
      default:
        return {
          title: "",
          description: "",
          confirmLabel: "",
          variant: "danger",
        };
    }
  };

  const modalConfig = getConfirmModalConfig();

  return createPortal(
    <>
      <div
        role="dialog"
        aria-modal="true"
        aria-labelledby={`modal-title-${post.id}`}
        className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-950/70 backdrop-blur-md"
        onClick={() => {
          if (!isPending && !confirmAction) onClose();
        }}
      >
        <div
          className="relative w-full max-w-2xl max-h-[90vh] overflow-y-auto bg-white rounded-2xl shadow-2xl border border-slate-200 p-6 sm:p-7 text-left text-slate-900"
          onClick={(e) => e.stopPropagation()}
        >
          {/* Header */}
          <div className="flex items-start justify-between gap-4 pb-4 border-b border-slate-100">
            <div className="space-y-2 text-left">
              <h2
                id={`modal-title-${post.id}`}
                className="text-xl sm:text-2xl font-bold text-slate-900 tracking-tight font-outfit"
              >
                {post.title}
              </h2>
              <div className="flex flex-wrap items-center gap-2">
                <span
                  className={`inline-flex items-center rounded-md px-2.5 py-1 text-xs font-semibold ring-1 ring-inset ${getTypeBadgeColor(
                    post.type,
                  )}`}
                >
                  {getTypeDisplayLabel(post.type)}
                </span>
                {post.isDeleted ? (
                  <span className="inline-flex items-center rounded-md bg-rose-50 px-2.5 py-1 text-xs font-medium text-rose-700 ring-1 ring-inset ring-rose-600/20">
                    Deleted
                  </span>
                ) : (
                  <span
                    className={`inline-flex items-center rounded-md px-2.5 py-1 text-xs font-medium ring-1 ring-inset ${getStatusBadgeColor(
                      post.status,
                    )}`}
                  >
                    {post.status}
                  </span>
                )}
                {post.urgencyLevel && (
                  <span className="inline-flex items-center gap-1 text-xs font-semibold text-rose-600 bg-rose-50 px-2.5 py-1 rounded-md ring-1 ring-inset ring-rose-600/20">
                    <AlertTriangle className="w-3 h-3" />
                    {post.urgencyLevel}
                  </span>
                )}
              </div>
            </div>

            <button
              type="button"
              onClick={onClose}
              disabled={isPending}
              className="p-1.5 text-slate-400 hover:text-slate-700 hover:bg-slate-100 rounded-lg transition-colors cursor-pointer shrink-0"
              aria-label="Close modal"
            >
              <X className="w-5 h-5" />
            </button>
          </div>

          {/* Author, Date, Location, and Animal Meta */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 py-4 text-xs text-slate-600 border-b border-slate-100 w-full">
            {/* Left column */}
            <div className="space-y-2.5 text-left">
              <div className="flex items-center gap-2">
                <User className="w-4 h-4 text-slate-400 shrink-0" />
                <span className="truncate">
                  Author:{" "}
                  <strong className="font-semibold text-slate-800">
                    {post.authorDisplayName}
                  </strong>
                  {post.authorEmail && (
                    <span className="text-slate-500">
                      {" "}
                      ({post.authorEmail})
                    </span>
                  )}
                </span>
              </div>
              {post.locationLabel && (
                <div className="flex items-center gap-2">
                  <MapPin className="w-4 h-4 text-slate-400 shrink-0" />
                  <span className="text-slate-700">
                    Location: {post.locationLabel}
                  </span>
                </div>
              )}
            </div>

            {/* Right column aligned to the right edge */}
            <div className="space-y-2.5 sm:text-right sm:flex sm:flex-col sm:items-end">
              <div className="flex items-center gap-2 sm:justify-end">
                <Calendar className="w-4 h-4 text-slate-400 shrink-0" />
                <span className="text-slate-700">
                  Posted: {new Date(post.createdAt).toLocaleString()}
                </span>
              </div>
              {post.animalName && (
                <div className="flex items-center gap-2 sm:justify-end">
                  <PawPrint className="w-4 h-4 text-slate-400 shrink-0" />
                  <span className="text-slate-700">
                    Animal:{" "}
                    <strong className="font-semibold text-slate-800">
                      {post.animalName}
                    </strong>
                    {post.animalSpecies && (
                      <span className="text-slate-500">
                        {" "}
                        ({post.animalSpecies})
                      </span>
                    )}
                  </span>
                </div>
              )}
            </div>
          </div>

          {/* AI Triage if present */}
          {(post.urgencyLevel || post.aiTriageReason) && (
            <div className="my-4 rounded-xl border border-amber-200 bg-amber-50/70 p-4 text-sm text-left">
              <div className="flex items-center gap-2 font-semibold text-amber-900 mb-1">
                <AlertTriangle className="w-4 h-4 text-amber-700 shrink-0" />
                <span>
                  AI triage assessment: {post.urgencyLevel || "Not assigned"}
                </span>
              </div>
              {post.aiTriageReason && (
                <p className="text-xs text-amber-800 leading-relaxed text-left">
                  {post.aiTriageReason}
                </p>
              )}
            </div>
          )}

          {/* Post Body */}
          <div className="py-4 text-left">
            <h3 className="text-xs font-semibold uppercase tracking-wider text-slate-400 mb-2 text-left">
              Post description
            </h3>
            <p className="text-sm text-slate-700 whitespace-pre-line leading-relaxed text-left">
              {post.body}
            </p>
          </div>

          {/* Attached Photos */}
          {post.photoUrls && post.photoUrls.length > 0 && (
            <div className="py-4 border-t border-slate-100 text-left">
              <h3 className="text-xs font-semibold uppercase tracking-wider text-slate-400 mb-3 text-left">
                Attached media ({post.photoUrls.length})
              </h3>
              <div className="grid grid-cols-2 sm:grid-cols-3 gap-3">
                {post.photoUrls.map((url, idx) => (
                  <div
                    key={idx}
                    className="relative aspect-square overflow-hidden rounded-xl bg-slate-100 border border-slate-200"
                  >
                    <Image
                      src={url}
                      alt={`Photo ${idx + 1} for ${post.title}`}
                      fill
                      unoptimized
                      sizes="(max-width: 640px) 50vw, 33vw"
                      className="object-cover"
                    />
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Moderation actions footer */}
          <div className="pt-4 mt-2 border-t border-slate-100 flex flex-wrap items-center justify-end gap-2.5">
            {post.isDeleted ? (
              <>
                <button
                  type="button"
                  onClick={() => handleOpenConfirm("permanentDelete")}
                  disabled={isPending}
                  className="px-4 py-2 text-xs font-semibold rounded-xl shadow-xs transition-all flex items-center gap-1.5 cursor-pointer disabled:cursor-not-allowed bg-rose-600 hover:bg-rose-700 active:scale-[0.98] disabled:bg-rose-300 text-white"
                >
                  <Trash2 className="w-4 h-4" />
                  <span>Permanent delete</span>
                </button>
                <button
                  type="button"
                  onClick={() => handleOpenConfirm("restore")}
                  disabled={isPending}
                  className="px-4 py-2 text-xs font-semibold rounded-xl shadow-xs transition-all flex items-center gap-1.5 cursor-pointer disabled:cursor-not-allowed bg-emerald-600 hover:bg-emerald-700 active:scale-[0.98] disabled:bg-emerald-300 text-white"
                >
                  <RotateCcw className="w-4 h-4" />
                  <span>Restore post</span>
                </button>
              </>
            ) : (
              <>
                {post.status === "PendingApproval" && (
                  <>
                    <button
                      type="button"
                      onClick={() => handleOpenConfirm("reject")}
                      disabled={isPending}
                      className="px-4 py-2 text-xs font-semibold rounded-xl shadow-xs transition-all flex items-center gap-1.5 cursor-pointer disabled:cursor-not-allowed bg-slate-100 hover:bg-slate-200 text-slate-700 border border-slate-200"
                    >
                      <XCircle className="w-4 h-4 text-rose-500" />
                      <span>Reject post</span>
                    </button>
                    <button
                      type="button"
                      onClick={() => handleOpenConfirm("approve")}
                      disabled={isPending}
                      className="px-4 py-2 text-xs font-semibold rounded-xl shadow-xs transition-all flex items-center gap-1.5 cursor-pointer disabled:cursor-not-allowed bg-blue-600 hover:bg-blue-700 active:scale-[0.98] text-white"
                    >
                      <CheckCircle className="w-4 h-4" />
                      <span>Approve post</span>
                    </button>
                  </>
                )}
                <button
                  type="button"
                  onClick={() => handleOpenConfirm("delete")}
                  disabled={isPending}
                  className="px-4 py-2 text-xs font-semibold rounded-xl shadow-xs transition-all flex items-center gap-1.5 cursor-pointer disabled:cursor-not-allowed bg-rose-600 hover:bg-rose-700 active:scale-[0.98] disabled:bg-rose-300 text-white"
                >
                  <Trash2 className="w-4 h-4" />
                  <span>Delete post</span>
                </button>
              </>
            )}
          </div>
        </div>
      </div>

      <ConfirmModal
        isOpen={confirmAction !== null}
        title={modalConfig.title}
        description={modalConfig.description}
        confirmLabel={modalConfig.confirmLabel}
        variant={modalConfig.variant}
        isPending={isPending}
        error={error}
        checkboxes={modalConfig.checkboxes}
        onConfirm={handleExecuteModeration}
        onClose={handleCloseConfirm}
      />
    </>,
    document.body,
  );
}
