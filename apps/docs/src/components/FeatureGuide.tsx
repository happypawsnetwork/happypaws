import { useState, useEffect, useCallback, useRef } from "react";
import { motion, useAnimationControls, AnimatePresence } from "framer-motion";
import {
  Smartphone,
  ZoomIn,
  X,
  ChevronLeft,
  ChevronRight,
  Sparkles,
  Lightbulb,
  MousePointerClick,
  Layers,
  ArrowRight,
  GripHorizontal
} from "lucide-react";
import type { FeatureGuideStep } from "@/data/featureGuides";

interface FeatureGuideProps {
  steps?: FeatureGuideStep[];
  storyTitle?: string;
}

export function FeatureGuide({ steps, storyTitle }: FeatureGuideProps) {
  const [currentStepIndex, setCurrentStepIndex] = useState(0);
  const [activeImageIndex, setActiveImageIndex] = useState<number | null>(null);

  const containerRef = useRef<HTMLDivElement>(null);
  const [containerWidth, setContainerWidth] = useState(0);
  const controls = useAnimationControls();

  // Measure container width accurately on mount and resize
  useEffect(() => {
    if (!containerRef.current) return;

    const updateWidth = () => {
      if (containerRef.current) {
        setContainerWidth(containerRef.current.offsetWidth);
      }
    };

    updateWidth();
    const observer = new ResizeObserver(updateWidth);
    observer.observe(containerRef.current);

    return () => observer.disconnect();
  }, []);

  const prevWidthRef = useRef(0);

  // Sync animation position when container width or active slide changes
  const goToStep = useCallback(
    (nextIndex: number) => {
      if (!steps || steps.length === 0) return;
      if (nextIndex < 0 || nextIndex >= steps.length) return;

      setCurrentStepIndex(nextIndex);
      if (containerWidth > 0) {
        controls.start({
          x: -nextIndex * containerWidth,
          transition: { type: "spring", bounce: 0, duration: 0.45 }
        });
      }
    },
    [containerWidth, controls, steps]
  );

  // Re-align track position only when container width actually resizes
  useEffect(() => {
    if (containerWidth > 0 && prevWidthRef.current !== containerWidth) {
      prevWidthRef.current = containerWidth;
      controls.set({ x: -currentStepIndex * containerWidth });
    }
  }, [containerWidth, controls, currentStepIndex]);

  // Handle slide drag release (10% threshold to advance to next/prev slide)
  const handleDragEnd = (
    _e: MouseEvent | TouchEvent | PointerEvent,
    info: { offset: { x: number; y: number }; velocity: { x: number; y: number } }
  ) => {
    if (!steps || steps.length === 0 || containerWidth === 0) return;

    const dragDistance = info.offset.x;
    const dragVelocity = info.velocity.x;
    // 10% threshold: making at least 10% visible triggers slide change
    const threshold = containerWidth * 0.1;

    let targetIndex = currentStepIndex;

    if (dragDistance < -threshold || dragVelocity < -250) {
      targetIndex = Math.min(currentStepIndex + 1, steps.length - 1);
    } else if (dragDistance > threshold || dragVelocity > 250) {
      targetIndex = Math.max(currentStepIndex - 1, 0);
    }

    setCurrentStepIndex(targetIndex);
    controls.start({
      x: -targetIndex * containerWidth,
      transition: { type: "spring", bounce: 0, duration: 0.45 }
    });
  };

  // Keyboard navigation for slides and modal
  const handleKeyDown = useCallback(
    (e: KeyboardEvent) => {
      if (!steps || steps.length === 0) return;

      if (activeImageIndex !== null) {
        if (e.key === "Escape") {
          setActiveImageIndex(null);
        } else if (e.key === "ArrowLeft") {
          setActiveImageIndex((prev) => {
            const nextIdx = prev !== null && prev > 0 ? prev - 1 : steps.length - 1;
            goToStep(nextIdx);
            return nextIdx;
          });
        } else if (e.key === "ArrowRight") {
          setActiveImageIndex((prev) => {
            const nextIdx = prev !== null && prev < steps.length - 1 ? prev + 1 : 0;
            goToStep(nextIdx);
            return nextIdx;
          });
        }
      } else {
        if (e.key === "ArrowLeft") {
          if (currentStepIndex > 0) {
            goToStep(currentStepIndex - 1);
          }
        } else if (e.key === "ArrowRight") {
          if (currentStepIndex < steps.length - 1) {
            goToStep(currentStepIndex + 1);
          }
        }
      }
    },
    [activeImageIndex, currentStepIndex, goToStep, steps]
  );

  useEffect(() => {
    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [handleKeyDown]);

  // Empty state when no steps are documented yet
  if (!steps || steps.length === 0) {
    return (
      <div className="bg-white p-10 md:p-14 rounded-2xl border border-slate-200/80 shadow-xs text-center space-y-4">
        <div className="w-14 h-14 rounded-2xl bg-teal-50 border border-teal-100 flex items-center justify-center mx-auto text-teal-700">
          <Layers className="w-7 h-7" />
        </div>
        <div className="space-y-1.5 max-w-md mx-auto">
          <h3 className="text-base font-semibold text-slate-800">
            Feature guide in preparation
          </h3>
          <p className="text-xs text-slate-500 leading-relaxed">
            Screen captures and step guidance are currently being assembled for this user story.
          </p>
        </div>
        <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-slate-100 text-[11px] font-medium text-slate-600">
          <Sparkles className="w-3.5 h-3.5 text-amber-500" />
          Interactive walkthrough coming soon
        </div>
      </div>
    );
  }

  const currentModalStep =
    activeImageIndex !== null ? steps[activeImageIndex] : null;

  return (
    <div className="space-y-6">
      {/* Top Walkthrough Step Selector Bar (Same length as gallery card below) */}
      <div className="w-full bg-white p-4 rounded-2xl border border-slate-200/80 shadow-xs space-y-3">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <Smartphone className="w-4 h-4 text-teal-700" />
            <span className="text-xs font-bold uppercase tracking-wider text-slate-500">
              {storyTitle ? `${storyTitle} walkthrough` : "Screen walkthrough"}
            </span>
          </div>
          <span className="text-xs text-slate-400 font-medium">
            Slide {currentStepIndex + 1} of {steps.length}
          </span>
        </div>

        <div className="flex flex-wrap gap-2">
          {steps.map((step, idx) => {
            const isActive = idx === currentStepIndex;

            return (
              <button
                key={step.stepNumber}
                type="button"
                onClick={() => goToStep(idx)}
                className={`px-3 py-1.5 rounded-lg text-xs font-medium transition-all flex items-center gap-1.5 cursor-pointer ${
                  isActive
                    ? "bg-teal-700 text-white shadow-xs"
                    : "bg-slate-50 hover:bg-teal-50 hover:text-teal-800 text-slate-700 border border-slate-200/80"
                }`}
              >
                <span
                  className={`w-4 h-4 rounded-full text-[10px] font-bold flex items-center justify-center ${
                    isActive
                      ? "bg-teal-800 text-white"
                      : "bg-slate-200 text-slate-700"
                  }`}
                >
                  {idx + 1}
                </span>
                <span className="truncate max-w-[140px] sm:max-w-[200px]">
                  {step.screenName}
                </span>
              </button>
            );
          })}
        </div>
      </div>

      {/* Sliding Gallery Card Container (Identical length and outer borders) */}
      <div
        ref={containerRef}
        className="w-full bg-white rounded-3xl border border-slate-200/90 shadow-sm overflow-hidden relative"
      >
        {/* Floating Left Slide Button */}
        <button
          type="button"
          disabled={currentStepIndex === 0}
          onClick={() => goToStep(currentStepIndex - 1)}
          className={`absolute left-3 sm:left-4 top-1/2 -translate-y-1/2 z-30 p-2.5 sm:p-3 rounded-full border shadow-md backdrop-blur-xs transition-all duration-200 flex items-center justify-center cursor-pointer ${
            currentStepIndex === 0
              ? "opacity-0 pointer-events-none"
              : "bg-white/90 hover:bg-white text-slate-700 hover:text-slate-900 border-slate-200/90 active:scale-95 hover:scale-105"
          }`}
          aria-label="Previous slide"
          title="Previous slide"
        >
          <ChevronLeft className="w-5 h-5" />
        </button>

        {/* Floating Right Slide Button */}
        <button
          type="button"
          disabled={currentStepIndex === steps.length - 1}
          onClick={() => goToStep(currentStepIndex + 1)}
          className={`absolute right-3 sm:right-4 top-1/2 -translate-y-1/2 z-30 p-2.5 sm:p-3 rounded-full border shadow-md backdrop-blur-xs transition-all duration-200 flex items-center justify-center cursor-pointer ${
            currentStepIndex === steps.length - 1
              ? "opacity-0 pointer-events-none"
              : "bg-teal-700 hover:bg-teal-800 text-white border-teal-700 shadow-teal-900/20 active:scale-95 hover:scale-105"
          }`}
          aria-label="Next slide"
          title="Next slide"
        >
          <ChevronRight className="w-5 h-5" />
        </button>

        {/* Continuous Horizontal Sliding Track */}
        <motion.div
          className="flex w-full cursor-grab active:cursor-grabbing select-none"
          style={{ touchAction: "pan-y" }}
          drag="x"
          dragConstraints={{
            left: -((steps.length - 1) * (containerWidth || 1)),
            right: 0
          }}
          dragElastic={0.12}
          animate={controls}
          onDragEnd={handleDragEnd}
        >
          {steps.map((step, idx) => (
            <div
              key={step.stepNumber}
              style={{ width: containerWidth ? `${containerWidth}px` : "100%" }}
              className="w-full shrink-0 p-6 md:p-8 space-y-6 flex flex-col justify-between"
            >
              {/* Slide Header: Step counter and title positioned at top-left */}
              <div className="flex flex-col sm:flex-row sm:items-start justify-between gap-4 border-b border-slate-100 pb-5">
                <div className="space-y-1.5">
                  <div className="flex items-center gap-2.5 flex-wrap">
                    <span className="px-2.5 py-0.5 rounded-full bg-teal-50 border border-teal-200/80 text-teal-800 text-xs font-bold tracking-wide">
                      Step {step.stepNumber < 10 ? `0${step.stepNumber}` : step.stepNumber} of{" "}
                      {steps.length < 10 ? `0${steps.length}` : steps.length}
                    </span>
                    <span className="text-xs font-semibold uppercase tracking-wider text-slate-400">
                      {step.screenName}
                    </span>
                  </div>
                  <h3 className="text-2xl font-bold text-slate-900 tracking-tight">
                    {step.title}
                  </h3>
                </div>

                {/* Drag Hint Indicator & Mini Step Counter */}
                <div className="flex items-center gap-3 shrink-0 self-end sm:self-center">
                  <div className="hidden sm:flex items-center gap-1.5 text-[11px] font-medium text-slate-400 select-none">
                    <GripHorizontal className="w-3.5 h-3.5 text-slate-400" />
                    Drag to switch
                  </div>
                  <span className="text-xs font-semibold text-slate-500 px-2 py-1 rounded-lg bg-slate-50 border border-slate-200/70 select-none min-w-[38px] text-center">
                    {idx + 1} / {steps.length}
                  </span>
                </div>
              </div>

              {/* Slide Body: Screenshot on Left, Guidance on Right */}
              <div className="grid grid-cols-1 md:grid-cols-12 gap-8 items-start flex-1">
                {/* Left Column: Plain Screenshot with zero clipping */}
                <div className="md:col-span-5 flex flex-col items-center">
                  <div className="relative w-full max-w-[320px]">
                    <div
                      role="button"
                      tabIndex={0}
                      onClick={() => setActiveImageIndex(idx)}
                      onKeyDown={(e) => {
                        if (e.key === "Enter" || e.key === " ") {
                          setActiveImageIndex(idx);
                        }
                      }}
                      className="relative group cursor-zoom-in focus:outline-none focus:ring-2 focus:ring-teal-500 rounded-3xl"
                      aria-label={`Enlarge ${step.screenName} screenshot`}
                    >
                      <img
                        src={step.imagePath}
                        alt={step.imageAlt}
                        loading="lazy"
                        className="w-full h-auto object-contain select-none block"
                      />

                      {/* Tactile Hover Overlay without image clipping */}
                      <div className="absolute inset-0 bg-slate-900/10 opacity-0 group-hover:opacity-100 transition-opacity duration-200 flex items-center justify-center rounded-3xl">
                        <span className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-white/95 text-slate-800 text-xs font-semibold shadow-md border border-slate-200/90 backdrop-blur-xs">
                          <ZoomIn className="w-3.5 h-3.5 text-teal-600" />
                          Click to enlarge
                        </span>
                      </div>
                    </div>

                    {/* Caption under Screenshot */}
                    <p className="text-center text-[11px] text-slate-400 mt-2.5 font-medium select-none">
                      Screen {step.stepNumber} &bull; {step.screenName}
                    </p>
                  </div>
                </div>

                {/* Right Column: Guidance and Actions */}
                <div className="md:col-span-7 space-y-5">
                  {/* Screen Description */}
                  <p className="text-sm text-slate-600 leading-relaxed">
                    {step.description}
                  </p>

                  {/* Primary Action Box */}
                  <div className="rounded-xl border border-teal-200 bg-teal-50/70 p-4 space-y-2.5">
                    <div className="flex items-center justify-between gap-2">
                      <span className="text-xs font-bold uppercase tracking-wider text-teal-900 flex items-center gap-1.5">
                        <MousePointerClick className="w-3.5 h-3.5 text-teal-700" />
                        Primary action
                      </span>
                      {step.primaryAction.targetName && (
                        <span className="text-[11px] text-teal-700/80">
                          {step.primaryAction.targetName}
                        </span>
                      )}
                    </div>

                    <div className="flex flex-col sm:flex-row sm:items-center gap-2.5">
                      <div className="inline-flex items-center gap-1.5 px-3.5 py-1.5 rounded-lg bg-teal-700 text-white text-xs font-semibold shadow-xs shrink-0 self-start sm:self-auto">
                        <span>{step.primaryAction.label}</span>
                        <ArrowRight className="w-3 h-3 text-teal-200" />
                      </div>
                      <p className="text-xs text-teal-950 leading-relaxed">
                        {step.primaryAction.description}
                      </p>
                    </div>
                  </div>

                  {/* Secondary Action Box */}
                  {step.secondaryAction && (
                    <div className="rounded-xl border border-slate-200/80 bg-slate-50/80 p-3.5 space-y-2">
                      <span className="text-[11px] font-bold uppercase tracking-wider text-slate-500 block">
                        Secondary action
                      </span>
                      <div className="flex flex-col sm:flex-row sm:items-center gap-2">
                        <span className="inline-flex items-center px-2.5 py-1 rounded-md bg-white border border-slate-200 text-slate-800 text-xs font-medium shrink-0 self-start sm:self-auto">
                          {step.secondaryAction.label}
                        </span>
                        <p className="text-xs text-slate-600 leading-relaxed">
                          {step.secondaryAction.description}
                        </p>
                      </div>
                    </div>
                  )}

                  {/* Tips & Recommendations */}
                  {step.tips && step.tips.length > 0 && (
                    <div className="rounded-xl border border-amber-200/70 bg-amber-50/50 p-3.5 space-y-1.5 text-xs text-amber-950">
                      <div className="flex items-center gap-1.5 font-semibold text-amber-900">
                        <Lightbulb className="w-3.5 h-3.5 text-amber-600 shrink-0" />
                        <span>Helpful tip</span>
                      </div>
                      <ul className="space-y-1 pl-5 list-disc marker:text-amber-500 leading-relaxed">
                        {step.tips.map((tip, tipIdx) => (
                          <li key={tipIdx}>{tip}</li>
                        ))}
                      </ul>
                    </div>
                  )}
                </div>
              </div>

              {/* Slide Navigation Footer */}
              <div className="pt-6 border-t border-slate-100 flex items-center justify-between gap-3">
                {/* Previous Slide Button */}
                {idx > 0 ? (
                  <button
                    type="button"
                    onClick={() => goToStep(idx - 1)}
                    className="px-4 py-2 rounded-xl border border-slate-200 bg-white hover:bg-slate-50 text-slate-700 text-xs font-semibold shadow-xs flex items-center gap-2 transition-all active:scale-[0.98] cursor-pointer"
                  >
                    <ChevronLeft className="w-4 h-4 text-slate-500" />
                    <span className="hidden sm:inline">
                      Previous: {steps[idx - 1].screenName}
                    </span>
                    <span className="sm:hidden">Previous</span>
                  </button>
                ) : (
                  <div className="px-4 py-2 text-xs font-medium text-slate-400 select-none">
                    First step
                  </div>
                )}

                {/* Progress Dots */}
                <div className="flex items-center gap-1.5">
                  {steps.map((_, dotIdx) => (
                    <button
                      key={dotIdx}
                      type="button"
                      onClick={() => goToStep(dotIdx)}
                      className={`transition-all duration-300 rounded-full cursor-pointer ${
                        dotIdx === currentStepIndex
                          ? "w-6 h-2 bg-teal-700"
                          : "w-2 h-2 bg-slate-200 hover:bg-slate-400"
                      }`}
                      aria-label={`Go to step ${dotIdx + 1}`}
                      title={`Step ${dotIdx + 1}: ${steps[dotIdx].screenName}`}
                    />
                  ))}
                </div>

                {/* Next Slide Button */}
                {idx < steps.length - 1 ? (
                  <button
                    type="button"
                    onClick={() => goToStep(idx + 1)}
                    className="px-4 py-2 rounded-xl bg-teal-700 hover:bg-teal-800 text-white text-xs font-semibold shadow-xs flex items-center gap-2 transition-all active:scale-[0.98] cursor-pointer"
                  >
                    <span className="hidden sm:inline">
                      Next: {steps[idx + 1].screenName}
                    </span>
                    <span className="sm:hidden">Next</span>
                    <ChevronRight className="w-4 h-4 text-teal-200" />
                  </button>
                ) : (
                  <button
                    type="button"
                    onClick={() => goToStep(0)}
                    className="px-4 py-2 rounded-xl bg-teal-50 border border-teal-200 text-teal-800 hover:bg-teal-100 text-xs font-semibold shadow-xs flex items-center gap-2 transition-all active:scale-[0.98] cursor-pointer"
                  >
                    <span>Restart walkthrough</span>
                    <ChevronRight className="w-4 h-4 text-teal-600" />
                  </button>
                )}
              </div>
            </div>
          ))}
        </motion.div>
      </div>

      {/* Lightbox Modal with Critically Damped Spring Motion */}
      <AnimatePresence>
        {activeImageIndex !== null && currentModalStep && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            transition={{ duration: 0.2 }}
            className="fixed inset-0 z-50 bg-slate-900/40 backdrop-blur-sm flex items-center justify-center p-4 sm:p-6"
            onClick={() => setActiveImageIndex(null)}
          >
            <motion.div
              role="dialog"
              aria-modal="true"
              aria-label={`Enlarged view of ${currentModalStep.screenName}`}
              initial={{ scale: 0.94, opacity: 0, y: 8 }}
              animate={{ scale: 1, opacity: 1, y: 0 }}
              exit={{ scale: 0.94, opacity: 0, y: 8 }}
              transition={{ type: "spring", bounce: 0, duration: 0.35 }}
              onClick={(e) => e.stopPropagation()}
              className="relative max-w-4xl w-full bg-white rounded-2xl border border-slate-200 shadow-2xl p-4 sm:p-6 text-slate-900 space-y-4 max-h-[92vh] flex flex-col"
            >
              {/* Modal Top Bar */}
              <div className="flex items-center justify-between gap-4 border-b border-slate-100 pb-3 shrink-0">
                <div className="min-w-0">
                  <div className="flex items-center gap-2">
                    <span className="text-xs font-bold text-teal-700">
                      Step {currentModalStep.stepNumber} of {steps.length}
                    </span>
                    <span className="text-xs text-slate-400 truncate">
                      {currentModalStep.screenName}
                    </span>
                  </div>
                  <h4 className="text-sm font-semibold text-slate-900 truncate mt-0.5">
                    {currentModalStep.title}
                  </h4>
                </div>

                <button
                  type="button"
                  onClick={() => setActiveImageIndex(null)}
                  className="p-1.5 rounded-lg bg-slate-100 hover:bg-slate-200 text-slate-500 hover:text-slate-800 transition-colors cursor-pointer"
                  aria-label="Close modal"
                >
                  <X className="w-5 h-5" />
                </button>
              </div>

              {/* Modal Image Display */}
              <div className="relative flex-1 min-h-0 flex items-center justify-center overflow-hidden py-2 bg-slate-50/60 border border-slate-100 rounded-xl">
                <img
                  src={currentModalStep.imagePath}
                  alt={currentModalStep.imageAlt}
                  className="max-h-[64vh] w-auto max-w-full object-contain rounded-lg shadow-xs select-none bg-white"
                />

                {/* Left/Right Arrow Navigation */}
                {steps.length > 1 && (
                  <>
                    <button
                      type="button"
                      onClick={(e) => {
                        e.stopPropagation();
                        setActiveImageIndex((prev) => {
                          const nextIdx = prev !== null && prev > 0 ? prev - 1 : steps.length - 1;
                          goToStep(nextIdx);
                          return nextIdx;
                        });
                      }}
                      className="absolute left-2 top-1/2 -translate-y-1/2 p-2 rounded-full bg-white/95 hover:bg-white text-slate-700 hover:text-slate-900 transition-colors cursor-pointer shadow-md border border-slate-200"
                      aria-label="Previous step"
                    >
                      <ChevronLeft className="w-5 h-5" />
                    </button>
                    <button
                      type="button"
                      onClick={(e) => {
                        e.stopPropagation();
                        setActiveImageIndex((prev) => {
                          const nextIdx = prev !== null && prev < steps.length - 1 ? prev + 1 : 0;
                          goToStep(nextIdx);
                          return nextIdx;
                        });
                      }}
                      className="absolute right-2 top-1/2 -translate-y-1/2 p-2 rounded-full bg-white/95 hover:bg-white text-slate-700 hover:text-slate-900 transition-colors cursor-pointer shadow-md border border-slate-200"
                      aria-label="Next step"
                    >
                      <ChevronRight className="w-5 h-5" />
                    </button>
                  </>
                )}
              </div>

              {/* Modal Bottom Guidance Footer */}
              <div className="flex items-center justify-between gap-3 text-xs text-slate-500 border-t border-slate-100 pt-3 shrink-0">
                <div className="flex items-center gap-1.5">
                  <span className="font-semibold text-slate-700">Highlight:</span>
                  <span className="px-2 py-0.5 rounded bg-teal-50 text-teal-800 border border-teal-200/80 font-medium">
                    {currentModalStep.primaryAction.label}
                  </span>
                </div>
                <div className="text-[11px] text-slate-400">
                  Use arrow keys or click outside to close
                </div>
              </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}
