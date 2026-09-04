"use server";

import { cookies } from "next/headers";
import { revalidatePath } from "next/cache";

const API_URL =
  process.env.API_URL ||
  process.env.NEXT_PUBLIC_API_URL ||
  "http://localhost:5197";

export interface AdminUserSummary {
  id: number;
  email: string;
  firstName: string;
  lastName: string;
  fullName: string;
  phoneNumber: string | null;
  avatarUrl: string | null;
  reputationPoints: number;
  isActive: boolean;
  isDeleted: boolean;
  roles: string[];
  createdAt: string;
  updatedAt: string;
}

export type AdminUserListItem = AdminUserSummary;

export interface AdminUserStats {
  totalUsers: number;
  activeUsers: number;
  suspendedUsers: number;
  deletedUsers: number;
}

export interface AdminUsersListResponse {
  items: AdminUserSummary[];
  totalCount: number;
  page: number;
  pageSize: number;
  totalPages: number;
  stats: AdminUserStats;
}

export interface AdminUserDetail {
  id: number;
  email: string;
  firstName: string;
  lastName: string;
  fullName: string;
  phoneNumber: string | null;
  avatarUrl: string | null;
  tagline?: string | null;
  reputationPoints: number;
  isActive: boolean;
  isDeleted: boolean;
  roles: { name: string; isVerified: boolean }[];
  activeSessionsCount: number;
  createdAt: string;
  updatedAt: string;
  totalPosts?: number;
}

export interface CreateAdminUserData {
  email: string;
  password: string;
  firstName: string;
  lastName: string;
  phoneNumber?: string;
  roles?: string[];
  initialReputationPoints?: number;
}

async function getAuthHeader(): Promise<Record<string, string>> {
  const cookieStore = await cookies();
  const token = cookieStore.get("access_token")?.value;
  return token ? { Authorization: `Bearer ${token}` } : {};
}

function mapUserSummary(
  u: Omit<AdminUserSummary, "fullName">,
): AdminUserSummary {
  return {
    ...u,
    fullName: `${u.firstName || ""} ${u.lastName || ""}`.trim() || u.email,
  };
}

export async function getUsersAction(params: {
  search?: string;
  role?: string;
  status?: string;
  sortBy?: string;
  page?: number;
  pageSize?: number;
}): Promise<AdminUsersListResponse> {
  const authHeader = await getAuthHeader();
  const query = new URLSearchParams();

  if (params.search) query.set("search", params.search);
  if (params.role) query.set("role", params.role);
  if (params.status) query.set("status", params.status);
  if (params.sortBy) query.set("sortBy", params.sortBy);
  if (params.page) query.set("page", params.page.toString());
  if (params.pageSize) query.set("pageSize", params.pageSize.toString());

  const url = `${API_URL}/api/admin/users?${query.toString()}`;
  const res = await fetch(url, {
    method: "GET",
    headers: {
      "Content-Type": "application/json",
      ...authHeader,
    },
    next: { revalidate: 0 },
  });

  if (!res.ok) {
    const errorText = await res.text().catch(() => "");
    throw new Error(`Failed to fetch users: ${res.status} ${errorText}`);
  }

  const data = await res.json();
  return {
    ...data,
    items: (data.items || []).map(mapUserSummary),
  };
}

export async function getAdminUsersAction(params: {
  page?: number;
  pageSize?: number;
  search?: string;
  role?: string;
  status?: string;
}): Promise<{
  users: AdminUserListItem[];
  totalUsers: number;
  totalPages: number;
  currentPage: number;
}> {
  const res = await getUsersAction(params);
  return {
    users: res.items,
    totalUsers: res.totalCount,
    totalPages: res.totalPages,
    currentPage: res.page,
  };
}

export async function getUserByIdAction(id: number): Promise<AdminUserDetail> {
  const authHeader = await getAuthHeader();
  const res = await fetch(`${API_URL}/api/admin/users/${id}`, {
    method: "GET",
    headers: {
      "Content-Type": "application/json",
      ...authHeader,
    },
    next: { revalidate: 0 },
  });

  if (!res.ok) {
    const errorText = await res.text().catch(() => "");
    throw new Error(`Failed to load user details: ${res.status} ${errorText}`);
  }

  const data = await res.json();
  return {
    ...data,
    fullName:
      `${data.firstName || ""} ${data.lastName || ""}`.trim() || data.email,
  };
}

export async function createUserAction(
  data: CreateAdminUserData,
): Promise<AdminUserDetail> {
  const authHeader = await getAuthHeader();
  const res = await fetch(`${API_URL}/api/admin/users`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      ...authHeader,
    },
    body: JSON.stringify(data),
  });

  if (!res.ok) {
    const errorText = await res.text().catch(() => "");
    throw new Error(errorText || "Failed to create user account.");
  }

  revalidatePath("/admin/users");
  const created = await res.json();
  return {
    ...created,
    fullName:
      `${created.firstName || ""} ${created.lastName || ""}`.trim() ||
      created.email,
  };
}

export async function updateUserStatusAction(
  id: number,
  status: { isActive?: boolean; isDeleted?: boolean },
): Promise<{ success: boolean }> {
  const authHeader = await getAuthHeader();
  const res = await fetch(`${API_URL}/api/admin/users/${id}/status`, {
    method: "PUT",
    headers: {
      "Content-Type": "application/json",
      ...authHeader,
    },
    body: JSON.stringify(status),
  });

  if (!res.ok) {
    const errorText = await res.text().catch(() => "");
    throw new Error(errorText || "Failed to update user status.");
  }

  revalidatePath("/admin/users");
  return { success: true };
}

export async function toggleUserStatusAction(
  userId: number,
  currentStatus: boolean,
): Promise<{ success: boolean }> {
  return await updateUserStatusAction(userId, { isActive: !currentStatus });
}

export async function updateUserRolesAction(
  id: number,
  roles: string[],
): Promise<{ success: boolean }> {
  const authHeader = await getAuthHeader();
  const res = await fetch(`${API_URL}/api/admin/users/${id}/roles`, {
    method: "PUT",
    headers: {
      "Content-Type": "application/json",
      ...authHeader,
    },
    body: JSON.stringify({ roles }),
  });

  if (!res.ok) {
    const errorText = await res.text().catch(() => "");
    throw new Error(errorText || "Failed to update user roles.");
  }

  revalidatePath("/admin/users");
  return { success: true };
}

export async function adjustUserReputationAction(
  id: number,
  pointsDelta: number,
  reason?: string,
): Promise<{ userId: number; reputationPoints: number }> {
  const authHeader = await getAuthHeader();
  const res = await fetch(`${API_URL}/api/admin/users/${id}/reputation`, {
    method: "PUT",
    headers: {
      "Content-Type": "application/json",
      ...authHeader,
    },
    body: JSON.stringify({ pointsDelta, reason }),
  });

  if (!res.ok) {
    const errorText = await res.text().catch(() => "");
    throw new Error(errorText || "Failed to adjust user reputation points.");
  }

  revalidatePath("/admin/users");
  return await res.json();
}

export async function resetUserPasswordAction(
  id: number,
  newPassword: string,
): Promise<{ success: boolean }> {
  const authHeader = await getAuthHeader();
  const res = await fetch(`${API_URL}/api/admin/users/${id}/reset-password`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      ...authHeader,
    },
    body: JSON.stringify({ newPassword }),
  });

  if (!res.ok) {
    const errorText = await res.text().catch(() => "");
    throw new Error(errorText || "Failed to reset user password.");
  }

  return { success: true };
}
