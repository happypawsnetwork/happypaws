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

const TYPE_MAP: Record<string, string> = {
  Rescue: "RescueAlert",
  Update: "FosterUpdate",
  "Find Home": "AdoptionListing",
  Highlight: "Highlight",
  Transport: "TransportRequest",
  Treatment: "VetRequest",
  Sponsor: "SponsorshipRequest",
};

export interface AdminCommunityPost {
  id: string;
  type: string;
  status: string;
  title: string;
  body: string;
  likeCount: number;
  authorDisplayName: string;
  authorEmail?: string;
  authorId: number;
  authorAvatarUrl?: string;
  locationLabel?: string;
  latitude?: number;
  longitude?: number;
  animalSpecies?: string;
  animalName?: string;
  firstPhotoUrl?: string;
  photoCount: number;
  photoUrls: string[];
  urgencyLevel?: string;
  aiTriageReason?: string;
  isUrgencyManuallyOverridden: boolean;
  isDeleted: boolean;
  createdAt: string;
  updatedAt: string;
}

export async function getCommunityPostsAction(params: {
  type?: string;
  status?: string;
  search?: string;
  includeDeleted?: boolean;
}) {
  const authHeader = await getAuthHeader();
  const query = new URLSearchParams();

  if (params.type && params.type !== "All") {
    const mappedType = TYPE_MAP[params.type] || params.type;
    query.set("type", mappedType);
  }
  if (params.status && params.status !== "All") {
    query.set("status", params.status);
  }
  if (params.search) {
    query.set("search", params.search);
  }
  if (params.includeDeleted) {
    query.set("includeDeleted", "true");
  }

  const url = `${API_URL}/api/v1/admin/posts?${query.toString()}`;
  const res = await fetch(url, {
    method: "GET",
    headers: {
      "Content-Type": "application/json",
      ...authHeader,
    },
    next: { revalidate: 0 },
  });

  if (!res.ok) return { items: [] };
  const data = await res.json();
  const items: AdminCommunityPost[] = Array.isArray(data)
    ? data
    : data.items || [];
  return { items };
}

export async function deletePostAction(id: string) {
  const authHeader = await getAuthHeader();
  const res = await fetch(`${API_URL}/api/v1/community/posts/${id}`, {
    method: "DELETE",
    headers: { ...authHeader },
  });
  if (!res.ok) throw new Error("Failed to delete post");
  revalidatePath("/admin/community");
  return { success: true };
}

export async function restorePostAction(id: string) {
  const authHeader = await getAuthHeader();
  const res = await fetch(`${API_URL}/api/v1/admin/posts/${id}/restore`, {
    method: "POST",
    headers: { ...authHeader },
  });
  if (!res.ok) throw new Error("Failed to restore post");
  revalidatePath("/admin/community");
  return { success: true };
}

export async function permanentDeletePostAction(id: string) {
  const authHeader = await getAuthHeader();
  const res = await fetch(`${API_URL}/api/v1/admin/posts/${id}/permanent`, {
    method: "DELETE",
    headers: { ...authHeader },
  });
  if (!res.ok) throw new Error("Failed to permanently delete post");
  revalidatePath("/admin/community");
  return { success: true };
}

export interface AdminRescueCase {
  id: string;
  title: string;
  status: string;
  animalName?: string;
  animalSpecies?: string;
  urgencyLevel?: string;
  aiTriageReason?: string;
  isUrgencyManuallyOverridden: boolean;
  authorName: string;
  authorEmail?: string;
  authorId: number;
  createdAt: string;
  summary: {
    applicationId?: string;
    animalName?: string;
    animalSpecies?: string;
    assignedRescuerName?: string;
    assignedRescuerRole?: string;
    hasVehicle: boolean;
    dateApproved?: string;
  };
}

export async function getAdminRescuesAction() {
  const authHeader = await getAuthHeader();
  const res = await fetch(`${API_URL}/api/v1/admin/rescues`, {
    method: "GET",
    headers: {
      "Content-Type": "application/json",
      ...authHeader,
    },
    next: { revalidate: 0 },
  });

  if (!res.ok) return { items: [] };
  const data = await res.json();
  const items: AdminRescueCase[] = Array.isArray(data)
    ? data
    : data.items || [];
  return { items };
}

export async function overrideRescueAction(
  postId: string,
  applicationId: string,
) {
  const authHeader = await getAuthHeader();
  const res = await fetch(
    `${API_URL}/api/v1/community/posts/${postId}/rescue-applications/${applicationId}/admin-override`,
    {
      method: "POST",
      headers: { ...authHeader },
    },
  );
  if (!res.ok) throw new Error("Failed to override rescue");
  revalidatePath("/admin/rescues");
  return { success: true };
}

