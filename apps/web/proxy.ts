import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";

// Fast-path guard to bounce completely unauthenticated visitors attempting to access dashboard routes
export function proxy(request: NextRequest) {
  const { pathname } = request.nextUrl;
  const hasAuthCookie =
    request.cookies.has("access_token") || request.cookies.has("refresh_token");
  const isLoginPage = pathname === "/admin/login";

  // Fast-path redirect unauthenticated visitors back to login without touching downstream server components
  if (!isLoginPage && !hasAuthCookie) {
    return NextResponse.redirect(new URL("/admin/login", request.url));
  }

  return NextResponse.next();
}

export const config = {
  matcher: ["/admin/:path*"],
};
