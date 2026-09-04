"use server";

import { cookies } from "next/headers";
import { refreshAction } from "@/actions/auth";

const API_URL =
  process.env.API_URL ||
  process.env.NEXT_PUBLIC_API_URL ||
  "http://localhost:5197";

async function getAuthHeader(): Promise<Record<string, string>> {
  const cookieStore = await cookies();
  const token = cookieStore.get("access_token")?.value;
  return token ? { Authorization: `Bearer ${token}` } : {};
}

export interface ChatThreadSummary {
  id: number;
  isDirectMessage: boolean;
  isSelf?: boolean;
  updatedAt: string;
  otherParticipant: {
    userId: number;
    firstName: string;
    lastName: string;
    avatarUrl: string | null;
    email?: string | null;
    isSelf?: boolean;
  } | null;
  lastMessage: {
    content: string;
    messageType: string;
    sentAt: string;
    seenAt: string | null;
    senderId: number;
  } | null;
  unreadCount: number;
}

export interface MessageDto {
  id: number;
  threadId?: number;
  senderId: number;
  messageType: string;
  content: string;
  latitude: number | null;
  longitude: number | null;
  sentAt: string;
  deliveredAt: string | null;
  seenAt: string | null;
  senderName?: string;
  senderAvatarUrl?: string | null;
}

export interface FindOrCreateDirectThreadResponse {
  threadId: number;
  isSelf?: boolean;
  otherParticipant: {
    userId: number;
    firstName: string;
    lastName: string;
    avatarUrl: string | null;
    email?: string | null;
    isSelf?: boolean;
  } | null;
}

export async function getChatThreadsAction(): Promise<ChatThreadSummary[]> {
  const authHeader = await getAuthHeader();
  const res = await fetch(`${API_URL}/api/messaging/threads`, {
    method: "GET",
    headers: {
      "Content-Type": "application/json",
      ...authHeader,
    },
    next: { revalidate: 0 },
  });

  if (!res.ok) {
    const errorText = await res.text().catch(() => "");
    throw new Error(`Failed to fetch threads: ${res.status} ${errorText}`);
  }

  return await res.json();
}

export async function getChatMessagesAction(
  threadId: number,
): Promise<MessageDto[]> {
  const authHeader = await getAuthHeader();
  const res = await fetch(
    `${API_URL}/api/messaging/threads/${threadId}/messages`,
    {
      method: "GET",
      headers: {
        "Content-Type": "application/json",
        ...authHeader,
      },
      next: { revalidate: 0 },
    },
  );

  if (!res.ok) {
    const errorText = await res.text().catch(() => "");
    throw new Error(`Failed to fetch messages: ${res.status} ${errorText}`);
  }

  return await res.json();
}

export async function findOrCreateDirectThreadAction(
  targetUserId: number,
): Promise<FindOrCreateDirectThreadResponse> {
  const authHeader = await getAuthHeader();
  const res = await fetch(
    `${API_URL}/api/messaging/threads/direct/${targetUserId}`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        ...authHeader,
      },
    },
  );

  if (!res.ok) {
    const errorText = await res.text().catch(() => "");
    throw new Error(`Failed to create thread: ${res.status} ${errorText}`);
  }

  return await res.json();
}

export async function deleteChatThreadAction(threadId: number): Promise<void> {
  const authHeader = await getAuthHeader();
  const res = await fetch(`${API_URL}/api/messaging/threads/${threadId}`, {
    method: "DELETE",
    headers: {
      "Content-Type": "application/json",
      ...authHeader,
    },
  });

  if (!res.ok && res.status !== 204) {
    const errorText = await res.text().catch(() => "");
    throw new Error(`Failed to delete thread: ${res.status} ${errorText}`);
  }
}

export async function getChatTokenAction(): Promise<string | null> {
  const cookieStore = await cookies();
  const token = cookieStore.get("access_token")?.value;
  if (token) return token;

  const refreshToken = cookieStore.get("refresh_token")?.value;
  if (refreshToken) {
    try {
      const refreshed = await refreshAction();
      return refreshed.accessToken ?? null;
    } catch {
      return null;
    }
  }

  return null;
}

export async function sendChatMessageAction(
  targetUserId: number,
  content: string,
  messageType = "Text",
  latitude?: number | null,
  longitude?: number | null,
): Promise<MessageDto> {
  const authHeader = await getAuthHeader();
  const res = await fetch(
    `${API_URL}/api/messaging/threads/direct/${targetUserId}/messages`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        ...authHeader,
      },
      body: JSON.stringify({
        content,
        messageType,
        latitude,
        longitude,
      }),
    },
  );

  if (!res.ok) {
    const errorText = await res.text().catch(() => "");
    throw new Error(`Failed to send message: ${res.status} ${errorText}`);
  }

  return await res.json();
}

export async function getUnreadMessagesCountAction(): Promise<number> {
  const authHeader = await getAuthHeader();
  try {
    const res = await fetch(`${API_URL}/api/messaging/unread-count`, {
      headers: {
        ...authHeader,
      },
      cache: "no-store",
    });

    if (!res.ok) {
      return 0;
    }

    const data = await res.json();
    return typeof data.unreadCount === "number" ? data.unreadCount : 0;
  } catch {
    return 0;
  }
}

export interface CanMessageResponse {
  canMessage: boolean;
  reason?: string | null;
  iBlocked?: boolean;
  theyBlocked?: boolean;
}

export async function canMessageUserAction(
  targetUserId: number,
): Promise<CanMessageResponse> {
  const authHeader = await getAuthHeader();
  try {
    const res = await fetch(
      `${API_URL}/api/messaging/can-message/${targetUserId}`,
      {
        method: "GET",
        headers: {
          "Content-Type": "application/json",
          ...authHeader,
        },
        cache: "no-store",
      },
    );

    if (!res.ok) {
      return { canMessage: false, reason: "Failed to check messaging status" };
    }

    return await res.json();
  } catch {
    return { canMessage: false, reason: "Failed to check messaging status" };
  }
}

export async function blockUserAction(targetUserId: number): Promise<boolean> {
  const authHeader = await getAuthHeader();
  try {
    const res = await fetch(`${API_URL}/api/messaging/block/${targetUserId}`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        ...authHeader,
      },
    });

    return res.ok;
  } catch {
    return false;
  }
}

export async function unblockUserAction(
  targetUserId: number,
): Promise<boolean> {
  const authHeader = await getAuthHeader();
  try {
    const res = await fetch(
      `${API_URL}/api/messaging/unblock/${targetUserId}`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          ...authHeader,
        },
      },
    );

    return res.ok;
  } catch {
    return false;
  }
}
