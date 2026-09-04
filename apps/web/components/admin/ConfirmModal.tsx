"use client";

import React, {
  useState,
  useEffect,
  useCallback,
  useSyncExternalStore,
} from "react";
import { createPortal } from "react-dom";
import { motion, AnimatePresence } from "framer-motion";
import {
  AlertTriangle,
  RotateCcw,
  Trash2,
  Info,
  X,
  Loader2,
} from "lucide-react";

const emptySubscribe = () => () => {};

export interface ConfirmCheckbox {
  id: string;
  label: string;
}

export interface ConfirmModalProps {
  isOpen: boolean;
  title: string;
  description: string;
  confirmLabel?: string;
  cancelLabel?: string;
  variant?: "danger" | "success" | "warning" | "primary";
  isPending?: boolean;
  error?: string | null;
  checkboxes?: ConfirmCheckbox[];
  onConfirm: () => void | Promise<void>;
  onClose: () => void;
}

export function ConfirmModal({
  isOpen,
  title,
  description,
  confirmLabel,
  cancelLabel = "Cancel",
  variant = "danger",
  isPending = false,
  error = null,
  checkboxes,
  onConfirm,
  onClose,
}: ConfirmModalProps) {
  const [checkedMap, setCheckedMap] = useState<Record<string, boolean>>({});

  useEffect(() => {
    if (isOpen) {
      setCheckedMap({});
    }
  }, [isOpen]);

  const allCheckboxesSatisfied =
    !checkboxes ||
    checkboxes.length === 0 ||
    checkboxes.every((cb) => checkedMap[cb.id]);

  const toggleCheckbox = (id: string) => {
    if (isPending) return;
    setCheckedMap((prev) => ({ ...prev, [id]: !prev[id] }));
  };
  const mounted = useSyncExternalStore(
    emptySubscribe,
    () => true,
    () => false,
  );

  const handleKeyDown = useCallback(
    (event: KeyboardEvent) => {
      if (event.key === "Escape" && !isPending) {
        onClose();
      }
    },
    [isPending, onClose],
  );

  useEffect(() => {
    if (isOpen) {
      window.addEventListener("keydown", handleKeyDown);
      return () => window.removeEventListener("keydown", handleKeyDown);
    }
  }, [isOpen, handleKeyDown]);

  if (!mounted) return null;

  const getVariantStyles = () => {
    switch (variant) {
      case "danger":
        return {
          icon: <Trash2 className="w-5 h-5 text-rose-600" />,
          iconBg: "bg-rose-50 border-rose-100",
          buttonBg:
            "bg-rose-600 hover:bg-rose-700 active:scale-[0.98] disabled:bg-rose-300 text-white",
          defaultConfirm: "Delete",
        };
      case "success":
        return {
          icon: <RotateCcw className="w-5 h-5 text-emerald-600" />,
          iconBg: "bg-emerald-50 border-emerald-100",
          buttonBg:
            "bg-emerald-600 hover:bg-emerald-700 active:scale-[0.98] disabled:bg-emerald-300 text-white",
          defaultConfirm: "Restore",
        };
      case "warning":
        return {
          icon: <AlertTriangle className="w-5 h-5 text-amber-600" />,
          iconBg: "bg-amber-50 border-amber-100",
          buttonBg:
            "bg-amber-600 hover:bg-amber-700 active:scale-[0.98] disabled:bg-amber-300 text-white",
          defaultConfirm: "Proceed",
        };
      case "primary":
      default:
        return {
          icon: <Info className="w-5 h-5 text-blue-600" />,
          iconBg: "bg-blue-50 border-blue-100",
          buttonBg:
            "bg-blue-600 hover:bg-blue-700 active:scale-[0.98] disabled:bg-blue-300 text-white",
          defaultConfirm: "Confirm",
        };
    }
  };

  const currentVariant = getVariantStyles();
  const effectiveConfirmLabel = confirmLabel || currentVariant.defaultConfirm;

  return createPortal(
    <AnimatePresence>
      {isOpen && (
        <div
          role="dialog"
          aria-modal="true"
          aria-labelledby="confirm-modal-title"
          aria-describedby="confirm-modal-description"
          className="fixed inset-0 z-50 flex items-center justify-center p-4"
        >
          {/* Darkened and blurred backdrop overlay to cover page content */}
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            transition={{ duration: 0.2 }}
            onClick={isPending ? undefined : onClose}
            className="fixed inset-0 bg-slate-950/70 backdrop-blur-md"
          />

          {/* Modal card */}
          <motion.div
            initial={{ opacity: 0, scale: 0.95, y: 8 }}
            animate={{ opacity: 1, scale: 1, y: 0 }}
            exit={{ opacity: 0, scale: 0.95, y: 8 }}
            transition={{ type: "spring", bounce: 0, duration: 0.28 }}
            className="relative w-full max-w-md bg-white rounded-2xl shadow-2xl border border-slate-200/90 overflow-hidden z-10"
          >
            {/* Header */}
            <div className="px-6 py-4 border-b border-slate-100 flex items-center justify-between bg-slate-50/50">
              <div className="flex items-center gap-3">
                <div
                  className={`w-9 h-9 rounded-xl flex items-center justify-center border shadow-2xs ${currentVariant.iconBg}`}
                >
                  {currentVariant.icon}
                </div>
                <div>
                  <h2
                    id="confirm-modal-title"
                    className="text-base font-bold text-slate-900 leading-tight font-outfit"
                  >
                    {title}
                  </h2>
                </div>
              </div>

              <button
                type="button"
                onClick={onClose}
                disabled={isPending}
                aria-label="Close dialog"
                className="p-1 rounded-full text-slate-400 hover:text-slate-700 hover:bg-slate-100 transition-colors disabled:cursor-not-allowed cursor-pointer"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* Body */}
            <div className="p-6 space-y-4">
              <p
                id="confirm-modal-description"
                className="text-sm text-slate-600 leading-relaxed"
              >
                {description}
              </p>

              {checkboxes && checkboxes.length > 0 && (
                <div className="space-y-2 pt-1">
                  {checkboxes.map((cb) => {
                    const isChecked = Boolean(checkedMap[cb.id]);
                    return (
                      <label
                        key={cb.id}
                        className={`flex items-start gap-2.5 p-3 rounded-xl border transition-all cursor-pointer select-none ${
                          isChecked
                            ? "border-rose-300 bg-rose-50/50"
                            : "border-slate-200 bg-slate-50/75 hover:bg-slate-50"
                        }`}
                      >
                        <input
                          type="checkbox"
                          checked={isChecked}
                          onChange={() => toggleCheckbox(cb.id)}
                          disabled={isPending}
                          className="mt-0.5 h-4 w-4 rounded border-slate-300 text-rose-600 focus:ring-rose-500 focus:ring-offset-0 cursor-pointer"
                        />
                        <span className="text-xs text-slate-700 leading-relaxed">
                          {cb.label}
                        </span>
                      </label>
                    );
                  })}
                </div>
              )}

              {error && (
                <div
                  role="alert"
                  className="rounded-xl border border-rose-200 bg-rose-50 p-3 text-xs text-rose-700 flex items-start gap-2"
                >
                  <AlertTriangle className="w-4 h-4 shrink-0 text-rose-600 mt-0.5" />
                  <span>{error}</span>
                </div>
              )}

              {/* Actions footer */}
              <div className="pt-3 border-t border-slate-100 flex items-center justify-end gap-2.5">
                <button
                  type="button"
                  onClick={onClose}
                  disabled={isPending}
                  className="px-4 py-2 text-xs font-semibold text-slate-600 hover:text-slate-900 rounded-xl hover:bg-slate-100 border border-slate-200 transition-colors cursor-pointer disabled:cursor-not-allowed"
                >
                  {cancelLabel}
                </button>
                <button
                  type="button"
                  onClick={onConfirm}
                  disabled={isPending || !allCheckboxesSatisfied}
                  className={`px-4 py-2 text-xs font-semibold rounded-xl shadow-xs transition-all flex items-center gap-1.5 cursor-pointer disabled:cursor-not-allowed ${currentVariant.buttonBg}`}
                >
                  {isPending ? (
                    <>
                      <Loader2 className="w-3.5 h-3.5 animate-spin" />
                      <span>Processing...</span>
                    </>
                  ) : (
                    <span>{effectiveConfirmLabel}</span>
                  )}
                </button>
              </div>
            </div>
          </motion.div>
        </div>
      )}
    </AnimatePresence>,
    document.body,
  );
}
