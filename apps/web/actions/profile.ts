"use server";

import { cookies } from "next/headers";
import { revalidatePath } from "next/cache";

const API_URL =
  process.env.API_URL ||
  process.env.NEXT_PUBLIC_API_URL ||
  "http://localhost:5197";

export interface UserProfile {
  id: number;
  email: string;
  firstName: string;
  lastName: string;
  fullName: string;
  phoneNumber: string | null;
  avatarUrl: string | null;
  tagline: string | null;
  reputationPoints: number;
  roles: string[];
  createdAt: string;
  updatedAt: string;
}

export interface UserSession {
  id: string;
  createdAt: string;
  expiresAt: string;
  ipAddress: string;
  isActive: boolean;
}

async function getAuthHeader(): Promise<Record<string, string>> {
  const cookieStore = await cookies();
  const token = cookieStore.get("access_token")?.value;
  return token ? { Authorization: `Bearer ${token}` } : {};
}

export async function getProfileAction(): Promise<UserProfile> {
  const authHeader = await getAuthHeader();
  const res = await fetch(`${API_URL}/api/profile`, {
    method: "GET",
    headers: {
      "Content-Type": "application/json",
      ...authHeader,
    },
    next: { revalidate: 0 },
  });

  if (!res.ok) {
    const errorText = await res.text().catch(() => "");
    throw new Error(`Failed to load profile: ${res.status} ${errorText}`);
  }

  return await res.json();
}

export async function updateProfileAction(data: {
  firstName?: string;
  lastName?: string;
  phoneNumber?: string | null;
  tagline?: string | null;
}): Promise<UserProfile> {
  const authHeader = await getAuthHeader();
  const res = await fetch(`${API_URL}/api/profile`, {
    method: "PUT",
    headers: {
      "Content-Type": "application/json",
      ...authHeader,
    },
    body: JSON.stringify(data),
  });

  if (!res.ok) {
    const errorText = await res.text().catch(() => "");
    throw new Error(errorText || "Failed to update profile details.");
  }

  revalidatePath("/admin");
  revalidatePath("/admin/profile");
  return await res.json();
}

export async function uploadAvatarAction(
  formData: FormData,
): Promise<{ avatarUrl: string }> {
  const authHeader = await getAuthHeader();
  const res = await fetch(`${API_URL}/api/profile/avatar`, {
    method: "POST",
    headers: {
      ...authHeader,
    },
    body: formData,
  });

  if (!res.ok) {
    const errorText = await res.text().catch(() => "");
    throw new Error(errorText || "Failed to upload profile picture.");
  }

  revalidatePath("/admin");
  revalidatePath("/admin/profile");
  return await res.json();
}

export async function deleteAvatarAction(): Promise<UserProfile> {
  const authHeader = await getAuthHeader();
  const res = await fetch(`${API_URL}/api/profile/avatar`, {
    method: "DELETE",
    headers: {
      "Content-Type": "application/json",
      ...authHeader,
    },
  });

  if (!res.ok) {
    const errorText = await res.text().catch(() => "");
    throw new Error(errorText || "Failed to remove avatar.");
  }

  revalidatePath("/admin");
  revalidatePath("/admin/profile");
  return await res.json();
}

export async function sendEmailUpdateCodeAction(
  newEmail: string,
): Promise<{ verificationToken: string }> {
  const authHeader = await getAuthHeader();
  const res = await fetch(`${API_URL}/api/profile/email/send-code`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      ...authHeader,
    },
    body: JSON.stringify({ newEmail }),
  });

  if (!res.ok) {
    const errorText = await res.text().catch(() => "");
    throw new Error(errorText || "Failed to send verification code.");
  }

  return await res.json();
}

export async function verifyEmailUpdateCodeAction(
  verificationToken: string,
  otpCode: string,
): Promise<{ success: boolean }> {
  const authHeader = await getAuthHeader();
  const res = await fetch(`${API_URL}/api/profile/email/verify-code`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      ...authHeader,
    },
    body: JSON.stringify({ verificationToken, otpCode }),
  });

  if (!res.ok) {
    const errorText = await res.text().catch(() => "");
    throw new Error(errorText || "Invalid verification code.");
  }

  revalidatePath("/admin");
  revalidatePath("/admin/profile");
  return { success: true };
}

export async function changePasswordAction(
  oldPassword: string,
  newPassword: string,
): Promise<{ success: boolean }> {
  const authHeader = await getAuthHeader();
  const res = await fetch(`${API_URL}/api/profile/password`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      ...authHeader,
    },
    body: JSON.stringify({ oldPassword, newPassword }),
  });

  if (!res.ok) {
    const errorText = await res.text().catch(() => "");
    throw new Error(errorText || "Failed to update password.");
  }

  return { success: true };
}

export async function getActiveSessionsAction(): Promise<UserSession[]> {
  const authHeader = await getAuthHeader();
  const res = await fetch(`${API_URL}/api/profile/sessions`, {
    method: "GET",
    headers: {
      "Content-Type": "application/json",
      ...authHeader,
    },
    next: { revalidate: 0 },
  });

  if (!res.ok) {
    const errorText = await res.text().catch(() => "");
    throw new Error(`Failed to load sessions: ${res.status} ${errorText}`);
  }

  return await res.json();
}

export async function revokeSessionAction(
  sessionId: string,
): Promise<{ success: boolean }> {
  const authHeader = await getAuthHeader();
  const res = await fetch(`${API_URL}/api/profile/sessions/${sessionId}`, {
    method: "DELETE",
    headers: {
      "Content-Type": "application/json",
      ...authHeader,
    },
  });

  if (!res.ok) {
    const errorText = await res.text().catch(() => "");
    throw new Error(errorText || "Failed to revoke session.");
  }

  revalidatePath("/admin/profile");
  return { success: true };
}

export async function revokeOtherSessionsAction(): Promise<{
  success: boolean;
}> {
  const authHeader = await getAuthHeader();
  const res = await fetch(`${API_URL}/api/profile/sessions/revoke-others`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      ...authHeader,
    },
  });

  if (!res.ok) {
    const errorText = await res.text().catch(() => "");
    throw new Error(errorText || "Failed to revoke other sessions.");
  }

  revalidatePath("/admin/profile");
  return { success: true };
}
