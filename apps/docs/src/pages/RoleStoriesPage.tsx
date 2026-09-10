import { useState } from "react";
import { useParams, Link } from "react-router";
import { motion } from "framer-motion";
import { getStoriesByRole, ROLE_CATEGORIES } from "@/data/userStories";
import { parseEndpointString, getMethodBadgeClasses } from "@/data/openApiUtils";
import {
  FileText,
  ListChecks,
  Smartphone,
  Globe,
  Compass,
  ExternalLink,
  Clock,
  CheckCircle2
} from "lucide-react";
import { FeatureGuide } from "@/components/FeatureGuide";
import { getFeatureGuide, getStoryStatus } from "@/data/featureGuides";

export function RoleStoriesPage() {
  const { roleId, storyId } = useParams();
  const category = ROLE_CATEGORIES.find((c) => c.id === roleId) || ROLE_CATEGORIES[0];
  const stories = getStoriesByRole(roleId || category.id);

  // Active story selection
  const activeStory = stories.find((s) => s.id === storyId) || stories[0];
  const activeStoryStatus = getStoryStatus(activeStory);
  const [activeTab, setActiveTab] = useState<"overview" | "guide">("overview");

  const tabs = [
    { id: "overview" as const, label: "Story overview", icon: FileText },
    { id: "guide" as const, label: "Feature guide", icon: ListChecks },
  ];

  return (
    <div className="space-y-6">
      {activeStory ? (
        <div className="space-y-6">
          {/* Top-Level Tab Navigation */}
          <div
            role="tablist"
            aria-label="Story sections"
            className="flex items-center gap-8 border-b border-slate-200"
          >
            {tabs.map((tab) => {
              const Icon = tab.icon;
              const isActive = activeTab === tab.id;

              return (
                <button
                  key={tab.id}
                  role="tab"
                  id={`tab-${tab.id}`}
                  aria-selected={isActive}
                  aria-controls={`tabpanel-${tab.id}`}
                  onClick={() => setActiveTab(tab.id)}
                  className={`group relative pb-3 flex items-center gap-2 text-sm font-medium transition-colors cursor-pointer select-none ${
                    isActive
                      ? "text-teal-800 font-semibold"
                      : "text-slate-500 hover:text-slate-800"
                  }`}
                >
                  <Icon
                    className={`w-4 h-4 transition-colors ${
                      isActive
                        ? "text-teal-700"
                        : "text-slate-400 group-hover:text-slate-600"
                    }`}
                  />
                  <span>{tab.label}</span>

                  {isActive && (
                    <motion.div
                      layoutId="activeStoryTabIndicator"
                      className="absolute bottom-0 left-0 right-0 h-0.5 bg-teal-700 rounded-full"
                      transition={{ type: "spring", bounce: 0, duration: 0.35 }}
                    />
                  )}
                </button>
              );
            })}
          </div>

          {/* Tab 1: Story Overview & Technical Architecture */}
          {activeTab === "overview" && (
            <motion.div
              key="overview"
              id="tabpanel-overview"
              role="tabpanel"
              aria-labelledby="tab-overview"
              initial={{ opacity: 0, y: 6 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.2, ease: "easeOut" }}
              className="bg-white p-6 md:p-7 rounded-2xl border border-slate-200/80 shadow-xs space-y-6"
            >
              {/* Story Header Badges */}
              <div className="flex flex-wrap items-center justify-between gap-3">
                <div className="flex items-center gap-2">
                  <span className="text-xs font-mono uppercase tracking-wider px-2 py-0.5 rounded-md bg-teal-50 text-teal-800 border border-teal-200/60 font-semibold">
                    {activeStory.id}
                  </span>
                  <span className="text-xs font-medium text-slate-400">•</span>
                  <span className="text-xs font-medium text-slate-600">
                    {activeStory.platform}
                  </span>
                  <span className="text-xs font-medium text-slate-400">•</span>
                  {activeStoryStatus.isPending ? (
                    <span
                      title={activeStoryStatus.reason}
                      className="inline-flex items-center gap-1 text-[11px] font-semibold px-2 py-0.5 rounded-md bg-amber-50 text-amber-800 border border-amber-200/80"
                    >
                      <Clock className="w-3 h-3 text-amber-600" />
                      Pending
                    </span>
                  ) : (
                    <span
                      title="Story overview and feature guide ready"
                      className="inline-flex items-center gap-1 text-[11px] font-semibold px-2 py-0.5 rounded-md bg-emerald-50 text-emerald-800 border border-emerald-200/80"
                    >
                      <CheckCircle2 className="w-3 h-3 text-emerald-600" />
                      Ready
                    </span>
                  )}
                </div>
              </div>

              {/* Functionality & User Story Quote */}
              <div className="space-y-2">
                <h2 className="text-xl font-bold text-slate-900 tracking-tight">
                  {activeStory.functionality}
                </h2>
                <div className="p-4 rounded-xl bg-slate-50 border border-slate-100 text-sm text-slate-700 leading-relaxed font-serif italic">
                  &ldquo;{activeStory.userStory}&rdquo;
                </div>
              </div>

              {/* Functionality Description */}
              <div>
                <h3 className="text-xs font-bold uppercase tracking-wider text-slate-400 mb-1.5">
                  Functionality description
                </h3>
                <p className="text-sm text-slate-600 leading-relaxed">
                  {activeStory.description}
                </p>
              </div>

              {/* Technical Architecture (Consolidated) */}
              <div className="pt-6 border-t border-slate-100 space-y-5">
                <div>
                  <h3 className="text-xs font-bold uppercase tracking-wider text-slate-400 mb-1">
                    Technical architecture
                  </h3>
                  <p className="text-xs text-slate-500">
                    How this functionality is wired within the monorepo architecture.
                  </p>
                </div>

                <div className="space-y-4">
                  <div>
                    <h4 className="text-xs font-semibold text-slate-700 mb-1.5">
                      Target platform
                    </h4>
                    <div className="inline-flex items-center gap-2 px-3 py-1.5 rounded-lg bg-slate-100 text-slate-800 text-xs font-medium">
                      {activeStory.platform.includes("Web") ? (
                        <Globe className="w-4 h-4 text-blue-600" />
                      ) : (
                        <Smartphone className="w-4 h-4 text-amber-600" />
                      )}
                      {activeStory.platform}
                    </div>
                  </div>

                  {activeStory.endpoints && activeStory.endpoints.length > 0 && (
                    <div>
                      <h4 className="text-xs font-semibold text-slate-700 mb-1.5 flex items-center justify-between">
                        <span>Backend endpoints (ASP.NET Core 10)</span>
                        <span className="text-[11px] font-normal text-slate-400">
                          Click to inspect specification
                        </span>
                      </h4>
                      <div className="space-y-1.5 font-mono text-xs">
                        {activeStory.endpoints.map((ep, i) => {
                          const { method, path, anchor } = parseEndpointString(ep);
                          const styling = getMethodBadgeClasses(method);

                          return (
                            <Link
                              key={i}
                              to={`/api-spec#${anchor}`}
                              className="p-2.5 rounded-lg bg-slate-900 hover:bg-slate-800 text-slate-200 flex items-center justify-between gap-3 transition-colors group cursor-pointer"
                            >
                              <div className="flex items-center gap-2.5 min-w-0">
                                <span
                                  className={`px-1.5 py-0.5 rounded text-[10px] font-bold border ${styling.badge}`}
                                >
                                  {method}
                                </span>
                                <span className="truncate text-slate-300 group-hover:text-white transition-colors">
                                  {path}
                                </span>
                              </div>
                              <ExternalLink className="w-3.5 h-3.5 text-slate-500 group-hover:text-teal-400 shrink-0 transition-colors" />
                            </Link>
                          );
                        })}
                      </div>
                    </div>
                  )}

                  <div>
                    <h4 className="text-xs font-semibold text-slate-700 mb-1">
                      Clean architecture layering
                    </h4>
                    <p className="text-xs text-slate-600 leading-relaxed">
                      Handled through CQRS MediatR requests in the Application layer, with EF Core entity models persisted to PostgreSQL and audited via domain events.
                    </p>
                  </div>
                </div>
              </div>
            </motion.div>
          )}

          {/* Tab 2: Feature Guide */}
          {activeTab === "guide" && (
            <motion.div
              key="guide"
              id="tabpanel-guide"
              role="tabpanel"
              aria-labelledby="tab-guide"
              initial={{ opacity: 0, y: 6 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.2, ease: "easeOut" }}
            >
              <FeatureGuide
                steps={getFeatureGuide(activeStory.id)}
                storyTitle={activeStory.functionality}
              />
            </motion.div>
          )}
        </div>
      ) : (
        <div className="bg-white p-12 rounded-2xl border border-slate-200/80 text-center space-y-3">
          <Compass className="w-10 h-10 text-slate-300 mx-auto" />
          <p className="text-sm font-semibold text-slate-700">Select a user story from the sidebar</p>
          <p className="text-xs text-slate-400">Choose any item to inspect its demonstration instructions and architecture.</p>
        </div>
      )}
    </div>
  );
}
