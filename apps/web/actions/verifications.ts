"use server";

import { cookies } from "next/headers";
import { revalidatePath } from "next/cache";

const API_URL =
  process.env.API_URL ||
  process.env.NEXT_PUBLIC_API_URL ||
  "http://localhost:5197";

async function getAuthHeader(): Promise<Record<string, string>> {
  const cookieStore = await cookies();
  const token = cookieStore.get("access_token")?.value;
  return token ? { Authorization: `Bearer ${token}` } : {};
}

export interface AdminVerificationDocument {
  documentType: string;
  presignedUrl: string;
}

export interface AdminVerification {
  id: number;
  userId: number;
  userName: string;
  requestedRole: string;
  status: string;
  createdAt: string;
  documents: AdminVerificationDocument[];
}

export interface AdminVerificationListResponse {
  items: AdminVerification[];
  totalCount: number;
}

export async function getVerificationsAction(params: {
  status?: string;
  role?: string;
  page?: number;
  limit?: number;
}): Promise<AdminVerificationListResponse> {
  const authHeader = await getAuthHeader();
  const query = new URLSearchParams();

  if (params.status && params.status !== "All")
    query.set("status", params.status);
  if (params.role && params.role !== "All") query.set("role", params.role);
  if (params.page) query.set("page", params.page.toString());
  if (params.limit) query.set("limit", params.limit.toString());

  const url = `${API_URL}/api/admin/verifications?${query.toString()}`;
  const res = await fetch(url, {
    method: "GET",
    headers: {
      "Content-Type": "application/json",
      ...authHeader,
    },
    next: { revalidate: 0 },
  });

  if (!res.ok) return { items: [], totalCount: 0 };
  const data = await res.json();
  return {
    items: data.items || [],
    totalCount: data.totalCount ?? data.total ?? 0,
  };
}

export async function approveVerificationAction(id: number) {
  const authHeader = await getAuthHeader();
  const res = await fetch(`${API_URL}/api/admin/verifications/${id}/approve`, {
    method: "PUT",
    headers: { ...authHeader },
  });
  if (!res.ok) throw new Error("Failed to approve verification request");
  revalidatePath("/admin/verifications");
  return { success: true };
}

export async function rejectVerificationAction(id: number) {
  const authHeader = await getAuthHeader();
  const res = await fetch(`${API_URL}/api/admin/verifications/${id}/reject`, {
    method: "PUT",
    headers: { ...authHeader },
  });
  if (!res.ok) throw new Error("Failed to reject verification request");
  revalidatePath("/admin/verifications");
  return { success: true };
}
