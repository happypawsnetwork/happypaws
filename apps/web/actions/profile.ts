"use server";

import { cookies } from "next/headers";
import { revalidatePath } from "next/cache";
import { refreshAction } from "./auth";

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

async function authFetch(
  endpoint: string,
  options: RequestInit = {},
): Promise<Response> {
  const cookieStore = await cookies();
  let token = cookieStore.get("access_token")?.value;

  if (!token) {
    try {
      const refreshed = await refreshAction();
      token = refreshed.accessToken;
    } catch {
      throw new Error("Session expired. Please log in again.");
    }
  }

  if (!token) {
    throw new Error("Session expired. Please log in again.");
  }

  const performFetch = (bearer: string) => {
    const headers = new Headers(options.headers);
    headers.set("Authorization", `Bearer ${bearer}`);
    return fetch(`${API_URL}${endpoint}`, {
      ...options,
      headers,
    });
  };

  let res = await performFetch(token);

  if (res.status === 401) {
    try {
      const refreshed = await refreshAction();
      res = await performFetch(refreshed.accessToken);
    } catch {
      throw new Error("Session expired. Please log in again.");
    }
  }

  return res;
}

async function parseErrorMessage(
  res: Response,
  fallback: string,
): Promise<string> {
  try {
    const data = await res.json();
    return data.detail || data.title || data.message || fallback;
  } catch {
    const text = await res.text().catch(() => "");
    return text || fallback;
  }
}

export async function getProfileAction(): Promise<UserProfile> {
  const res = await authFetch("/api/profile", {
    method: "GET",
    headers: {
      "Content-Type": "application/json",
    },
    next: { revalidate: 0 },
  });

  if (!res.ok) {
    const err = await parseErrorMessage(res, "Failed to load profile.");
    throw new Error(err);
  }

  return await res.json();
}

export async function updateProfileAction(data: {
  firstName?: string;
  lastName?: string;
  phoneNumber?: string | null;
  tagline?: string | null;
}): Promise<UserProfile> {
  const res = await authFetch("/api/profile", {
    method: "PUT",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify(data),
  });

  if (!res.ok) {
    const err = await parseErrorMessage(
      res,
      "Failed to update profile details.",
    );
    throw new Error(err);
  }

  revalidatePath("/admin");
  revalidatePath("/admin/profile");
  return await res.json();
}

export async function uploadAvatarAction(
  formData: FormData,
): Promise<{ avatarUrl: string }> {
  const res = await authFetch("/api/profile/avatar", {
    method: "POST",
    body: formData,
  });

  if (!res.ok) {
    const err = await parseErrorMessage(
      res,
      "Failed to upload profile picture.",
    );
    throw new Error(err);
  }

  revalidatePath("/admin");
  revalidatePath("/admin/profile");
  return await res.json();
}

export async function deleteAvatarAction(): Promise<UserProfile> {
  const res = await authFetch("/api/profile/avatar", {
    method: "DELETE",
    headers: {
      "Content-Type": "application/json",
    },
  });

  if (!res.ok) {
    const err = await parseErrorMessage(res, "Failed to remove avatar.");
    throw new Error(err);
  }

  revalidatePath("/admin");
  revalidatePath("/admin/profile");
  return await res.json();
}

export async function sendEmailUpdateCodeAction(
  newEmail: string,
): Promise<{ verificationToken: string }> {
  const res = await authFetch("/api/profile/email/send-code", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ newEmail }),
  });

  if (!res.ok) {
    const err = await parseErrorMessage(
      res,
      "Failed to send verification code.",
    );
    throw new Error(err);
  }

  return await res.json();
}

export async function verifyEmailUpdateCodeAction(
  verificationToken: string,
  otpCode: string,
): Promise<{ success: boolean }> {
  const res = await authFetch("/api/profile/email/verify-code", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ verificationToken, otpCode }),
  });

  if (!res.ok) {
    const err = await parseErrorMessage(res, "Invalid verification code.");
    throw new Error(err);
  }

  revalidatePath("/admin");
  revalidatePath("/admin/profile");
  return { success: true };
}

export async function changePasswordAction(
  oldPassword: string,
  newPassword: string,
): Promise<{ success: boolean }> {
  const res = await authFetch("/api/profile/password", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ oldPassword, newPassword }),
  });

  if (!res.ok) {
    const err = await parseErrorMessage(res, "Failed to update password.");
    throw new Error(err);
  }

  return { success: true };
}

export async function getActiveSessionsAction(): Promise<UserSession[]> {
  const res = await authFetch("/api/profile/sessions", {
    method: "GET",
    headers: {
      "Content-Type": "application/json",
    },
    next: { revalidate: 0 },
  });

  if (!res.ok) {
    const err = await parseErrorMessage(res, "Failed to load sessions.");
    throw new Error(err);
  }

  return await res.json();
}

export async function revokeSessionAction(
  sessionId: string,
): Promise<{ success: boolean }> {
  const res = await authFetch(`/api/profile/sessions/${sessionId}`, {
    method: "DELETE",
    headers: {
      "Content-Type": "application/json",
    },
  });

  if (!res.ok) {
    const err = await parseErrorMessage(res, "Failed to revoke session.");
    throw new Error(err);
  }

  revalidatePath("/admin/profile");
  return { success: true };
}

export async function revokeOtherSessionsAction(): Promise<{
  success: boolean;
}> {
  const res = await authFetch("/api/profile/sessions/revoke-others", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
  });

  if (!res.ok) {
    const err = await parseErrorMessage(
      res,
      "Failed to revoke other sessions.",
    );
    throw new Error(err);
  }

  revalidatePath("/admin/profile");
  return { success: true };
}
