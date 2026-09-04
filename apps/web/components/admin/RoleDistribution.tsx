import React from "react";
import {
  Shield,
  Heart,
  Home,
  Truck,
  Stethoscope,
  Award,
  Users,
} from "lucide-react";
import type { RoleDistributionResponse } from "@/actions/analytics";

interface RoleDistributionProps {
  data?: RoleDistributionResponse;
}

const roleIcons: Record<string, React.ReactNode> = {
  Administrator: <Shield className="w-4 h-4 text-purple-600" />,
  Adopter: <Heart className="w-4 h-4 text-rose-500" />,
  Foster: <Home className="w-4 h-4 text-amber-500" />,
  Transporter: <Truck className="w-4 h-4 text-blue-500" />,
  Veterinarian: <Stethoscope className="w-4 h-4 text-emerald-500" />,
  Sponsor: <Award className="w-4 h-4 text-indigo-500" />,
};

const roleColors: Record<string, string> = {
  Administrator: "bg-purple-50 text-purple-700 border-purple-100",
  Adopter: "bg-rose-50 text-rose-700 border-rose-100",
  Foster: "bg-amber-50 text-amber-700 border-amber-100",
  Transporter: "bg-blue-50 text-blue-700 border-blue-100",
  Veterinarian: "bg-emerald-50 text-emerald-700 border-emerald-100",
  Sponsor: "bg-indigo-50 text-indigo-700 border-indigo-100",
};

export function RoleDistribution({ data }: RoleDistributionProps) {
  const roles = data?.roles ?? [];
  const totalAssigned = data?.totalRolesAssigned ?? 0;

  return (
    <section className="bg-white border border-slate-200/80 rounded-2xl p-6 shadow-xs space-y-6">
      <div className="flex items-center justify-between border-b border-slate-100 pb-4">
        <div>
          <h2 className="text-lg font-bold text-slate-900 font-outfit flex items-center gap-2">
            <Users className="w-5 h-5 text-blue-600" />
            Role distribution
          </h2>
          <p className="text-xs text-slate-500 mt-0.5">
            Real-time breakdown of user roles assigned across the community.
          </p>
        </div>
        <div className="text-right">
          <span className="text-xs font-semibold text-slate-500 uppercase tracking-wider">
            Total role assignments
          </span>
          <p className="text-xl font-bold text-slate-900 font-mono">
            {totalAssigned.toLocaleString()}
          </p>
        </div>
      </div>

      <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-6 gap-3">
        {roles.map((item) => {
          const icon = roleIcons[item.role] || (
            <Users className="w-4 h-4 text-slate-500" />
          );
          const colorClass =
            roleColors[item.role] ||
            "bg-slate-50 text-slate-700 border-slate-100";
          const percentage =
            totalAssigned > 0
              ? Math.round((item.count / totalAssigned) * 100)
              : 0;

          return (
            <div
              key={item.role}
              className={`p-4 rounded-xl border ${colorClass} flex flex-col justify-between transition-all hover:shadow-xs`}
            >
              <div className="flex items-center justify-between">
                <span className="text-xs font-semibold">{item.role}</span>
                {icon}
              </div>
              <div className="mt-4">
                <span className="text-2xl font-bold font-mono">
                  {item.count.toLocaleString()}
                </span>
                <p className="text-[11px] opacity-75 mt-0.5">
                  {percentage}% of assignments
                </p>
              </div>
            </div>
          );
        })}
      </div>
    </section>
  );
}
