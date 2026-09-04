"use client";

import React, { useState, useTransition, useEffect } from "react";
import {
  ResponsiveContainer,
  ComposedChart,
  Bar,
  Area,
  XAxis,
  YAxis,
  Tooltip,
  CartesianGrid,
} from "recharts";
import {
  Users,
  UserPlus,
  UserCheck,
  TrendingUp,
  Calendar,
  Layers,
  ArrowUpRight,
} from "lucide-react";
import {
  getUserGrowthAnalyticsAction,
  UserGrowthAnalyticsResponse,
} from "@/actions/analytics";

interface UserGrowthChartProps {
  initialData?: UserGrowthAnalyticsResponse;
}

const timeframeOptions = [
  { label: "7D", value: "7d" },
  { label: "30D", value: "30d" },
  { label: "90D", value: "90d" },
  { label: "1Y", value: "1y" },
  { label: "All", value: "all" },
];

const frequencyOptions = [
  { label: "Daily", value: "daily" },
  { label: "Weekly", value: "weekly" },
  { label: "Monthly", value: "monthly" },
];

interface TooltipPayloadItem {
  color?: string;
  fill?: string;
  name?: string;
  value: number;
}

interface CustomTooltipProps {
  active?: boolean;
  payload?: TooltipPayloadItem[];
  label?: string;
}

function CustomTooltip({ active, payload, label }: CustomTooltipProps) {
  if (active && payload && payload.length) {
    return (
      <div className="bg-white/95 backdrop-blur-md border border-slate-200/90 p-3.5 rounded-xl shadow-lg text-xs space-y-2 min-w-[170px]">
        <p className="font-semibold text-slate-800 border-b border-slate-100 pb-1.5 flex items-center justify-between">
          <span>{label}</span>
          <Calendar className="w-3.5 h-3.5 text-slate-400" />
        </p>
        {payload.map((entry, index: number) => (
          <div
            key={`item-${index}`}
            className="flex items-center justify-between gap-3"
          >
            <div className="flex items-center gap-1.5">
              <span
                className="w-2.5 h-2.5 rounded-full"
                style={{ backgroundColor: entry.color || entry.fill }}
              />
              <span className="text-slate-600 font-medium">{entry.name}:</span>
            </div>
            <span className="font-bold text-slate-900 font-mono">
              {entry.value.toLocaleString()}
            </span>
          </div>
        ))}
      </div>
    );
  }
  return null;
}

