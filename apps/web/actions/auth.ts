"use server";

import { cookies } from "next/headers";

const API_URL =
  process.env.API_URL ||
  process.env.NEXT_PUBLIC_API_URL ||
  "http://localhost:5197";

export async function loginAction(email: string, password: string) {
  const res = await fetch(`${API_URL}/api/auth/admin/login`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email, password }),
  });

  if (!res.ok) {
    const error = await res.json().catch(() => null);
    throw new Error(error?.detail || "Invalid credentials");
  }

  const data = await res.json();

  if (data.devBypass) {
    const cookieStore = await cookies();

    cookieStore.set("access_token", data.accessToken, {
      httpOnly: true,
      secure: process.env.NODE_ENV === "production",
      sameSite: "lax",
      maxAge: 15 * 60, // 15 mins
      path: "/",
    });

    cookieStore.set("refresh_token", data.refreshToken, {
      httpOnly: true,
      secure: process.env.NODE_ENV === "production",
      sameSite: "lax",
      maxAge: 14 * 24 * 60 * 60, // 14 days
      path: "/",
    });

    return { devBypass: true };
  }

  return data;
}

export async function verifyOtpAction(
  verificationToken: string,
  otpCode: string,
) {
  const res = await fetch(`${API_URL}/api/auth/admin/verify-otp`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ verificationToken, otpCode }),
  });

  if (!res.ok) {
    const error = await res.json().catch(() => null);
    throw new Error(error?.detail || "Invalid OTP");
  }

  const data = await res.json();
  const cookieStore = await cookies();

  // Set the Access Token (needed for Server Components to call backend APIs)
  cookieStore.set("access_token", data.accessToken, {
    httpOnly: true,
    secure: process.env.NODE_ENV === "production",
    sameSite: "lax",
    maxAge: 15 * 60, // 15 mins
    path: "/",
  });

  // Set the Refresh Token (HttpOnly)
  cookieStore.set("refresh_token", data.refreshToken, {
    httpOnly: true,
    secure: process.env.NODE_ENV === "production",
    sameSite: "lax",
    maxAge: 14 * 24 * 60 * 60, // 14 days
    path: "/",
  });

  return { success: true };
}

export async function refreshAction() {
  const cookieStore = await cookies();
  const refreshToken = cookieStore.get("refresh_token")?.value;

  if (!refreshToken) {
    throw new Error("No refresh token found");
  }

  const res = await fetch(`${API_URL}/api/auth/admin/refresh`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ refreshToken }),
  });

  if (!res.ok) {
    cookieStore.delete("access_token");
    cookieStore.delete("refresh_token");
    throw new Error("Failed to refresh token");
  }

  const data = await res.json();

  cookieStore.set("access_token", data.accessToken, {
    httpOnly: true,
    secure: process.env.NODE_ENV === "production",
    sameSite: "lax",
    maxAge: 15 * 60,
    path: "/",
  });

  cookieStore.set("refresh_token", data.refreshToken, {
    httpOnly: true,
    secure: process.env.NODE_ENV === "production",
    sameSite: "lax",
    maxAge: 14 * 24 * 60 * 60,
    path: "/",
  });

  return { success: true, accessToken: data.accessToken };
}

export async function logoutAction() {
  const cookieStore = await cookies();
  const refreshToken = cookieStore.get("refresh_token")?.value;
  const accessToken = cookieStore.get("access_token")?.value;

  if (refreshToken) {
    try {
      await fetch(`${API_URL}/api/auth/admin/revoke`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${accessToken}`,
        },
        body: JSON.stringify({ refreshToken }),
      });
    } catch {
      // Ignore errors during revocation to ensure local session is cleared
    }
  }

  cookieStore.delete("access_token");
  cookieStore.delete("refresh_token");

  return { success: true };
}

export interface CurrentAdminUser {
  id: number;
  email: string;
  name: string;
  avatarUrl: string | null;
  roles: string[];
}

export async function getCurrentAdminAction(): Promise<CurrentAdminUser | null> {
  const cookieStore = await cookies();
  const accessToken = cookieStore.get("access_token")?.value;
  if (!accessToken) return null;

  try {
    const res = await fetch(`${API_URL}/api/auth/admin/me`, {
      headers: {
        Authorization: `Bearer ${accessToken}`,
      },
      cache: "no-store",
    });

    if (!res.ok) return null;
    const data = await res.json();
    return {
      id: Number(data.id),
      email: data.email,
      name: data.name,
      avatarUrl: data.avatarUrl || null,
      roles: (data.roles || []).map((r: any) =>
        typeof r === "string" ? r : r.name,
      ),
    };
  } catch {
    return null;
  }
}
