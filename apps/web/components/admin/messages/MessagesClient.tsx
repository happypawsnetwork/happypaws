"use client";

import { useState, useEffect, useRef } from "react";
import {
  ChatThreadSummary,
  getChatMessagesAction,
  findOrCreateDirectThreadAction,
  deleteChatThreadAction,
  getChatTokenAction,
  sendChatMessageAction,
  canMessageUserAction,
  blockUserAction,
  unblockUserAction,
  MessageDto,
} from "@/actions/messaging";
import { getUsersAction, AdminUserSummary } from "@/actions/users";
import { ConfirmModal } from "@/components/admin/ConfirmModal";
import Image from "next/image";
import Link from "next/link";
import * as signalR from "@microsoft/signalr";
import {
  Trash2,
  ExternalLink,
  Search,
  X,
  MessageSquare,
  Send,
  Check,
  CheckCheck,
  MoreVertical,
  LockOpen,
  Ban,
  Info,
} from "lucide-react";
import { useMessaging } from "@/providers/MessagingProvider";

interface MessagesClientProps {
  initialThreads: ChatThreadSummary[];
  initialUserId: number | null;
  currentUser?: {
    id: number;
    name: string;
    email: string;
    avatarUrl: string | null;
  } | null;
  initialChatToken?: string | null;
}

function UserAvatar({
  url,
  name,
  size = 40,
  textSize = "text-sm",
}: {
  url?: string | null;
  name: string;
  size?: number;
  textSize?: string;
}) {
  const [hasError, setHasError] = useState(false);
  const initial = name.trim() ? name.trim()[0].toUpperCase() : "?";

  if (!url || hasError) {
    return (
      <div
        className={`w-full h-full bg-blue-100 flex items-center justify-center text-blue-600 font-bold ${textSize}`}
      >
        {initial}
      </div>
    );
  }

  return (
    <Image
      src={url}
      alt={name}
      width={size}
      height={size}
      className="object-cover w-full h-full"
      onError={() => setHasError(true)}
    />
  );
}