export function UserGrowthChart({ initialData }: UserGrowthChartProps) {
  const [data, setData] = useState<UserGrowthAnalyticsResponse | undefined>(
    initialData,
  );
  const [timeframe, setTimeframe] = useState<string>("30d");
  const [frequency, setFrequency] = useState<string>("daily");
  const [isPending, startTransition] = useTransition();

  const fetchAnalytics = React.useCallback((tf: string, freq: string) => {
    startTransition(async () => {
      try {
        const res = await getUserGrowthAnalyticsAction(tf, freq);
        setData(res);
      } catch (err) {
        console.error("Failed to load user growth analytics:", err);
      }
    });
  }, []);

  useEffect(() => {
    if (!initialData) {
      fetchAnalytics(timeframe, frequency);
    }
  }, [fetchAnalytics, initialData, timeframe, frequency]);

  const handleTimeframeChange = (newTf: string) => {
    setTimeframe(newTf);
    let autoFreq = frequency;
    if ((newTf === "1y" || newTf === "all") && frequency === "daily") {
      autoFreq = "monthly";
      setFrequency("monthly");
    } else if (newTf === "90d" && frequency === "daily") {
      autoFreq = "weekly";
      setFrequency("weekly");
    } else if ((newTf === "7d" || newTf === "30d") && frequency === "monthly") {
      autoFreq = "daily";
      setFrequency("daily");
    }
    fetchAnalytics(newTf, autoFreq);
  };

  const handleFrequencyChange = (newFreq: string) => {
    setFrequency(newFreq);
    fetchAnalytics(timeframe, newFreq);
  };

  const totalUsers = data?.totalUsers ?? 0;
  const newUsersInPeriod = data?.newUsersInPeriod ?? 0;
  const activeUsersCount = data?.activeUsersCount ?? 0;
  const growthRate = data?.growthRatePercentage ?? 0;
  const activePercentage =
    totalUsers > 0 ? Math.round((activeUsersCount / totalUsers) * 100) : 0;

  return (
    <div className="space-y-6">
      {/* KPI Cards Summary */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="bg-white border border-slate-200/80 rounded-2xl p-5 shadow-xs relative overflow-hidden">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold text-slate-500 uppercase tracking-wider">
              Total users
            </span>
            <div className="w-9 h-9 rounded-xl bg-blue-50 text-blue-600 flex items-center justify-center">
              <Users className="w-5 h-5" />
            </div>
          </div>
          <div className="mt-3 flex items-baseline justify-between">
            <span className="text-2xl font-bold text-slate-900 tracking-tight">
              {totalUsers.toLocaleString()}
            </span>
            <span className="inline-flex items-center gap-0.5 px-2 py-0.5 rounded-full text-xs font-semibold bg-emerald-50 text-emerald-700 border border-emerald-100">
              <ArrowUpRight className="w-3.5 h-3.5" />+{growthRate}%
            </span>
          </div>
          <p className="mt-1 text-xs text-slate-500">
            Cumulative platform scale
          </p>
        </div>

        <div className="bg-white border border-slate-200/80 rounded-2xl p-5 shadow-xs">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold text-slate-500 uppercase tracking-wider">
              New signups
            </span>
            <div className="w-9 h-9 rounded-xl bg-sky-50 text-sky-600 flex items-center justify-center">
              <UserPlus className="w-5 h-5" />
            </div>
          </div>
          <div className="mt-3 flex items-baseline justify-between">
            <span className="text-2xl font-bold text-slate-900 tracking-tight">
              {newUsersInPeriod.toLocaleString()}
            </span>
            <span className="text-xs text-slate-500 font-medium">
              In selected period
            </span>
          </div>
          <p className="mt-1 text-xs text-slate-500">New user registrations</p>
        </div>

        <div className="bg-white border border-slate-200/80 rounded-2xl p-5 shadow-xs">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold text-slate-500 uppercase tracking-wider">
              Active users
            </span>
            <div className="w-9 h-9 rounded-xl bg-emerald-50 text-emerald-600 flex items-center justify-center">
              <UserCheck className="w-5 h-5" />
            </div>
          </div>
          <div className="mt-3 flex items-baseline justify-between">
            <span className="text-2xl font-bold text-slate-900 tracking-tight">
              {activeUsersCount.toLocaleString()}
            </span>
            <span className="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-semibold bg-emerald-50 text-emerald-700">
              {activePercentage}% rate
            </span>
          </div>
          <p className="mt-1 text-xs text-slate-500">
            Verified active accounts
          </p>
        </div>

        <div className="bg-white border border-slate-200/80 rounded-2xl p-5 shadow-xs">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold text-slate-500 uppercase tracking-wider">
              Registration pace
            </span>
            <div className="w-9 h-9 rounded-xl bg-indigo-50 text-indigo-600 flex items-center justify-center">
              <TrendingUp className="w-5 h-5" />
            </div>
          </div>
          <div className="mt-3 flex items-baseline justify-between">
            <span className="text-2xl font-bold text-slate-900 tracking-tight">
              {data?.dataPoints && data.dataPoints.length > 0
                ? Math.round(newUsersInPeriod / data.dataPoints.length)
                : 0}
            </span>
            <span className="text-xs text-slate-500 font-medium">
              Avg /{" "}
              {frequency === "daily"
                ? "day"
                : frequency === "weekly"
                  ? "week"
                  : "month"}
            </span>
          </div>
          <p className="mt-1 text-xs text-slate-500">
            Average registration velocity
          </p>
        </div>
      </div>

      {/* Main Dual-Axis Chart Card */}
      <div className="bg-white border border-slate-200/80 rounded-2xl p-6 shadow-xs space-y-6">
        {/* Controls Header */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 border-b border-slate-100 pb-5">
          <div>
            <h2 className="text-lg font-bold text-slate-900 font-outfit flex items-center gap-2">
              User growth and scale trend
              {isPending && (
                <span className="inline-block w-2 h-2 rounded-full bg-blue-600 animate-ping" />
              )}
            </h2>
            <p className="text-xs text-slate-500 mt-0.5">
              Dual-axis view comparing new user signups against total cumulative
              community size.
            </p>
          </div>

          <div className="flex flex-wrap items-center gap-3">
            {/* Timeframe selector */}
            <div className="flex items-center bg-slate-100/80 p-1 rounded-xl border border-slate-200/60">
              {timeframeOptions.map((option) => (
                <button
                  key={option.value}
                  onClick={() => handleTimeframeChange(option.value)}
                  className={`px-2.5 py-1 text-xs font-semibold rounded-lg transition-all ${
                    timeframe === option.value
                      ? "bg-white text-blue-900 shadow-xs border border-slate-200/80"
                      : "text-slate-600 hover:text-slate-900"
                  }`}
                >
                  {option.label}
                </button>
              ))}
            </div>

            {/* Frequency selector */}
            <div className="flex items-center bg-slate-100/80 p-1 rounded-xl border border-slate-200/60">
              <Layers className="w-3.5 h-3.5 text-slate-400 ml-1.5 mr-0.5" />
              {frequencyOptions.map((option) => (
                <button
                  key={option.value}
                  onClick={() => handleFrequencyChange(option.value)}
                  className={`px-2.5 py-1 text-xs font-semibold rounded-lg transition-all ${
                    frequency === option.value
                      ? "bg-white text-blue-900 shadow-xs border border-slate-200/80"
                      : "text-slate-600 hover:text-slate-900"
                  }`}
                >
                  {option.label}
                </button>
              ))}
            </div>
          </div>
        </div>

        {/* Legend Indicator */}
        <div className="flex items-center justify-end gap-6 text-xs font-medium text-slate-600">
          <div className="flex items-center gap-2">
            <span className="w-3 h-3 rounded-sm bg-blue-500 inline-block" />
            <span>New registrations (Left axis)</span>
          </div>
          <div className="flex items-center gap-2">
            <span className="w-3 h-0.5 bg-indigo-700 rounded-full inline-block" />
            <span>Total users (Right axis)</span>
          </div>
        </div>

        {/* Recharts Render Container */}
        <div className="w-full h-80 pt-2">
          {!data ? (
            <div className="w-full h-full flex items-center justify-center bg-slate-50/50 rounded-xl border border-dashed border-slate-200">
              <div className="animate-pulse flex flex-col items-center gap-2 text-slate-400">
                <Users className="w-8 h-8" />
                <span className="text-xs font-medium">
                  Loading user growth analytics...
                </span>
              </div>
            </div>
          ) : (
            <ResponsiveContainer width="100%" height="100%">
              <ComposedChart
                data={data.dataPoints}
                margin={{ top: 10, right: 10, left: -10, bottom: 0 }}
              >
                <defs>
                  <linearGradient
                    id="totalUsersAreaGradient"
                    x1="0"
                    y1="0"
                    x2="0"
                    y2="1"
                  >
                    <stop offset="5%" stopColor="#4f46e5" stopOpacity={0.15} />
                    <stop offset="95%" stopColor="#4f46e5" stopOpacity={0.0} />
                  </linearGradient>
                  <linearGradient id="barGradient" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="0%" stopColor="#3b82f6" />
                    <stop offset="100%" stopColor="#2563eb" />
                  </linearGradient>
                </defs>
                <CartesianGrid
                  strokeDasharray="3 3"
                  vertical={false}
                  stroke="#f1f5f9"
                />
                <XAxis
                  dataKey="label"
                  tickLine={false}
                  axisLine={{ stroke: "#e2e8f0" }}
                  tick={{ fontSize: 11, fill: "#64748b" }}
                  dy={5}
                />
                <YAxis
                  yAxisId="left"
                  orientation="left"
                  tickLine={false}
                  axisLine={false}
                  tick={{ fontSize: 11, fill: "#64748b" }}
                  allowDecimals={false}
                />
                <YAxis
                  yAxisId="right"
                  orientation="right"
                  tickLine={false}
                  axisLine={false}
                  tick={{ fontSize: 11, fill: "#64748b" }}
                  allowDecimals={false}
                />
                <Tooltip content={<CustomTooltip />} />
                <Bar
                  yAxisId="left"
                  dataKey="newRegistrations"
                  name="New registrations"
                  fill="url(#barGradient)"
                  radius={[4, 4, 0, 0]}
                  maxBarSize={28}
                />
                <Area
                  yAxisId="right"
                  type="monotone"
                  dataKey="totalUsers"
                  name="Total users"
                  fill="url(#totalUsersAreaGradient)"
                  stroke="#4f46e5"
                  strokeWidth={2.5}
                  dot={false}
                  activeDot={{
                    r: 6,
                    fill: "#4f46e5",
                    stroke: "#ffffff",
                    strokeWidth: 2,
                  }}
                />
              </ComposedChart>
            </ResponsiveContainer>
          )}
        </div>
      </div>
    </div>
  );
}
