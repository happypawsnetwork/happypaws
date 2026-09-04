import { cookies } from "next/headers";
import { redirect } from "next/navigation";
import { AdminSidebar } from "@/components/admin/AdminSidebar";
import { AdminHeader, type AdminUser } from "@/components/admin/AdminHeader";
import { refreshAction } from "@/actions/auth";
import { MessagingProvider } from "@/providers/MessagingProvider";

async function getAuthenticatedAdmin(): Promise<AdminUser> {
  const cookieStore = await cookies();
  let accessToken = cookieStore.get("access_token")?.value;
  const refreshToken = cookieStore.get("refresh_token")?.value;

  if (!accessToken && !refreshToken) {
    redirect("/admin/login");
  }

  const apiUrl =
    process.env.API_URL ||
    process.env.NEXT_PUBLIC_API_URL ||
    "http://localhost:5197";

  // If we only have refresh token, or if we want to try refreshing proactively
  if (!accessToken && refreshToken) {
    try {
      const data = await refreshAction();
      accessToken = data.accessToken;
    } catch {
      redirect("/admin/login");
    }
  }

  try {
    let res = await fetch(`${apiUrl}/api/auth/admin/me`, {
      headers: {
        Authorization: `Bearer ${accessToken}`,
      },
      cache: "no-store",
    });

    if (res.status === 401 && refreshToken) {
      // Access token expired, attempt refresh
      try {
        const data = await refreshAction();
        accessToken = data.accessToken;

        res = await fetch(`${apiUrl}/api/auth/admin/me`, {
          headers: {
            Authorization: `Bearer ${accessToken}`,
          },
          cache: "no-store",
        });
      } catch {
        redirect("/admin/login");
      }
    }

    if (!res.ok) {
      redirect("/admin/login");
    }

    const user: AdminUser = await res.json();
    return user;
  } catch (error) {
    if (error && typeof error === "object" && "digest" in error) {
      throw error;
    }
    redirect("/admin/login");
  }
}

export default async function DashboardLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  const user = await getAuthenticatedAdmin();

  return (
    <MessagingProvider>
      <div className="flex min-h-screen bg-slate-50 text-slate-900 overflow-hidden font-sans selection:bg-blue-100 selection:text-blue-900">
        <AdminSidebar />
        <div className="flex-1 flex flex-col min-w-0">
          <AdminHeader user={user} />
          <main className="flex-1 overflow-y-auto p-6 lg:p-10 relative">
            {children}
          </main>
        </div>
      </div>
    </MessagingProvider>
  );
}
