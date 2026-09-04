"use server";

import { cookies } from "next/headers";

const API_URL =
  process.env.API_URL ||
  process.env.NEXT_PUBLIC_API_URL ||
  "http://localhost:5197";

export interface UserGrowthDataPoint {
  date: string;
  label: string;
  newRegistrations: number;
  totalUsers: number;
}

export interface UserGrowthAnalyticsResponse {
  totalUsers: number;
  newUsersInPeriod: number;
  activeUsersCount: number;
  growthRatePercentage: number;
  timeframe: string;
  frequency: string;
  dataPoints: UserGrowthDataPoint[];
}

export interface RoleCount {
  role: string;
  count: number;
}

export interface RoleDistributionResponse {
  totalRolesAssigned: number;
  roles: RoleCount[];
}

export async function getUserGrowthAnalyticsAction(
  timeframe: string = "30d",
  frequency: string = "daily",
): Promise<UserGrowthAnalyticsResponse> {
  const cookieStore = await cookies();
  const token = cookieStore.get("access_token")?.value;

  const url = `${API_URL}/api/admin/analytics/user-growth?timeframe=${encodeURIComponent(timeframe)}&frequency=${encodeURIComponent(frequency)}`;

  const res = await fetch(url, {
    method: "GET",
    headers: {
      "Content-Type": "application/json",
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    next: { revalidate: 0 },
  });

  if (!res.ok) {
    const errorText = await res.text().catch(() => "");
    throw new Error(
      `Failed to fetch user growth analytics: ${res.status} ${errorText}`,
    );
  }

  return await res.json();
}

export async function getRoleDistributionAction(): Promise<RoleDistributionResponse> {
  const cookieStore = await cookies();
  const token = cookieStore.get("access_token")?.value;

  const url = `${API_URL}/api/admin/analytics/roles-summary`;

  const res = await fetch(url, {
    method: "GET",
    headers: {
      "Content-Type": "application/json",
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    next: { revalidate: 0 },
  });

  if (!res.ok) {
    const errorText = await res.text().catch(() => "");
    throw new Error(
      `Failed to fetch role distribution: ${res.status} ${errorText}`,
    );
  }

  return await res.json();
}