export function MessagesClient({
  initialThreads,
  initialUserId,
  currentUser,
  initialChatToken,
}: MessagesClientProps) {
  const { refreshUnreadCount, hubConnection } = useMessaging();
  const [threads, setThreads] = useState<ChatThreadSummary[]>(initialThreads);
  const [activeThreadId, setActiveThreadId] = useState<number | null>(null);
  const [messages, setMessages] = useState<MessageDto[]>([]);
  const [newMessage, setNewMessage] = useState("");

  // Search state
  const [searchQuery, setSearchQuery] = useState("");
  const [searchResults, setSearchResults] = useState<AdminUserSummary[]>([]);
  const [isSearching, setIsSearching] = useState(false);

  // Deletion state
  const [threadToDelete, setThreadToDelete] = useState<number | null>(null);
  const [isDeleting, setIsDeleting] = useState(false);

  // Block state
  const [iBlocked, setIBlocked] = useState(false);
  const [theyBlocked, setTheyBlocked] = useState(false);
  const [isBlockPending, setIsBlockPending] = useState(false);
  const [isMenuOpen, setIsMenuOpen] = useState(false);
  const menuRef = useRef<HTMLDivElement>(null);
  const activeTargetUserIdRef = useRef<number | null>(null);

  const messagesEndRef = useRef<HTMLDivElement>(null);
  const activeThreadIdRef = useRef<number | null>(activeThreadId);
  activeThreadIdRef.current = activeThreadId;

  const activeThread = threads.find((t) => t.id === activeThreadId);
  activeTargetUserIdRef.current =
    activeThread?.otherParticipant?.userId ?? null;

  useEffect(() => {
    if (!hubConnection) return;

    const handleReceiveMessage = (message: MessageDto) => {
      setMessages((prev) => {
        if (prev.some((m) => m.id === message.id)) return prev;
        return [...prev, message];
      });

      // Update or prepend thread with last message
      setThreads((prev) => {
        const index = prev.findIndex((t) => t.id === message.threadId);
        if (index !== -1) {
          const updated = [...prev];
          const isSelfMessage =
            message.senderId === currentUser?.id && updated[index].isSelf;
          const isCurrentChat = updated[index].id === activeThreadIdRef.current;

          updated[index] = {
            ...updated[index],
            lastMessage: {
              content: message.content,
              messageType: message.messageType,
              sentAt: message.sentAt,
              seenAt: message.seenAt,
              senderId: message.senderId,
            },
            updatedAt: message.sentAt,
            unreadCount:
              isCurrentChat ||
              isSelfMessage ||
              message.senderId === currentUser?.id
                ? 0
                : updated[index].unreadCount + 1,
          };
          return updated.sort(
            (a, b) =>
              new Date(b.updatedAt).getTime() - new Date(a.updatedAt).getTime(),
          );
        }
        return prev;
      });
    };

    const handleMessageSeen = (messageId: number, seenAt: string) => {
      setMessages((prev) =>
        prev.map((m) => (m.id === messageId ? { ...m, seenAt } : m)),
      );
    };

    const handleBlockStatusChanged = (data: {
      targetUserId?: number;
      TargetUserId?: number;
      iBlocked?: boolean;
      IBlocked?: boolean;
      theyBlocked?: boolean;
      TheyBlocked?: boolean;
    }) => {
      const targetId = data.targetUserId ?? data.TargetUserId;
      if (
        activeTargetUserIdRef.current !== null &&
        targetId === activeTargetUserIdRef.current
      ) {
        setIBlocked(Boolean(data.iBlocked ?? data.IBlocked));
        setTheyBlocked(Boolean(data.theyBlocked ?? data.TheyBlocked));
      }
    };

    hubConnection.on("ReceiveMessage", handleReceiveMessage);
    hubConnection.on("MessageSeen", handleMessageSeen);
    hubConnection.on("UserBlockStatusChanged", handleBlockStatusChanged);

    return () => {
      hubConnection.off("ReceiveMessage", handleReceiveMessage);
      hubConnection.off("MessageSeen", handleMessageSeen);
      hubConnection.off("UserBlockStatusChanged", handleBlockStatusChanged);
    };
  }, [hubConnection, currentUser?.id]);

  useEffect(() => {
    if (initialUserId) {
      handleUserSelect({ id: initialUserId });
    }
  }, [initialUserId]);

  useEffect(() => {
    if (activeThreadId) {
      loadMessages(activeThreadId);
    }
  }, [activeThreadId]);

  useEffect(() => {
    if (!activeThreadId) {
      setIBlocked(false);
      setTheyBlocked(false);
      setIsMenuOpen(false);
      return;
    }

    const currentThread = threads.find((t) => t.id === activeThreadId);
    const targetUserId = currentThread?.otherParticipant?.userId;
    const isSelfChat =
      currentThread?.isSelf || targetUserId === currentUser?.id;

    setIsMenuOpen(false);

    if (!targetUserId || isSelfChat) {
      setIBlocked(false);
      setTheyBlocked(false);
      return;
    }

    let isMounted = true;
    canMessageUserAction(targetUserId)
      .then((res) => {
        if (!isMounted) return;
        setIBlocked(res.iBlocked ?? false);
        setTheyBlocked(res.theyBlocked ?? false);
      })
      .catch(() => {
        if (!isMounted) return;
        setIBlocked(false);
        setTheyBlocked(false);
      });

    return () => {
      isMounted = false;
    };
  }, [activeThreadId, threads, currentUser?.id]);

  useEffect(() => {
    const handleClickOutside = (e: MouseEvent) => {
      if (menuRef.current && !menuRef.current.contains(e.target as Node)) {
        setIsMenuOpen(false);
      }
    };
    if (isMenuOpen) {
      document.addEventListener("mousedown", handleClickOutside);
    }
    return () => {
      document.removeEventListener("mousedown", handleClickOutside);
    };
  }, [isMenuOpen]);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages]);

  useEffect(() => {
    const delayDebounceFn = setTimeout(() => {
      if (searchQuery.trim().length > 1) {
        setIsSearching(true);
        getUsersAction({ search: searchQuery, pageSize: 10 })
          .then((res) => {
            setSearchResults(res.items);
            setIsSearching(false);
          })
          .catch(() => setIsSearching(false));
      } else {
        setSearchResults([]);
      }
    }, 400);

    return () => clearTimeout(delayDebounceFn);
  }, [searchQuery]);

  const loadMessages = async (threadId: number) => {
    try {
      setThreads((prev) =>
        prev.map((t) => (t.id === threadId ? { ...t, unreadCount: 0 } : t)),
      );
      refreshUnreadCount();

      const msgs = await getChatMessagesAction(threadId);
      setMessages(msgs);

      const unseen = msgs.filter((m) => m.seenAt === null);
      unseen.forEach((m) => {
        if (hubConnection?.state === signalR.HubConnectionState.Connected) {
          hubConnection.invoke("MarkMessageAsSeen", m.id).catch(console.error);
        }
      });
    } catch (err) {
      console.error("Failed to load messages", err);
    }
  };

  const handleUserSelect = async (
    userOrId: AdminUserSummary | { id: number },
  ) => {
    try {
      const targetUserId =
        "id" in userOrId ? userOrId.id : (userOrId as any).userId;
      const res = await findOrCreateDirectThreadAction(targetUserId);
      const isSelf = targetUserId === currentUser?.id || res.isSelf;

      setThreads((prev) => {
        const existing = prev.find((t) => t.id === res.threadId);
        if (existing) {
          return prev;
        }

        const other = res.otherParticipant || {
          userId: Number(targetUserId),
          firstName:
            "firstName" in userOrId
              ? userOrId.firstName
              : isSelf && currentUser
                ? currentUser.name
                : "User",
          lastName: "lastName" in userOrId ? userOrId.lastName : "",
          avatarUrl:
            ("avatarUrl" in userOrId
              ? userOrId.avatarUrl
              : isSelf
                ? currentUser?.avatarUrl
                : null) ?? null,
          email:
            ("email" in userOrId
              ? userOrId.email
              : isSelf
                ? currentUser?.email
                : null) ?? null,
          isSelf,
        };

        const newThread: ChatThreadSummary = {
          id: res.threadId,
          isDirectMessage: true,
          isSelf,
          updatedAt: new Date().toISOString(),
          otherParticipant: other,
          lastMessage: null,
          unreadCount: 0,
        };

        return [newThread, ...prev];
      });

      setActiveThreadId(res.threadId);
      setSearchQuery("");
      setSearchResults([]);
    } catch (err) {
      console.error("Failed to start chat", err);
    }
  };

  const handleToggleBlock = async () => {
    const targetUserId = activeThread?.otherParticipant?.userId;
    if (!targetUserId || isBlockPending) return;
    setIsBlockPending(true);
    setIsMenuOpen(false);

    try {
      if (iBlocked) {
        const success = await unblockUserAction(targetUserId);
        if (success) {
          setIBlocked(false);
        } else {
          alert("Failed to unblock user.");
        }
      } else {
        const success = await blockUserAction(targetUserId);
        if (success) {
          setIBlocked(true);
        } else {
          alert("Failed to block user.");
        }
      }
    } catch (err) {
      console.error("Failed to update block status", err);
      alert("An error occurred while updating block status.");
    } finally {
      setIsBlockPending(false);
    }
  };

  const sendMessage = async () => {
    if (!newMessage.trim() || !activeThreadId || iBlocked || theyBlocked)
      return;

    const activeThread = threads.find((t) => t.id === activeThreadId);
    if (!activeThread?.otherParticipant) return;

    const messageText = newMessage.trim();
    const targetUserId = activeThread.otherParticipant.userId;
    setNewMessage("");

    try {
      if (
        hubConnection &&
        hubConnection.state === signalR.HubConnectionState.Connected
      ) {
        await hubConnection.invoke(
          "SendDirectMessage",
          targetUserId,
          messageText,
          "Text",
          null,
          null,
        );
      } else {
        const sent = await sendChatMessageAction(
          targetUserId,
          messageText,
          "Text",
        );
        setMessages((prev) => {
          if (prev.some((m) => m.id === sent.id)) return prev;
          return [...prev, sent];
        });
        setThreads((prev) => {
          const index = prev.findIndex((t) => t.id === activeThreadId);
          if (index !== -1) {
            const updated = [...prev];
            updated[index] = {
              ...updated[index],
              lastMessage: {
                content: sent.content,
                messageType: sent.messageType,
                sentAt: sent.sentAt,
                seenAt: sent.seenAt,
                senderId: sent.senderId,
              },
              updatedAt: sent.sentAt,
            };
            return updated.sort(
              (a, b) =>
                new Date(b.updatedAt).getTime() -
                new Date(a.updatedAt).getTime(),
            );
          }
          return prev;
        });
      }
    } catch (err) {
      console.error("Failed to send message", err);
      setNewMessage(messageText);
      alert("Failed to send message: " + err);
    }
  };

  const handleDeleteThread = async () => {
    if (!threadToDelete) return;
    try {
      setIsDeleting(true);
      await deleteChatThreadAction(threadToDelete);

      setThreads((prev) => prev.filter((t) => t.id !== threadToDelete));
      if (activeThreadId === threadToDelete) {
        setActiveThreadId(null);
        setMessages([]);
      }
      setThreadToDelete(null);
    } catch (err) {
      console.error("Failed to delete conversation", err);
      alert("Failed to delete conversation.");
    } finally {
      setIsDeleting(false);
    }
  };

  return (
    <div className="flex h-full bg-white rounded-2xl border border-slate-200 overflow-hidden shadow-sm">
      {/* Left Sidebar - Thread List & Search */}
      <div className="w-84 border-r border-slate-200 flex flex-col bg-slate-50 shrink-0">
        <div className="p-4 border-b border-slate-200 bg-white">
          <h2 className="text-xl font-bold text-slate-900 font-outfit mb-3">
            Messages
          </h2>
          <div className="relative">
            <input
              type="text"
              placeholder="Search users..."
              className="w-full pl-9 pr-8 py-2 rounded-xl border border-slate-200 focus:outline-none focus:ring-2 focus:ring-blue-500/30 focus:border-blue-500 text-sm bg-slate-50 transition-all placeholder:text-slate-400"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
            />
            <Search className="w-4 h-4 text-slate-400 absolute left-3 top-2.5" />
            {searchQuery && (
              <button
                onClick={() => setSearchQuery("")}
                className="absolute right-2.5 top-2.5 text-slate-400 hover:text-slate-600 p-0.5"
              >
                <X className="w-3.5 h-3.5" />
              </button>
            )}
          </div>
        </div>

        <div className="flex-1 overflow-y-auto">
          {searchQuery.trim().length > 1 ? (
            <div className="p-2 space-y-1">
              {isSearching ? (
                <div className="p-4 text-center text-sm text-slate-400">
                  Searching users...
                </div>
              ) : searchResults.length > 0 ? (
                searchResults.map((user) => {
                  const isMe = user.id === currentUser?.id;
                  const displayName = isMe
                    ? `${user.fullName} (Me)`
                    : user.fullName;

                  return (
                    <button
                      key={user.id}
                      onClick={() => handleUserSelect(user)}
                      className="w-full flex items-center gap-3 p-2.5 hover:bg-slate-200/60 rounded-xl text-left transition-colors cursor-pointer"
                    >
                      <div className="w-10 h-10 rounded-full overflow-hidden shrink-0">
                        <UserAvatar
                          url={user.avatarUrl}
                          name={displayName}
                          size={40}
                        />
                      </div>
                      <div className="flex-1 min-w-0">
                        <div className="font-semibold text-slate-800 text-sm truncate flex items-center gap-1.5">
                          <span>{displayName}</span>
                          {isMe && (
                            <span className="text-[10px] bg-blue-100 text-blue-700 font-bold px-1.5 py-0.5 rounded-full">
                              You
                            </span>
                          )}
                        </div>
                        <div className="text-xs text-slate-500 truncate">
                          {isMe ? "Message yourself" : user.email}
                        </div>
                      </div>
                    </button>
                  );
                })
              ) : (
                <div className="p-6 text-center text-sm text-slate-400">
                  No users found.
                </div>
              )}
            </div>
          ) : (
            <div className="p-2 space-y-1">
              {threads.map((thread) => {
                const isActive = thread.id === activeThreadId;
                const other = thread.otherParticipant;
                const isMe = thread.isSelf || other?.userId === currentUser?.id;
                const baseName = other
                  ? `${other.firstName} ${other.lastName}`.trim()
                  : isMe && currentUser?.name
                    ? currentUser.name
                    : "Conversation";
                const displayName = isMe ? `${baseName} (Me)` : baseName;

                return (
                  <div
                    key={thread.id}
                    className={`group relative flex items-center gap-3 p-3 rounded-xl transition-colors cursor-pointer ${
                      isActive
                        ? "bg-white shadow-xs border border-slate-200/80"
                        : "hover:bg-slate-200/50"
                    }`}
                    onClick={() => setActiveThreadId(thread.id)}
                  >
                    <div className="w-11 h-11 rounded-full overflow-hidden shrink-0">
                      <UserAvatar
                        url={other?.avatarUrl}
                        name={displayName}
                        size={44}
                        textSize="text-base"
                      />
                    </div>
                    <div className="flex-1 min-w-0">
                      {/* Top row: Name on left, timestamp on right */}
                      <div className="flex items-center justify-between gap-2 mb-1">
                        <span
                          className={`text-sm truncate font-outfit ${
                            thread.unreadCount > 0 && !isMe
                              ? "font-bold text-slate-900"
                              : "font-semibold text-slate-800"
                          }`}
                        >
                          {displayName}
                        </span>
                        {thread.lastMessage && (
                          <span
                            suppressHydrationWarning
                            className={`text-[11px] shrink-0 font-medium ${
                              thread.unreadCount > 0 && !isMe
                                ? "text-emerald-600 font-semibold"
                                : "text-slate-400"
                            }`}
                          >
                            {new Date(
                              thread.lastMessage.sentAt,
                            ).toLocaleTimeString([], {
                              hour: "2-digit",
                              minute: "2-digit",
                            })}
                          </span>
                        )}
                      </div>

                      {/* Bottom row: Shortened last message on left, unread count badge rightmost */}
                      <div className="flex items-center justify-between gap-2">
                        <p
                          className={`text-xs truncate flex-1 ${
                            thread.unreadCount > 0 && !isMe
                              ? "text-slate-900 font-semibold"
                              : "text-slate-500"
                          }`}
                        >
                          {thread.lastMessage?.content ||
                            (isMe ? "Message yourself" : "No messages yet")}
                        </p>

                        <div className="flex items-center gap-1.5 shrink-0">
                          {thread.unreadCount > 0 && !isMe && (
                            <span className="min-w-5 h-5 px-1.5 flex items-center justify-center text-[10px] font-bold bg-emerald-600 text-white rounded-full shadow-xs">
                              {thread.unreadCount > 99
                                ? "99+"
                                : thread.unreadCount}
                            </span>
                          )}

                          {/* Delete conversation action button on hover */}
                          <button
                            onClick={(e) => {
                              e.stopPropagation();
                              setThreadToDelete(thread.id);
                            }}
                            title={
                              isMe
                                ? "Clear saved messages"
                                : "Delete conversation"
                            }
                            className="opacity-0 group-hover:opacity-100 p-1 rounded-md text-slate-400 hover:text-rose-600 hover:bg-rose-50 transition-all cursor-pointer"
                          >
                            <Trash2 className="w-3.5 h-3.5" />
                          </button>
                        </div>
                      </div>
                    </div>
                  </div>
                );
              })}
              {threads.length === 0 && (
                <div className="p-8 text-center text-slate-400">
                  <MessageSquare className="w-8 h-8 mx-auto mb-2 opacity-50" />
                  <p className="font-medium text-sm">No conversations</p>
                  <p className="text-xs mt-1 text-slate-400">
                    Search for a user to start messaging.
                  </p>
                </div>
              )}
            </div>
          )}
        </div>
      </div>

      {/* Right Content - Active Chat */}
      <div className="flex-1 flex flex-col bg-slate-50/50 min-w-0">
        {activeThread ? (
          <>
            {/* Chat Header */}
            {(() => {
              const isSelfChat =
                activeThread.isSelf ||
                activeThread.otherParticipant?.userId === currentUser?.id;
              const baseName = activeThread.otherParticipant
                ? `${activeThread.otherParticipant.firstName} ${activeThread.otherParticipant.lastName}`.trim()
                : isSelfChat && currentUser
                  ? currentUser.name
                  : "Conversation";
              const headerTitle = isSelfChat ? `${baseName} (Me)` : baseName;

              return (
                <div className="px-6 py-3.5 border-b border-slate-200 bg-white flex items-center justify-between shadow-xs z-10">
                  <div className="flex items-center gap-3.5 min-w-0">
                    <div className="w-10 h-10 rounded-full overflow-hidden shrink-0">
                      <UserAvatar
                        url={activeThread.otherParticipant?.avatarUrl}
                        name={headerTitle}
                        size={40}
                      />
                    </div>
                    <div className="min-w-0">
                      <div className="flex items-center gap-2">
                        <h3 className="font-bold text-slate-900 text-base leading-tight font-outfit truncate">
                          {headerTitle}
                        </h3>
                        {!isSelfChat &&
                          activeThread.otherParticipant?.userId && (
                            <Link
                              href={`/admin/users/${activeThread.otherParticipant.userId}`}
                              target="_blank"
                              title="View user profile"
                              className="text-slate-400 hover:text-blue-600 transition-colors p-0.5 rounded-md hover:bg-slate-100"
                            >
                              <ExternalLink className="w-3.5 h-3.5" />
                            </Link>
                          )}
                      </div>
                      <p className="text-xs text-slate-400 truncate">
                        {isSelfChat
                          ? "Message yourself • Saved messages"
                          : activeThread.otherParticipant?.email
                            ? activeThread.otherParticipant.email
                            : `User #${activeThread.otherParticipant?.userId}`}
                      </p>
                    </div>
                  </div>

                  <div className="relative" ref={menuRef}>
                    <button
                      type="button"
                      onClick={() => setIsMenuOpen((prev) => !prev)}
                      title="Conversation options"
                      aria-label="Conversation options"
                      className="p-2 rounded-xl text-slate-500 hover:text-slate-700 hover:bg-slate-100 border border-slate-200 transition-colors cursor-pointer"
                    >
                      <MoreVertical className="w-4 h-4" />
                    </button>

                    {isMenuOpen && (
                      <div className="absolute right-0 mt-2 w-48 bg-white rounded-xl shadow-lg border border-slate-200 py-1 z-30 animate-in fade-in zoom-in-95 duration-100">
                        {!isSelfChat && (
                          <>
                            <button
                              type="button"
                              disabled={isBlockPending}
                              onClick={handleToggleBlock}
                              className={`w-full px-4 py-2 text-left text-xs font-medium flex items-center gap-2 transition-colors cursor-pointer ${
                                iBlocked
                                  ? "text-slate-700 hover:bg-slate-50"
                                  : "text-amber-700 hover:bg-amber-50"
                              }`}
                            >
                              {iBlocked ? (
                                <>
                                  <LockOpen className="w-3.5 h-3.5 text-slate-500" />
                                  <span>Unblock user</span>
                                </>
                              ) : (
                                <>
                                  <Ban className="w-3.5 h-3.5 text-amber-600" />
                                  <span>Block user</span>
                                </>
                              )}
                            </button>
                            <div className="h-px bg-slate-100 my-1" />
                          </>
                        )}

                        <button
                          type="button"
                          onClick={() => {
                            setIsMenuOpen(false);
                            setThreadToDelete(activeThread.id);
                          }}
                          className="w-full px-4 py-2 text-left text-xs font-medium text-rose-600 hover:bg-rose-50 flex items-center gap-2 transition-colors cursor-pointer"
                        >
                          <Trash2 className="w-3.5 h-3.5" />
                          <span>
                            {isSelfChat ? "Clear messages" : "Delete chat"}
                          </span>
                        </button>
                      </div>
                    )}
                  </div>
                </div>
              );
            })()}

            {/* Chat Messages */}
            <div className="flex-1 overflow-y-auto p-6 space-y-3">
              {(() => {
                const isSelfChat =
                  activeThread.isSelf ||
                  activeThread.otherParticipant?.userId === currentUser?.id;

                if (messages.length === 0) {
                  return isSelfChat ? (
                    <div className="h-full flex flex-col items-center justify-center text-slate-400">
                      <div className="w-14 h-14 rounded-2xl bg-white border border-slate-200 flex items-center justify-center mb-3 shadow-2xs">
                        <MessageSquare className="w-6 h-6 text-blue-600" />
                      </div>
                      <p className="font-semibold text-slate-700 text-sm font-outfit">
                        Saved Messages
                      </p>
                      <p className="text-xs text-slate-400 mt-1 max-w-xs text-center">
                        Send a message to yourself to keep notes, links, or
                        important reminders.
                      </p>
                    </div>
                  ) : (
                    <div className="h-full flex flex-col items-center justify-center text-slate-400">
                      <div className="w-14 h-14 rounded-2xl bg-white border border-slate-200 flex items-center justify-center mb-3 shadow-2xs">
                        <MessageSquare className="w-6 h-6 text-slate-400" />
                      </div>
                      <p className="font-semibold text-slate-700 text-sm font-outfit">
                        No messages yet
                      </p>
                      <p className="text-xs text-slate-400 mt-1">
                        Send a message below to start your conversation with{" "}
                        {activeThread.otherParticipant?.firstName}.
                      </p>
                    </div>
                  );
                }

                return messages.map((msg) => {
                  const isMine = isSelfChat
                    ? true
                    : msg.senderId === currentUser?.id ||
                      msg.senderId !== activeThread.otherParticipant?.userId;
                  return (
                    <div
                      key={msg.id}
                      className={`flex ${isMine ? "justify-end" : "justify-start"}`}
                    >
                      <div
                        className={`max-w-[70%] rounded-2xl px-4 py-2.5 shadow-2xs ${
                          isMine
                            ? "bg-blue-600 text-white rounded-br-xs"
                            : "bg-white text-slate-800 rounded-bl-xs border border-slate-200/80"
                        }`}
                      >
                        {msg.messageType === "Location" ? (
                          <div className="flex flex-col gap-1.5">
                            <div className="flex items-center gap-2 font-medium text-sm">
                              <svg
                                className="w-4 h-4 shrink-0"
                                fill="none"
                                stroke="currentColor"
                                viewBox="0 0 24 24"
                              >
                                <path
                                  strokeLinecap="round"
                                  strokeLinejoin="round"
                                  strokeWidth="2"
                                  d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"
                                />
                                <path
                                  strokeLinecap="round"
                                  strokeLinejoin="round"
                                  strokeWidth="2"
                                  d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"
                                />
                              </svg>
                              <span>{msg.content || "Location Shared"}</span>
                            </div>
                            <a
                              href={`https://maps.google.com/?q=${msg.latitude},${msg.longitude}`}
                              target="_blank"
                              rel="noreferrer"
                              className={`text-xs underline ${isMine ? "text-blue-100 hover:text-white" : "text-blue-600 hover:text-blue-700"}`}
                            >
                              Open in Google Maps
                            </a>
                          </div>
                        ) : (
                          <p className="text-sm break-words whitespace-pre-wrap leading-relaxed">
                            {msg.content}
                          </p>
                        )}
                        <div
                          className={`flex justify-end items-center mt-1 gap-1 ${isMine ? "text-blue-200" : "text-slate-400"}`}
                        >
                          <span className="text-[10px]">
                            {new Date(msg.sentAt).toLocaleTimeString([], {
                              hour: "2-digit",
                              minute: "2-digit",
                            })}
                          </span>
                          {isMine && (
                            <span
                              className="inline-flex items-center ml-0.5"
                              title={
                                msg.seenAt
                                  ? "Seen"
                                  : msg.deliveredAt
                                    ? "Delivered"
                                    : "Sent"
                              }
                            >
                              {msg.seenAt ? (
                                <CheckCheck className="w-3.5 h-3.5 text-sky-200" />
                              ) : msg.deliveredAt ? (
                                <CheckCheck className="w-3.5 h-3.5 text-blue-200" />
                              ) : (
                                <Check className="w-3.5 h-3.5 text-blue-200" />
                              )}
                            </span>
                          )}
                        </div>
                      </div>
                    </div>
                  );
                });
              })()}
              <div ref={messagesEndRef} />
            </div>

            {/* Blocked banner */}
            {(iBlocked || theyBlocked) && (
              <div className="p-4 bg-slate-50 border-t border-slate-200">
                <div className="p-3.5 bg-amber-50/80 border border-amber-200/80 rounded-xl text-center space-y-2.5">
                  <div className="flex items-center justify-center gap-2 text-xs font-medium text-amber-900">
                    <Ban className="w-4 h-4 text-amber-600 shrink-0" />
                    <span>
                      {iBlocked
                        ? "You blocked this user. You cannot send or receive messages."
                        : "You cannot send or receive messages from this user."}
                    </span>
                  </div>
                  {iBlocked && (
                    <div className="flex items-center justify-center gap-2 pt-1">
                      <button
                        type="button"
                        onClick={() => setThreadToDelete(activeThread.id)}
                        className="px-3 py-1.5 text-xs font-semibold text-rose-700 bg-white hover:bg-rose-50 border border-rose-200 rounded-lg shadow-2xs transition-colors cursor-pointer flex items-center gap-1.5"
                      >
                        <Trash2 className="w-3.5 h-3.5 text-rose-600" />
                        <span>Delete conversation</span>
                      </button>
                      <button
                        type="button"
                        disabled={isBlockPending}
                        onClick={handleToggleBlock}
                        className="px-3 py-1.5 text-xs font-semibold text-white bg-blue-600 hover:bg-blue-700 rounded-lg shadow-2xs transition-colors cursor-pointer flex items-center gap-1.5 disabled:opacity-50"
                      >
                        <LockOpen className="w-3.5 h-3.5" />
                        <span>Unblock user</span>
                      </button>
                    </div>
                  )}
                </div>
              </div>
            )}

            {/* Chat Input */}
            <div className="p-4 bg-white border-t border-slate-200">
              <div
                className={`flex items-end gap-2 border rounded-2xl p-2 transition-all ${
                  iBlocked || theyBlocked
                    ? "bg-slate-100 border-slate-200 opacity-60 cursor-not-allowed"
                    : "bg-slate-50 border-slate-200 focus-within:ring-2 focus-within:ring-blue-500/20 focus-within:border-blue-500"
                }`}
              >
                <textarea
                  className="flex-1 bg-transparent resize-none border-none focus:outline-none focus:ring-0 py-1.5 px-2 text-sm max-h-32 text-slate-800 placeholder:text-slate-400 disabled:cursor-not-allowed"
                  placeholder={
                    iBlocked || theyBlocked
                      ? "You cannot send messages to this conversation."
                      : "Type a message..."
                  }
                  rows={1}
                  value={newMessage}
                  disabled={iBlocked || theyBlocked}
                  onChange={(e) => setNewMessage(e.target.value)}
                  onKeyDown={(e) => {
                    if (e.key === "Enter" && !e.shiftKey) {
                      e.preventDefault();
                      sendMessage();
                    }
                  }}
                  autoFocus
                />
                <button
                  onClick={sendMessage}
                  disabled={!newMessage.trim() || iBlocked || theyBlocked}
                  className="p-2.5 bg-blue-600 hover:bg-blue-700 disabled:bg-slate-300 text-white rounded-xl transition-all shrink-0 shadow-xs cursor-pointer disabled:cursor-not-allowed"
                >
                  <Send className="w-4 h-4" />
                </button>
              </div>
            </div>
          </>
        ) : (
          <div className="flex-1 flex items-center justify-center text-slate-400 flex-col gap-3 bg-slate-50/50">
            <div className="w-20 h-20 rounded-2xl bg-white border border-slate-200 flex items-center justify-center shadow-2xs">
              <MessageSquare className="w-8 h-8 text-slate-300" />
            </div>
            <p className="font-semibold text-slate-700 text-sm font-outfit">
              No chat selected
            </p>
            <p className="text-xs text-slate-400">
              Select a conversation from the left or search for a user to start
              messaging.
            </p>
          </div>
        )}
      </div>

      {/* Delete Confirmation Modal */}
      {(() => {
        const isSelfChat =
          activeThread?.isSelf ||
          activeThread?.otherParticipant?.userId === currentUser?.id;
        const isClearingActiveSelf =
          isSelfChat && threadToDelete === activeThread?.id;

        return (
          <ConfirmModal
            isOpen={threadToDelete !== null}
            title={
              isClearingActiveSelf
                ? "Clear Saved Messages"
                : "Delete Conversation"
            }
            description={
              isClearingActiveSelf
                ? "Are you sure you want to clear your saved messages? This will permanently remove this message history for you."
                : "Are you sure you want to delete this entire conversation? This will permanently remove the conversation history for you. The other participant will not be affected."
            }
            confirmLabel={
              isClearingActiveSelf ? "Clear Messages" : "Delete Conversation"
            }
            variant="danger"
            isPending={isDeleting}
            onConfirm={handleDeleteThread}
            onClose={() => setThreadToDelete(null)}
          />
        );
      })()}
    </div>
  );
}
