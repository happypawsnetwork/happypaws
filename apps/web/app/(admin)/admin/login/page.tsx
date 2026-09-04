import Image from "next/image";
import { Metadata } from "next";
import { cookies } from "next/headers";
import { redirect } from "next/navigation";
import LoginForm from "./LoginForm";

export const metadata: Metadata = {
  title: "Admin Login | HappyPaws",
  description: "Secure admin access for HappyPaws network.",
};

async function checkExistingAuth() {
  const cookieStore = await cookies();
  let accessToken = cookieStore.get("access_token")?.value;
  const refreshToken = cookieStore.get("refresh_token")?.value;

  if (!accessToken && !refreshToken) {
    return;
  }

  const apiUrl =
    process.env.API_URL ||
    process.env.NEXT_PUBLIC_API_URL ||
    "http://localhost:5197";

  // If we only have refresh token, or if we want to try refreshing proactively
  if (!accessToken && refreshToken) {
    try {
      // Need to import refreshAction
      const { refreshAction } = await import("@/actions/auth");
      const data = await refreshAction();
      accessToken = data.accessToken;
    } catch {
      return;
    }
  }

  try {
    const res = await fetch(`${apiUrl}/api/auth/admin/me`, {
      headers: {
        Authorization: `Bearer ${accessToken}`,
      },
      cache: "no-store",
    });

    if (res.ok) {
      redirect("/admin");
    }
  } catch (error) {
    if (error && typeof error === "object" && "digest" in error) {
      throw error;
    }
    // Invalid/expired session, allow user to log in
  }
}

export default async function AdminLoginPage() {
  await checkExistingAuth();

  return (
    <div className="relative flex min-h-screen items-center justify-center bg-[#1E1E24] overflow-hidden selection:bg-[#4CE5E5]/30">
      {/* Background from Hero Section */}
      <div className="absolute inset-0 block md:hidden z-0">
        <Image
          src="/images/hero/hero-mobile.jpg"
          alt="HappyPaws Mobile Admin Background"
          fill
          priority
          sizes="100vw"
          className="object-cover object-center brightness-75"
        />
      </div>
      <div className="absolute inset-0 hidden md:block z-0">
        <Image
          src="/images/hero/hero-desktop.jpg"
          alt="HappyPaws Desktop Admin Background"
          fill
          priority
          sizes="100vw"
          className="object-cover object-center brightness-75"
        />
      </div>

      {/* Dark Gradient Overlay for optimal contrast */}
      <div className="absolute inset-0 bg-gradient-to-b from-[#1E1E24]/80 via-[#1E1E24]/85 to-[#1E1E24] z-10" />

      {/* Interactive Form Component */}
      <div className="relative z-20 w-full max-w-md px-4 sm:px-6">
        <LoginForm />
      </div>
    </div>
  );
}
