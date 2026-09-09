import { Link } from "react-router";
import { ROLE_CATEGORIES } from "@/data/userStories";
import { IconMap } from "@/components/Icons";
import { Layers, ArrowRight } from "lucide-react";

export function UserRolesPage() {
  return (
    <div className="space-y-8 animate-in fade-in duration-300">
      {/* Page Header */}
      <div className="space-y-2 border-b border-slate-200/80 pb-6">
        <h1 className="text-2xl md:text-3xl font-bold text-slate-900 tracking-tight">
          User roles
        </h1>
        <p className="text-sm text-slate-500 max-w-2xl">
          Select any role to view its feature breakdown, user stories, and demonstration instructions.
        </p>
      </div>

      {/* Role Cards Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
        {ROLE_CATEGORIES.map((role) => {
          const IconComponent = IconMap[role.iconName] || Layers;

          return (
            <Link
              key={role.id}
              to={`/stories/${role.id}`}
              className="group relative p-6 rounded-2xl bg-white border border-slate-200/80 shadow-2xs hover:shadow-md hover:border-teal-500/40 transition-all flex flex-col justify-between overflow-hidden"
            >
              <div className="space-y-3">
                <div className="w-10 h-10 rounded-xl bg-teal-50 border border-teal-100/80 flex items-center justify-center text-teal-700 group-hover:scale-105 transition-transform">
                  <IconComponent className="w-5 h-5" />
                </div>

                <div>
                  <h3 className="text-base font-bold text-slate-900 group-hover:text-teal-700 transition-colors flex items-center justify-between">
                    {role.name}
                    <ArrowRight className="w-4 h-4 text-slate-300 group-hover:text-teal-600 group-hover:translate-x-1 transition-all" />
                  </h3>
                  <p className="text-xs text-slate-500 mt-1 line-clamp-2 leading-relaxed">
                    {role.description}
                  </p>
                </div>
              </div>

              <div className="mt-5 pt-4 border-t border-slate-100 flex items-center justify-between text-xs text-slate-500">
                <span className="font-semibold text-slate-800">{role.storiesCount} user stories</span>
                <span className="text-teal-600 font-medium">Open role &rarr;</span>
              </div>
            </Link>
          );
        })}
      </div>
    </div>
  );
}
