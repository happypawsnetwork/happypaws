import { Outlet } from "react-router";
import { Sidebar } from "@/components/Sidebar";
import { HeaderSearch } from "@/components/HeaderSearch";
import { Breadcrumbs } from "@/components/Breadcrumbs";

export function RootLayout() {
  return (
    <div className="min-h-screen bg-slate-50/50 flex">
      {/* Admin styled frosted glass sidebar */}
      <Sidebar />

      {/* Main content view */}
      <main className="flex-1 min-w-0 flex flex-col h-screen overflow-y-auto">
        {/* Top header bar with Apple Design aesthetic and increased height */}
        <header className="h-20 border-b border-slate-200/80 bg-white/70 backdrop-blur-xl px-6 md:px-8 flex items-center justify-between gap-6 sticky top-0 z-30 shrink-0">
          {/* Leftmost Breadcrumb Navigation */}
          <div className="flex items-center shrink-0">
            <Breadcrumbs />
          </div>

          {/* Rightmost Search Bar */}
          <div className="flex items-center shrink-0 ml-auto">
            <HeaderSearch />
          </div>
        </header>

        {/* Page content */}
        <div className="flex-1 p-6 md:p-8 max-w-7xl w-full mx-auto">
          <Outlet />
        </div>
      </main>
    </div>
  );
}
