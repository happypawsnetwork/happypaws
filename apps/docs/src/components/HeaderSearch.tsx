import { useState, useEffect, useRef } from "react";
import { createPortal } from "react-dom";
import { useNavigate } from "react-router";
import { motion, AnimatePresence } from "framer-motion";
import { searchStories, ROLE_CATEGORIES, type UserStory } from "@/data/userStories";
import { IconMap } from "@/components/Icons";
import { Search, CornerDownLeft, X, Sparkles } from "lucide-react";

export function HeaderSearch() {
  const [isOpen, setIsOpen] = useState(false);
  const [query, setQuery] = useState("");
  const [selectedIndex, setSelectedIndex] = useState(0);

  const inputRef = useRef<HTMLInputElement>(null);
  const resultsContainerRef = useRef<HTMLDivElement>(null);
  const navigate = useNavigate();

  // Filter matching roles and stories
  const matchedRoles = ROLE_CATEGORIES.filter((r) =>
    r.name.toLowerCase().includes(query.toLowerCase()) ||
    r.description.toLowerCase().includes(query.toLowerCase()) ||
    r.id.toLowerCase().includes(query.toLowerCase())
  );
  const matchedStories = searchStories(query);

  const displayRoles = query.trim() ? matchedRoles : [];
  const displayStories = query.trim() ? matchedStories : [];

  const totalItemsCount = displayRoles.length + displayStories.length;

  // Open modal handler
  const handleOpenModal = () => {
    setIsOpen(true);
    setSelectedIndex(0);
  };

  // Close modal handler
  const handleCloseModal = () => {
    setIsOpen(false);
    setQuery("");
  };

  // Handle global shortcut (Cmd+K / Ctrl+K)
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === "k") {
        e.preventDefault();
        setIsOpen((prev) => !prev);
      } else if (e.key === "Escape" && isOpen) {
        e.preventDefault();
        handleCloseModal();
      }
    };
    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [isOpen]);

  // Auto focus input when modal opens & lock body scroll
  useEffect(() => {
    if (isOpen) {
      document.body.style.overflow = "hidden";
      const timer = setTimeout(() => {
        inputRef.current?.focus();
      }, 50);
      return () => {
        clearTimeout(timer);
        document.body.style.overflow = "";
      };
    } else {
      document.body.style.overflow = "";
    }
  }, [isOpen]);

  // Navigation handlers
  const handleSelectStory = (story: UserStory) => {
    handleCloseModal();
    navigate(`/stories/${story.role}/${story.id}`);
  };

  const handleSelectRole = (roleId: string) => {
    handleCloseModal();
    navigate(`/stories/${roleId}`);
  };

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (!isOpen) return;

    if (e.key === "ArrowDown") {
      e.preventDefault();
      setSelectedIndex((prev) => (totalItemsCount > 0 ? (prev + 1) % totalItemsCount : 0));
    } else if (e.key === "ArrowUp") {
      e.preventDefault();
      setSelectedIndex((prev) => (totalItemsCount > 0 ? (prev - 1 + totalItemsCount) % totalItemsCount : 0));
    } else if (e.key === "Enter") {
      e.preventDefault();
      if (displayRoles.length > 0 && selectedIndex < displayRoles.length) {
        handleSelectRole(displayRoles[selectedIndex].id);
      } else {
        const storyIdx = selectedIndex - displayRoles.length;
        if (displayStories[storyIdx]) {
          handleSelectStory(displayStories[storyIdx]);
        }
      }
    }
  };

  // Scroll active item into view
  useEffect(() => {
    if (resultsContainerRef.current) {
      const selectedEl = resultsContainerRef.current.querySelector('[data-selected="true"]');
      if (selectedEl) {
        selectedEl.scrollIntoView({ block: "nearest" });
      }
    }
  }, [selectedIndex]);

  return (
    <>
      {/* Trigger Button in Header */}
      <button
        type="button"
        onClick={handleOpenModal}
        className="w-full max-w-xs sm:max-w-sm md:max-w-md flex items-center justify-between gap-3 px-3.5 py-2 rounded-xl bg-slate-100 hover:bg-slate-200/70 border border-slate-200/80 text-slate-500 text-xs md:text-sm font-medium transition cursor-pointer shadow-2xs group"
        aria-label="Search stories, roles, or endpoints"
      >
        <div className="flex items-center gap-2 truncate">
          <Search className="w-4 h-4 text-slate-400 group-hover:text-slate-600 transition" />
          <span className="truncate">Search user stories, roles...</span>
        </div>
        <kbd className="hidden sm:inline-flex items-center gap-0.5 px-1.5 py-0.5 text-[10px] font-mono font-semibold text-slate-400 bg-white border border-slate-200 rounded shadow-2xs">
          ⌘K
        </kbd>
      </button>

      {/* Search Modal Backdrop & Dialog */}
      {typeof document !== "undefined" &&
        createPortal(
          <AnimatePresence>
            {isOpen && (
              <div className="fixed inset-0 z-50 overflow-y-auto p-4 sm:p-6 md:p-20 flex justify-center items-start">
                <motion.div
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                  exit={{ opacity: 0 }}
                  transition={{ duration: 0.15 }}
                  onClick={handleCloseModal}
                  className="fixed inset-0 bg-slate-900/40 backdrop-blur-xs transition-opacity"
                />

                <div className="relative w-full max-w-2xl min-h-[50vh] flex items-center justify-center pointer-events-none">
                  <motion.div
                    initial={{ opacity: 0, scale: 0.97, y: 8 }}
                    animate={{ opacity: 1, scale: 1, y: 0 }}
                    exit={{ opacity: 0, scale: 0.97, y: -8 }}
                    transition={{ type: "spring", bounce: 0, duration: 0.2 }}
                    className="pointer-events-auto w-full max-w-2xl bg-white border border-slate-200/90 rounded-2xl shadow-2xl shadow-slate-950/40 overflow-hidden flex flex-col my-auto max-h-[80vh]"
                    role="dialog"
                    aria-modal="true"
                    aria-label="Search playbook"
                  >
                    {/* Modal Header & Input */}
                    <div className="p-4 border-b border-slate-100 bg-white flex items-center gap-3 shrink-0">
                      <Search className="w-5 h-5 text-slate-400 shrink-0" />
                      <input
                        ref={inputRef}
                        type="text"
                        value={query}
                        onChange={(e) => {
                          setQuery(e.target.value);
                          setSelectedIndex(0);
                        }}
                        onKeyDown={handleKeyDown}
                        placeholder="What are you searching for?"
                        className="w-full text-sm sm:text-base font-medium text-slate-900 placeholder:text-slate-400 bg-transparent outline-none border-none focus:ring-0 p-0"
                      />
                      {query && (
                        <button
                          type="button"
                          onClick={() => {
                            setQuery("");
                            setSelectedIndex(0);
                          }}
                          className="p-1 rounded-full text-slate-400 hover:text-slate-600 hover:bg-slate-100 transition cursor-pointer"
                        >
                          <X className="w-4 h-4" />
                        </button>
                      )}
                      <button
                        type="button"
                        onClick={handleCloseModal}
                        className="hidden sm:inline-flex px-2 py-1 text-xs font-mono font-medium text-slate-400 bg-slate-100 rounded-md hover:text-slate-700 hover:bg-slate-200/80 transition cursor-pointer"
                      >
                        ESC
                      </button>
                    </div>

                    {/* Results / Empty Initial State Container */}
                    <div
                      ref={resultsContainerRef}
                      className="flex-1 overflow-y-auto p-3 space-y-4 min-h-[220px] max-h-[50vh] scroll-smooth bg-white"
                    >
                      {!query.trim() ? (
                        /* Initial Empty Area with Centered Prompt */
                        <div className="py-16 text-center space-y-3 flex flex-col items-center justify-center">
                          <div className="w-12 h-12 rounded-full bg-slate-50 border border-slate-100 flex items-center justify-center text-slate-300">
                            <Search className="w-6 h-6" />
                          </div>
                          <div className="space-y-1">
                            <p className="text-sm font-semibold text-slate-600">
                              Enter text to search
                            </p>
                            <p className="text-xs text-slate-400">
                              Type any feature, user story, or role name to begin searching.
                            </p>
                          </div>
                        </div>
                      ) : totalItemsCount === 0 ? (
                        /* No Matches Found */
                        <div className="py-14 text-center space-y-2">
                          <div className="w-12 h-12 rounded-full bg-slate-50 border border-slate-100 flex items-center justify-center mx-auto text-slate-300">
                            <Search className="w-6 h-6" />
                          </div>
                          <p className="text-sm font-semibold text-slate-700">
                            No results found for "{query}"
                          </p>
                          <p className="text-xs text-slate-400">
                            Try searching for role names, functionality keywords, or platforms (Web, Mobile).
                          </p>
                        </div>
                      ) : (
                        /* Active Search Results */
                        <div className="space-y-3 p-1">
                          {/* Matching Roles Section */}
                          {displayRoles.length > 0 && (
                            <div className="space-y-1.5">
                              <p className="text-[11px] font-semibold tracking-wider uppercase text-slate-400 px-2">
                                User Roles ({displayRoles.length})
                              </p>
                              {displayRoles.map((role, idx) => {
                                const isSelected = idx === selectedIndex;
                                const IconComponent = IconMap[role.iconName] || Sparkles;
                                return (
                                  <div
                                    key={role.id}
                                    data-selected={isSelected}
                                    onClick={() => handleSelectRole(role.id)}
                                    onMouseEnter={() => setSelectedIndex(idx)}
                                    className={`p-3 rounded-xl border transition-all cursor-pointer flex items-center justify-between gap-3 ${
                                      isSelected
                                        ? "bg-teal-50/90 border-teal-300 shadow-2xs"
                                        : "bg-white hover:bg-slate-50 border-slate-200/80"
                                    }`}
                                  >
                                    <div className="flex items-center gap-3 min-w-0">
                                      <div
                                        className={`p-2 rounded-lg shrink-0 ${
                                          isSelected
                                            ? "bg-teal-700 text-white"
                                            : "bg-slate-100 text-slate-600"
                                        }`}
                                      >
                                        <IconComponent className="w-4 h-4" />
                                      </div>
                                      <div className="min-w-0">
                                        <div className="flex items-center gap-2">
                                          <span
                                            className={`text-xs font-bold ${
                                              isSelected ? "text-teal-950" : "text-slate-900"
                                            }`}
                                          >
                                            {role.name}
                                          </span>
                                          <span className="text-[10px] font-mono px-1.5 py-0.2 rounded bg-slate-100 text-slate-500 font-medium">
                                            {role.storiesCount} stories
                                          </span>
                                        </div>
                                        <p className="text-[11px] text-slate-500 truncate mt-0.5">
                                          {role.description}
                                        </p>
                                      </div>
                                    </div>
                                    {isSelected && (
                                      <CornerDownLeft className="w-4 h-4 text-teal-600 shrink-0" />
                                    )}
                                  </div>
                                );
                              })}
                            </div>
                          )}

                          {/* Matching User Stories Section */}
                          {displayStories.length > 0 && (
                            <div className="space-y-1.5">
                              <p className="text-[11px] font-semibold tracking-wider uppercase text-slate-400 px-2">
                                User Stories ({displayStories.length})
                              </p>
                              {displayStories.map((story, idx) => {
                                const itemIndex = displayRoles.length + idx;
                                const isSelected = itemIndex === selectedIndex;
                                const isMobile = story.platform.includes("Mobile");
                                const isWeb = story.platform.includes("Web");

                                return (
                                  <div
                                    key={story.id}
                                    data-selected={isSelected}
                                    onClick={() => handleSelectStory(story)}
                                    onMouseEnter={() => setSelectedIndex(itemIndex)}
                                    className={`p-3 rounded-xl border transition-all cursor-pointer flex items-start justify-between gap-3 ${
                                      isSelected
                                        ? "bg-teal-50/90 border-teal-300 shadow-2xs"
                                        : "bg-white hover:bg-slate-50 border-slate-200/80"
                                    }`}
                                  >
                                    <div className="space-y-1 min-w-0 flex-1">
                                      <div className="flex flex-wrap items-center gap-2">
                                        <span
                                          className={`text-xs font-bold ${
                                            isSelected ? "text-teal-950" : "text-slate-900"
                                          }`}
                                        >
                                          {story.functionality}
                                        </span>
                                        <span className="text-[10px] font-mono px-1.5 py-0.2 rounded uppercase bg-slate-100 text-slate-600 border border-slate-200/70 font-semibold">
                                          {story.id}
                                        </span>
                                        <span className="text-[10px] font-medium capitalize text-teal-700 bg-teal-50 px-2 py-0.2 rounded-full border border-teal-200/50">
                                          {story.role}
                                        </span>
                                      </div>

                                      <p className="text-[11px] text-slate-600 line-clamp-2 leading-relaxed">
                                        {story.userStory}
                                      </p>
                                    </div>

                                    <div className="flex items-center gap-2 shrink-0 pt-0.5">
                                      <span
                                        className={`text-[9px] font-mono uppercase px-1.5 py-0.5 rounded font-semibold ${
                                          isWeb
                                            ? "bg-blue-50 text-blue-700 border border-blue-100"
                                            : isMobile
                                            ? "bg-amber-50 text-amber-700 border border-amber-100"
                                            : "bg-purple-50 text-purple-700 border border-purple-100"
                                        }`}
                                      >
                                        {story.platform.split(" ")[0]}
                                      </span>
                                      {isSelected && (
                                        <CornerDownLeft className="w-4 h-4 text-teal-600" />
                                      )}
                                    </div>
                                  </div>
                                );
                              })}
                            </div>
                          )}
                        </div>
                      )}
                    </div>

                    {/* Modal Footer */}
                    <div className="px-4 py-2.5 border-t border-slate-100 bg-white flex items-center justify-between text-[11px] text-slate-500 shrink-0">
                      <div className="flex items-center gap-3">
                        <span className="flex items-center gap-1">
                          <kbd className="font-mono text-[10px] bg-slate-50 px-1.5 py-0.5 rounded border border-slate-200 shadow-2xs">
                            ↑
                          </kbd>
                          <kbd className="font-mono text-[10px] bg-slate-50 px-1.5 py-0.5 rounded border border-slate-200 shadow-2xs">
                            ↓
                          </kbd>
                          <span className="ml-0.5 text-slate-400">Navigate</span>
                        </span>
                        <span className="flex items-center gap-1">
                          <kbd className="font-mono text-[10px] bg-slate-50 px-1.5 py-0.5 rounded border border-slate-200 shadow-2xs">
                            ↵
                          </kbd>
                          <span className="ml-0.5 text-slate-400">Select</span>
                        </span>
                        <span className="flex items-center gap-1">
                          <kbd className="font-mono text-[10px] bg-slate-50 px-1 py-0.5 rounded border border-slate-200 shadow-2xs">
                            esc
                          </kbd>
                          <span className="ml-0.5 text-slate-400">Close</span>
                        </span>
                      </div>

                      <span className="text-[10px] text-slate-400 font-mono">
                        {query.trim()
                          ? `${totalItemsCount} result${totalItemsCount === 1 ? "" : "s"}`
                          : "Happy Paws Playbook"}
                      </span>
                    </div>
                  </motion.div>
                </div>
              </div>
            )}
          </AnimatePresence>,
          document.body
        )}
    </>
  );
}