export async function getTransportsAction(params: { status?: string }) {
  const authHeader = await getAuthHeader();
  const query = new URLSearchParams();
  if (params.status && params.status !== "All")
    query.set("status", params.status);
  const res = await fetch(
    `${API_URL}/api/v1/community/transport-tasks/admin?${query.toString()}`,
    {
      method: "GET",
      headers: { ...authHeader },
      next: { revalidate: 0 },
    },
  );
  if (!res.ok) return { items: [] };
  const data = await res.json();
  const items = Array.isArray(data) ? data : data.items || [];
  return { items };
}

export interface AdminSponsorshipDetails {
  goalDescription?: string;
  estimatedAmountLkr?: number;
  adminRejectionNotes?: string | null;
  fundedAt?: string | null;
  proofDocumentsCount?: number;
}

export interface AdminSponsorshipItem {
  id: string;
  title: string;
  body?: string;
  authorDisplayName?: string;
  authorName?: string;
  author?: { name?: string };
  sponsorshipDetails?: AdminSponsorshipDetails | null;
  goalDescription?: string;
  estimatedAmount?: number;
  photoCount?: number;
  media?: Array<{ id?: string; cdnUrl?: string }>;
  proofDocumentsCount?: number;
  submittedAt?: string;
  createdAt?: string;
}

export async function getSponsorshipsAction(params: {
  status?: string;
}): Promise<{ items: AdminSponsorshipItem[] }> {
  const authHeader = await getAuthHeader();
  const query = new URLSearchParams();
  if (params.status && params.status !== "All")
    query.set("status", params.status);
  const res = await fetch(
    `${API_URL}/api/v1/community/sponsorships/admin?${query.toString()}`,
    {
      method: "GET",
      headers: { ...authHeader },
      next: { revalidate: 0 },
    },
  );
  if (!res.ok) return { items: [] };
  const data = await res.json();
  const items: AdminSponsorshipItem[] = Array.isArray(data)
    ? data
    : data.items || [];
  return { items };
}

export async function reviewSponsorshipAction(
  id: string,
  approved: boolean,
  rejectionNotes?: string,
) {
  const authHeader = await getAuthHeader();
  const res = await fetch(
    `${API_URL}/api/v1/community/sponsorships/${id}/admin-review`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json", ...authHeader },
      body: JSON.stringify({ approved, rejectionNotes }),
    },
  );
  if (!res.ok) throw new Error("Failed to review sponsorship");
  revalidatePath("/admin/sponsorships");
  return { success: true };
}

export async function getSponsorshipDocsAction(id: string) {
  const authHeader = await getAuthHeader();
  const res = await fetch(
    `${API_URL}/api/v1/community/sponsorships/${id}/proof-documents`,
    {
      method: "GET",
      headers: { ...authHeader },
      next: { revalidate: 0 },
    },
  );
  if (!res.ok) return { items: [] };
  const data = await res.json();
  const items = Array.isArray(data) ? data : data.items || [];
  return { items };
}

export async function updateRescueUrgencyAction(
  postId: string,
  urgencyLevel: string,
) {
  const authHeader = await getAuthHeader();
  const res = await fetch(`${API_URL}/api/v1/admin/rescues/${postId}/urgency`, {
    method: "PATCH",
    headers: { "Content-Type": "application/json", ...authHeader },
    body: JSON.stringify({ urgencyLevel }),
  });
  if (!res.ok) throw new Error("Failed to update rescue urgency");
  revalidatePath("/admin/rescues");
  return { success: true };
}

export async function approvePostAction(postId: string) {
  const authHeader = await getAuthHeader();
  const res = await fetch(`${API_URL}/api/v1/admin/posts/${postId}/approve`, {
    method: "PATCH",
    headers: { ...authHeader },
  });
  if (!res.ok) throw new Error("Failed to approve post");
  revalidatePath("/admin/approvals");
  return { success: true };
}

export async function rejectPostAction(postId: string) {
  const authHeader = await getAuthHeader();
  const res = await fetch(`${API_URL}/api/v1/admin/posts/${postId}/reject`, {
    method: "PATCH",
    headers: { ...authHeader },
  });
  if (!res.ok) throw new Error("Failed to reject post");
  revalidatePath("/admin/approvals");
  return { success: true };
}
