import { useState } from "react";
import { Link, useLocation } from "react-router";
import { motion, AnimatePresence } from "framer-motion";
import logoSvg from "@/assets/logo.svg";
import { ROLE_CATEGORIES, USER_STORIES } from "@/data/userStories";
import { allApiOperations, getMethodBadgeClasses } from "@/data/openApiUtils";
import { API_TOPICS } from "@/data/apiTopics";
import { IconMap } from "@/components/Icons";
import { LayoutDashboard, Users, ChevronDown, Code2, Layers, Clock } from "lucide-react";
import { getStoryStatus } from "@/data/featureGuides";

export function Sidebar() {
  const location = useLocation();

  // Determine active role from pathname
  const currentRoleId = location.pathname.startsWith("/stories/")
    ? location.pathname.split("/")[2]
    : null;

  const currentStoryId = location.pathname.startsWith("/stories/")
    ? location.pathname.split("/")[3]
    : null;

  // Determine active API topic from pathname
  const currentTopicId = location.pathname.startsWith("/api-spec/")
    ? location.pathname.split("/")[2]
    : null;
  const isAllApiSpec = location.pathname === "/api-spec";

  // Track expanded state for each role category
  const [expandedRoles, setExpandedRoles] = useState<Record<string, boolean>>(() => {
    const initial: Record<string, boolean> = {};
    ROLE_CATEGORIES.forEach((cat) => {
      initial[cat.id] = cat.id === currentRoleId;
    });
    return initial;
  });

  // Track expanded state for each API topic
  const [expandedTopics, setExpandedTopics] = useState<Record<string, boolean>>(() => {
    const initial: Record<string, boolean> = {};
    API_TOPICS.forEach((topic) => {
      initial[topic.id] = topic.id === currentTopicId;
    });
    return initial;
  });

  // Auto-expand active role when route changes to a new role category
  const [prevRoleId, setPrevRoleId] = useState(currentRoleId);
  if (currentRoleId !== prevRoleId) {
    setPrevRoleId(currentRoleId);
    if (currentRoleId && !expandedRoles[currentRoleId]) {
      setExpandedRoles((prev) => ({
        ...prev,
        [currentRoleId]: true,
      }));
    }
  }

  // Auto-expand active topic when route changes to a new topic
  const [prevTopicId, setPrevTopicId] = useState(currentTopicId);
  if (currentTopicId !== prevTopicId) {
    setPrevTopicId(currentTopicId);
    if (currentTopicId && !expandedTopics[currentTopicId]) {
      setExpandedTopics((prev) => ({
        ...prev,
        [currentTopicId]: true,
      }));
    }
  }

  return (
    <aside className="w-72 h-screen border-r border-slate-200/80 bg-white/70 backdrop-blur-xl flex flex-col pt-6 pb-4 pl-3.5 pr-0 sticky top-0 shrink-0 z-20 select-none">
      {/* Brand logo */}
      <Link
        to="/"
        className="mb-8 flex items-center justify-start pl-3.5 pr-2 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-teal-500 rounded-xl group"
      >
        <img
          src={logoSvg}
          alt="Happy Paws Playbook Logo"
          className="w-44 h-auto object-contain transition-transform group-hover:scale-[1.01]"
        />
      </Link>

      {/* Navigation links tree */}
      <nav className="flex-1 flex flex-col gap-1.5 overflow-y-auto pr-1">
        {/* Section header for Getting Started */}
        <div className="pb-1.5 pl-3.5 pr-3">
          <p className="text-[11px] font-semibold tracking-wider uppercase text-slate-400">
            Getting Started
          </p>
        </div>

        {/* Project overview item */}
        <Link
          to="/"
          className="relative mr-2 px-3.5 py-2.5 rounded-xl flex items-center gap-3 text-sm font-medium transition-colors outline-none focus-visible:ring-2 focus-visible:ring-teal-500 group"
        >
          {location.pathname === "/" && (
            <motion.div
              layoutId="sidebar-active"
              className="absolute inset-0 bg-teal-50/90 border border-teal-100/80 rounded-xl shadow-xs"
              initial={false}
              transition={{ type: "spring", bounce: 0, duration: 0.35 }}
            />
          )}
          <LayoutDashboard
            className={`w-4 h-4 relative z-10 transition-colors ${
              location.pathname === "/"
                ? "text-teal-600"
                : "text-slate-400 group-hover:text-slate-600"
            }`}
          />
          <span
            className={`relative z-10 transition-colors ${
              location.pathname === "/"
                ? "text-teal-900 font-semibold"
                : "text-slate-600 group-hover:text-slate-900"
            }`}
          >
            Project overview
          </span>
        </Link>

        {/* User roles item */}
        <Link
          to="/user-roles"
          className="relative mr-2 px-3.5 py-2.5 rounded-xl flex items-center gap-3 text-sm font-medium transition-colors outline-none focus-visible:ring-2 focus-visible:ring-teal-500 group"
        >
          {location.pathname === "/user-roles" && (
            <motion.div
              layoutId="sidebar-active"
              className="absolute inset-0 bg-teal-50/90 border border-teal-100/80 rounded-xl shadow-xs"
              initial={false}
              transition={{ type: "spring", bounce: 0, duration: 0.35 }}
            />
          )}
          <Users
            className={`w-4 h-4 relative z-10 transition-colors ${
              location.pathname === "/user-roles"
                ? "text-teal-600"
                : "text-slate-400 group-hover:text-slate-600"
            }`}
          />
          <span
            className={`relative z-10 transition-colors ${
              location.pathname === "/user-roles"
                ? "text-teal-900 font-semibold"
                : "text-slate-600 group-hover:text-slate-900"
            }`}
          >
            User roles
          </span>
        </Link>

        <div className="pt-4 pb-1.5 pl-3.5 pr-3">
          <p className="text-[11px] font-semibold tracking-wider uppercase text-slate-400">
            User Roles & Features
          </p>
        </div>

        {/* Role categories with nested story items */}
        {ROLE_CATEGORIES.map((cat) => {
          const isRoleActive = currentRoleId === cat.id;
          const isCategorySelected = isRoleActive && !currentStoryId;
          const isExpanded = !!expandedRoles[cat.id];
          const IconComponent = IconMap[cat.iconName] || LayoutDashboard;
          const roleStories = USER_STORIES.filter((s) => s.role.toLowerCase() === cat.id);

          return (
            <div key={cat.id} className="flex flex-col gap-1">
              {/* Role Header Button - exact match with apps/web sidebar button layout & height */}
              <Link
                to={`/stories/${cat.id}`}
                onClick={() => {
                  setExpandedRoles((prev) => ({
                    ...prev,
                    [cat.id]: !prev[cat.id],
                  }));
                }}
                className="relative mr-2 px-3.5 py-2.5 rounded-xl flex items-center justify-between gap-3 text-sm font-medium transition-colors outline-none focus-visible:ring-2 focus-visible:ring-teal-500 group cursor-pointer"
              >
                {isCategorySelected && (
                  <motion.div
                    layoutId="sidebar-active"
                    className="absolute inset-0 bg-teal-50/90 border border-teal-100/80 rounded-xl shadow-xs"
                    initial={false}
                    transition={{ type: "spring", bounce: 0, duration: 0.35 }}
                  />
                )}

                <div className="flex items-center gap-3 min-w-0 relative z-10">
                  <IconComponent
                    className={`w-4 h-4 shrink-0 transition-colors ${
                      isCategorySelected
                        ? "text-teal-600"
                        : isRoleActive
                        ? "text-teal-600"
                        : "text-slate-400 group-hover:text-slate-600"
                    }`}
                  />
                  <span
                    className={`transition-colors truncate ${
                      isCategorySelected
                        ? "text-teal-900 font-semibold"
                        : isRoleActive
                        ? "text-teal-900 font-semibold"
                        : "text-slate-600 group-hover:text-slate-900"
                    }`}
                  >
                    {cat.name}
                  </span>
                </div>

                <div className="flex items-center gap-2 shrink-0 relative z-10">
                  <span
                    className={`text-[11px] font-mono px-2 py-0.5 rounded-md font-semibold transition-colors ${
                      isRoleActive
                        ? "bg-teal-100/80 text-teal-800"
                        : "bg-slate-100 text-slate-500 font-medium"
                    }`}
                  >
                    {cat.storiesCount}
                  </span>
                  <ChevronDown
                    className={`w-4 h-4 transition-transform duration-200 ${
                      isExpanded
                        ? "rotate-180 text-teal-600"
                        : "text-slate-400 group-hover:text-slate-600"
                    }`}
                  />
                </div>
              </Link>

              {/* Nested Story Items */}
              <AnimatePresence initial={false}>
                {isExpanded && (
                  <motion.div
                    initial={{ opacity: 0, height: 0 }}
                    animate={{ opacity: 1, height: "auto" }}
                    exit={{ opacity: 0, height: 0 }}
                    transition={{ duration: 0.2 }}
                    className="overflow-hidden pl-3.5 pr-1 py-1.5 flex flex-col gap-1.5 border-l-2 border-slate-100 ml-5 my-1 mr-2"
                  >
                    {roleStories.map((s) => {
                      const isStorySelected = currentStoryId === s.id;
                      const isMobile = s.platform.includes("Mobile");
                      const isWeb = s.platform.includes("Web");
                      const { isPending, reason } = getStoryStatus(s);

                      return (
                        <Link
                          key={s.id}
                          to={`/stories/${cat.id}/${s.id}`}
                          className="relative px-3.5 py-2.5 rounded-xl flex items-center justify-between gap-2.5 text-[13px] font-medium transition-colors outline-none focus-visible:ring-2 focus-visible:ring-teal-500 group"
                        >
                          {isStorySelected && (
                            <motion.div
                              layoutId="sidebar-active"
                              className="absolute inset-0 bg-teal-50/90 border border-teal-100/80 rounded-xl shadow-xs"
                              initial={false}
                              transition={{ type: "spring", bounce: 0, duration: 0.35 }}
                            />
                          )}

                          <span
                            className={`relative z-10 transition-colors truncate ${
                              isStorySelected
                                ? "text-teal-900 font-semibold"
                                : "text-slate-600 group-hover:text-slate-900"
                            }`}
                          >
                            {s.functionality}
                          </span>

                          <div className="flex items-center gap-1.5 shrink-0 relative z-10">
                            {isPending && (
                              <span
                                title={reason}
                                aria-label={reason}
                                className="text-amber-500/90 group-hover:text-amber-600 transition-colors flex items-center"
                              >
                                <Clock className="w-3.5 h-3.5" />
                              </span>
                            )}

                            <span
                              className={`text-[9px] font-mono uppercase px-1.5 py-0.5 rounded font-semibold shrink-0 transition-colors ${
                                isWeb
                                  ? "bg-blue-50 text-blue-700 border border-blue-100"
                                  : isMobile
                                  ? "bg-amber-50 text-amber-700 border border-amber-100"
                                  : "bg-purple-50 text-purple-700 border border-purple-100"
                              }`}
                            >
                              {s.platform.split(" ")[0]}
                            </span>
                          </div>
                        </Link>
                      );
                    })}
                  </motion.div>
                )}
              </AnimatePresence>
            </div>
          );
        })}

        {/* API Specification Section */}
        <div className="pt-4 pb-1.5 pl-3.5 pr-3">
          <p className="text-[11px] font-semibold tracking-wider uppercase text-slate-400">
            API Specification
          </p>
        </div>

        {/* All endpoints overview button */}
        <Link
          to="/api-spec"
          className="relative mr-2 px-3.5 py-2.5 rounded-xl flex items-center justify-between text-sm font-medium transition-colors outline-none focus-visible:ring-2 focus-visible:ring-teal-500 group cursor-pointer"
        >
          {isAllApiSpec && (
            <motion.div
              layoutId="sidebar-active"
              className="absolute inset-0 bg-teal-50/90 border border-teal-100/80 rounded-xl shadow-xs"
              initial={false}
              transition={{ type: "spring", bounce: 0, duration: 0.35 }}
            />
          )}

          <div className="flex items-center gap-3 min-w-0 relative z-10">
            <Layers
              className={`w-4 h-4 shrink-0 transition-colors ${
                isAllApiSpec
                  ? "text-teal-600"
                  : "text-slate-400 group-hover:text-slate-600"
              }`}
            />
            <span
              className={`transition-colors truncate ${
                isAllApiSpec
                  ? "text-teal-900 font-semibold"
                  : "text-slate-600 group-hover:text-slate-900"
              }`}
            >
              All endpoints
            </span>
          </div>

          <span
            className={`text-[11px] font-mono px-2 py-0.5 rounded-md font-semibold shrink-0 relative z-10 transition-colors ${
              isAllApiSpec
                ? "bg-teal-100/80 text-teal-800"
                : "bg-slate-100 text-slate-500 font-medium"
            }`}
          >
            {allApiOperations.length}
          </span>
        </Link>

        {/* Individual API topic buttons matching User Roles & Features */}
        {API_TOPICS.map((topic) => {
          const isTopicActive = currentTopicId === topic.id;
          const isExpanded = !!expandedTopics[topic.id];
          const IconComponent = IconMap[topic.iconName] || Code2;

          return (
            <div key={topic.id} className="flex flex-col gap-1">
              {/* Topic Header Button */}
              <Link
                to={`/api-spec/${topic.id}`}
                onClick={() => {
                  setExpandedTopics((prev) => ({
                    ...prev,
                    [topic.id]: !prev[topic.id],
                  }));
                }}
                className="relative mr-2 px-3.5 py-2.5 rounded-xl flex items-center justify-between gap-3 text-sm font-medium transition-colors outline-none focus-visible:ring-2 focus-visible:ring-teal-500 group cursor-pointer"
              >
                {isTopicActive && (
                  <motion.div
                    layoutId="sidebar-active"
                    className="absolute inset-0 bg-teal-50/90 border border-teal-100/80 rounded-xl shadow-xs"
                    initial={false}
                    transition={{ type: "spring", bounce: 0, duration: 0.35 }}
                  />
                )}

                <div className="flex items-center gap-3 min-w-0 relative z-10">
                  <IconComponent
                    className={`w-4 h-4 shrink-0 transition-colors ${
                      isTopicActive
                        ? "text-teal-600"
                        : "text-slate-400 group-hover:text-slate-600"
                    }`}
                  />
                  <span
                    className={`transition-colors truncate ${
                      isTopicActive
                        ? "text-teal-900 font-semibold"
                        : "text-slate-600 group-hover:text-slate-900"
                    }`}
                  >
                    {topic.name}
                  </span>
                </div>

                <div className="flex items-center gap-2 shrink-0 relative z-10">
                  <span
                    className={`text-[11px] font-mono px-2 py-0.5 rounded-md font-semibold transition-colors ${
                      isTopicActive
                        ? "bg-teal-100/80 text-teal-800"
                        : "bg-slate-100 text-slate-500 font-medium"
                    }`}
                  >
                    {topic.endpointCount}
                  </span>
                  <ChevronDown
                    className={`w-4 h-4 transition-transform duration-200 ${
                      isExpanded
                        ? "rotate-180 text-teal-600"
                        : "text-slate-400 group-hover:text-slate-600"
                    }`}
                  />
                </div>
              </Link>

              {/* Nested Endpoint Items */}
              <AnimatePresence initial={false}>
                {isExpanded && (
                  <motion.div
                    initial={{ opacity: 0, height: 0 }}
                    animate={{ opacity: 1, height: "auto" }}
                    exit={{ opacity: 0, height: 0 }}
                    transition={{ duration: 0.2 }}
                    className="overflow-hidden pl-3.5 pr-1 py-1.5 flex flex-col gap-1.5 border-l-2 border-slate-100 ml-5 my-1 mr-2"
                  >
                    {topic.endpoints.map((ep) => {
                      const styling = getMethodBadgeClasses(ep.method);
                      const isEndpointActive =
                        isTopicActive &&
                        location.hash.replace(/^#/, "").toLowerCase() === ep.id.toLowerCase();

                      return (
                        <Link
                          key={ep.id}
                          to={`/api-spec/${topic.id}#${ep.id}`}
                          className="relative px-3 py-2 rounded-xl flex items-center justify-between gap-2 text-[12px] font-medium transition-colors outline-none focus-visible:ring-2 focus-visible:ring-teal-500 group"
                        >
                          {isEndpointActive && (
                            <motion.div
                              layoutId="sidebar-active-endpoint"
                              className="absolute inset-0 bg-teal-50/90 border border-teal-100/80 rounded-xl shadow-xs"
                              initial={false}
                              transition={{ type: "spring", bounce: 0, duration: 0.35 }}
                            />
                          )}

                          <span
                            className={`relative z-10 transition-colors truncate font-sans ${
                              isEndpointActive
                                ? "text-teal-900 font-semibold"
                                : "text-slate-600 group-hover:text-slate-900"
                            }`}
                            title={ep.summary || ep.path}
                          >
                            {ep.summary || ep.path}
                          </span>

                          <span
                            className={`relative z-10 text-[9px] font-mono font-bold px-1.5 py-0.5 rounded border shrink-0 ${styling.badge}`}
                          >
                            {ep.method}
                          </span>
                        </Link>
                      );
                    })}
                  </motion.div>
                )}
              </AnimatePresence>
            </div>
          );
        })}
      </nav>
    </aside>
  );
}
