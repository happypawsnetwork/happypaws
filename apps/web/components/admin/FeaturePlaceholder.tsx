"use client";

import { motion } from "framer-motion";
import { HammerIcon } from "./Icons";

export function FeaturePlaceholder({
  title,
  description,
}: {
  title: string;
  description: string;
}) {
  return (
    <div className="flex-1 flex flex-col items-center justify-center min-h-[420px] p-8 text-center">
      <motion.div
        initial={{ opacity: 0, y: 12 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ type: "spring", bounce: 0, duration: 0.4 }}
        className="max-w-md w-full bg-white/70 backdrop-blur-2xl rounded-3xl shadow-[0_8px_30px_rgba(0,0,0,0.04)] border border-slate-200/80 p-8 flex flex-col items-center"
      >
        <div className="w-14 h-14 bg-blue-50 text-blue-600 rounded-2xl flex items-center justify-center mb-5 border border-blue-100 shadow-inner">
          <HammerIcon className="w-7 h-7" />
        </div>
        <h2 className="text-xl font-semibold text-slate-800 tracking-tight mb-2 font-outfit">
          {title}
        </h2>
        <p className="text-slate-500 text-sm leading-relaxed font-light">
          {description}
        </p>
      </motion.div>
    </div>
  );
}
