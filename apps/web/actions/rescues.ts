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

export type AdminRescueMapCase = {
  id: string;
  title: string;
  status: string;
  animalName: string | null;
  animalSpecies: string | null;
  urgencyLevel: string | null;
  aiTriageReason: string | null;
  isUrgencyManuallyOverridden: boolean;
  latitude: number | null;
  longitude: number | null;
  locationLabel: string | null;
  createdAt: string;
};

export async function getRescueMapCases(): Promise<AdminRescueMapCase[]> {
  try {
    const res = await fetch(`${API_URL}/api/v1/admin/rescues/map`, {
      headers: {
        ...(await getAuthHeader()),
      },
      next: { tags: ["rescue-cases-map"], revalidate: 60 },
    });

    if (!res.ok) {
      console.error("Failed to fetch rescue map cases:", res.statusText);
      return [];
    }

    return await res.json();
  } catch (error) {
    console.error("Error fetching rescue map cases:", error);
    return [];
  }
}

export async function updateRescueUrgency(
  postId: string,
  urgencyLevel: string,
) {
  try {
    const res = await fetch(
      `${API_URL}/api/v1/admin/rescues/${postId}/urgency`,
      {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          ...(await getAuthHeader()),
        },
        body: JSON.stringify({ urgencyLevel }),
      },
    );

    if (!res.ok) {
      throw new Error(`Failed to update urgency: ${res.statusText}`);
    }

    revalidatePath("/admin/rescue-map");
    revalidatePath("/admin/rescues"); // revalidate rescues tab if they have one
    return { success: true };
  } catch (error) {
    console.error("Error updating rescue urgency:", error);
    return { success: false, error: (error as Error).message };
  }
}
