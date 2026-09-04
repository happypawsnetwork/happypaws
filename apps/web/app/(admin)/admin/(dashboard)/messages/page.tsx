import { getChatThreadsAction, getChatTokenAction } from "@/actions/messaging";
import { getCurrentAdminAction } from "@/actions/auth";
import { MessagesClient } from "@/components/admin/messages/MessagesClient";

export default async function MessagesPage({
  searchParams,
}: {
  searchParams: Promise<{ userId?: string }>;
}) {
  const [threads, currentUser, chatToken, resolvedParams] = await Promise.all([
    getChatThreadsAction().catch(() => []),
    getCurrentAdminAction(),
    getChatTokenAction(),
    searchParams,
  ]);

  const initialUserId = resolvedParams.userId
    ? Number(resolvedParams.userId)
    : null;

  return (
    <div className="h-[calc(100vh-6rem)] w-full">
      <MessagesClient
        initialThreads={threads}
        initialUserId={initialUserId}
        currentUser={currentUser}
        initialChatToken={chatToken}
      />
    </div>
  );
}
