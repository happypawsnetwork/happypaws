import { Suspense } from "react";
import { ProfileSettingsView } from "@/components/admin/profile/ProfileSettingsView";
import {
  getProfileAction,
  getActiveSessionsAction,
  type UserProfile,
  type UserSession,
} from "@/actions/profile";

export const dynamic = "force-dynamic";

function ProfileLoadingSkeleton() {
  return (
    <div className="w-full max-w-5xl mx-auto space-y-8 animate-pulse">
      <div className="space-y-2">
        <div className="h-8 w-48 bg-slate-200 rounded-xl" />
        <div className="h-4 w-80 bg-slate-100 rounded-lg" />
      </div>

      <div className="h-44 bg-white border border-slate-200/80 rounded-2xl p-6 shadow-xs" />
      <div className="h-12 w-96 bg-slate-200 rounded-2xl" />
      <div className="h-80 bg-white border border-slate-200/80 rounded-2xl p-6 shadow-xs" />
    </div>
  );
}

export default async function ProfilePage() {
  let profile: UserProfile | undefined;
  let sessions: UserSession[] = [];

  try {
    const [p, s] = await Promise.all([
      getProfileAction(),
      getActiveSessionsAction().catch(() => []),
    ]);
    profile = p;
    sessions = s;
  } catch (err) {
    console.error("Failed to pre-fetch profile on server:", err);
  }

  if (!profile) {
    // Fallback minimal profile structure if server call is pending auth
    profile = {
      id: 0,
      email: "admin@happypaws.org",
      firstName: "Happy",
      lastName: "Paws",
      fullName: "Happy Paws",
      phoneNumber: null,
      avatarUrl: null,
      tagline: null,
      reputationPoints: 100,
      roles: ["Administrator"],
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };
  }

  return (
    <Suspense fallback={<ProfileLoadingSkeleton />}>
      <ProfileSettingsView
        initialProfile={profile}
        initialSessions={sessions}
      />
    </Suspense>
  );
}
