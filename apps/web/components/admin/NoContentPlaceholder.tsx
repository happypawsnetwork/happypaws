"use client";

import React from "react";
import { motion } from "framer-motion";
import { Inbox } from "lucide-react";

interface NoContentPlaceholderProps {
  title?: string;
  description?: string;
}

export function NoContentPlaceholder({
  title = "No content available",
  description = "There are currently no records or updates to display.",
}: NoContentPlaceholderProps) {
  return (
    <div className="flex-1 flex flex-col items-center justify-center min-h-[380px] p-8 text-center">
      <motion.div
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ type: "spring", bounce: 0, duration: 0.35 }}
        className="max-w-md w-full bg-white/80 backdrop-blur-xl rounded-3xl shadow-[0_8px_30px_rgba(0,0,0,0.04)] border border-slate-200/80 p-8 flex flex-col items-center"
      >
        <div className="w-14 h-14 bg-slate-100/90 text-slate-500 rounded-2xl flex items-center justify-center mb-4 border border-slate-200/80 shadow-xs">
          <Inbox className="w-7 h-7" />
        </div>
        <h2 className="text-xl font-bold text-slate-900 tracking-tight mb-2 font-outfit">
          {title}
        </h2>
        <p className="text-slate-500 text-sm leading-relaxed font-normal">
          {description}
        </p>
      </motion.div>
    </div>
  );
}
