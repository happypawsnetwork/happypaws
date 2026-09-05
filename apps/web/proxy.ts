import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";

const API_URL =
  process.env.API_URL ||
  process.env.NEXT_PUBLIC_API_URL ||
  "http://localhost:5197";

/**
 * Reads the exp claim from a JWT payload without verifying the cryptographic signature.
 *
 * The edge runtime uses this to trigger token refreshing before expiration.
 * The backend API serves as the authority and verifies signatures on every request.
 */
function isTokenExpired(token: string): boolean {
  try {
    const parts = token.split(".");
    if (parts.length !== 3) return true;
    const base64Url = parts[1];
    const base64 = base64Url.replace(/-/g, "+").replace(/_/g, "/");
    const jsonStr = atob(base64);
    const payload = JSON.parse(jsonStr);
    const exp = payload.exp;
    if (typeof exp !== "number") return true;
    // Buffer by 30 seconds to refresh early before actual expiration
    return Date.now() >= exp * 1000 - 30000;
  } catch {
    return true;
  }
}

export async function proxy(request: NextRequest) {
  const { pathname } = request.nextUrl;
  const isLoginPage = pathname === "/admin/login";

  if (isLoginPage) {
    return NextResponse.next();
  }

  const accessToken = request.cookies.get("access_token")?.value;
  const refreshToken = request.cookies.get("refresh_token")?.value;

  if (!accessToken && !refreshToken) {
    return NextResponse.redirect(new URL("/admin/login", request.url));
  }

  const needsRefresh = !accessToken || isTokenExpired(accessToken);

  if (needsRefresh) {
    if (!refreshToken) {
      const loginUrl = new URL("/admin/login", request.url);
      const res = NextResponse.redirect(loginUrl);
      res.cookies.delete("access_token");
      res.cookies.delete("refresh_token");
      return res;
    }

    try {
      const refreshRes = await fetch(`${API_URL}/api/auth/admin/refresh`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ refreshToken }),
      });

      if (!refreshRes.ok) {
        const loginUrl = new URL("/admin/login", request.url);
        const res = NextResponse.redirect(loginUrl);
        res.cookies.delete("access_token");
        res.cookies.delete("refresh_token");
        return res;
      }

      const data = await refreshRes.json();
      const refreshMaxAge = data.refreshExpiresIn || 30 * 24 * 60 * 60;

      request.cookies.set("access_token", data.accessToken);
      request.cookies.set("refresh_token", data.refreshToken);

      const requestHeaders = new Headers(request.headers);
      requestHeaders.set("Authorization", `Bearer ${data.accessToken}`);
      requestHeaders.set("cookie", request.cookies.toString());

      const response = NextResponse.next({
        request: {
          headers: requestHeaders,
        },
      });

      response.cookies.set("access_token", data.accessToken, {
        httpOnly: true,
        secure: process.env.NODE_ENV === "production",
        sameSite: "lax",
        maxAge: 15 * 60,
        path: "/",
      });

      response.cookies.set("refresh_token", data.refreshToken, {
        httpOnly: true,
        secure: process.env.NODE_ENV === "production",
        sameSite: "lax",
        maxAge: refreshMaxAge,
        path: "/",
      });

      return response;
    } catch {
      const loginUrl = new URL("/admin/login", request.url);
      const res = NextResponse.redirect(loginUrl);
      res.cookies.delete("access_token");
      res.cookies.delete("refresh_token");
      return res;
    }
  }

  return NextResponse.next();
}

export const config = {
  matcher: ["/admin/:path*"],
};
