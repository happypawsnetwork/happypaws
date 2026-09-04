"use client";

import React, {
  createContext,
  useContext,
  useEffect,
  useState,
  useCallback,
  useRef,
} from "react";
import { usePathname, useRouter } from "next/navigation";
import * as signalR from "@microsoft/signalr";
import { motion, AnimatePresence } from "framer-motion";
import { MessageSquare, X } from "lucide-react";
import {
  getChatTokenAction,
  getUnreadMessagesCountAction,
  type MessageDto,
} from "@/actions/messaging";

interface MessagingContextType {
  unreadCount: number;
  setUnreadCount: React.Dispatch<React.SetStateAction<number>>;
  refreshUnreadCount: () => Promise<void>;
  hubConnection: signalR.HubConnection | null;
}

const MessagingContext = createContext<MessagingContextType>({
  unreadCount: 0,
  setUnreadCount: () => {},
  refreshUnreadCount: async () => {},
  hubConnection: null,
});

export function useMessaging() {
  return useContext(MessagingContext);
}

interface InAppAlert {
  id: string;
  senderName: string;
  content: string;
  threadId?: number;
  senderAvatarUrl?: string | null;
}

export function MessagingProvider({ children }: { children: React.ReactNode }) {
  const [unreadCount, setUnreadCount] = useState<number>(0);
  const [activeAlert, setActiveAlert] = useState<InAppAlert | null>(null);
  const [hubConnection, setHubConnection] =
    useState<signalR.HubConnection | null>(null);
  const alertTimerRef = useRef<NodeJS.Timeout | null>(null);
  const hubConnectionRef = useRef<signalR.HubConnection | null>(null);
  const pathname = usePathname();
  const pathnameRef = useRef(pathname);
  const router = useRouter();

  useEffect(() => {
    pathnameRef.current = pathname;
  }, [pathname]);

  const refreshUnreadCount = useCallback(async () => {
    try {
      const count = await getUnreadMessagesCountAction();
      setUnreadCount(count);
    } catch {
      // Ignore background refresh errors
    }
  }, []);

  useEffect(() => {
    refreshUnreadCount();
  }, [refreshUnreadCount]);

  useEffect(() => {
    let isMounted = true;
    const apiUrl =
      process.env.NEXT_PUBLIC_API_URL ||
      process.env.API_URL ||
      "http://localhost:5197";

    const connectHub = async () => {
      try {
        const token = await getChatTokenAction();
        if (!token || !isMounted) return;

        const connection = new signalR.HubConnectionBuilder()
          .withUrl(`${apiUrl}/chatHub`, {
            accessTokenFactory: async () => {
              const freshToken = await getChatTokenAction();
              return freshToken || token;
            },
            skipNegotiation: false,
            transport:
              signalR.HttpTransportType.WebSockets |
              signalR.HttpTransportType.ServerSentEvents,
          })
          .withAutomaticReconnect()
          .build();

        connection.on("ReceiveMessage", (msg: MessageDto) => {
          if (!isMounted) return;

          // If not currently in messages tab, increment unread count and show in-app banner
          if (pathnameRef.current !== "/admin/messages") {
            setUnreadCount((prev) => prev + 1);

            if (alertTimerRef.current) {
              clearTimeout(alertTimerRef.current);
            }

            setActiveAlert({
              id: `${msg.id}-${Date.now()}`,
              senderName: msg.senderName || "New message",
              content: msg.content,
              threadId: msg.threadId,
              senderAvatarUrl: msg.senderAvatarUrl,
            });

            alertTimerRef.current = setTimeout(() => {
              setActiveAlert(null);
            }, 5000);
          }
        });

        connection.on("UnreadCountChanged", (count: number) => {
          if (!isMounted) return;
          setUnreadCount(count);
        });

        await connection.start();
        if (isMounted) {
          hubConnectionRef.current = connection;
          setHubConnection(connection);
        } else {
          connection.stop().catch(() => {});
        }
      } catch (err: unknown) {
        const error = err as Error | null;
        if (
          error?.message?.includes("stopped during negotiation") ||
          error?.name === "AbortError"
        ) {
          return;
        }
      }
    };

    connectHub();

    return () => {
      isMounted = false;
      if (alertTimerRef.current) {
        clearTimeout(alertTimerRef.current);
      }
      if (hubConnectionRef.current) {
        const conn = hubConnectionRef.current;
        hubConnectionRef.current = null;
        setHubConnection(null);
        if (conn.state === signalR.HubConnectionState.Connected) {
          conn.stop().catch(() => {});
        }
      }
    };
  }, []);

  const handleDismissAlert = () => {
    if (alertTimerRef.current) {
      clearTimeout(alertTimerRef.current);
    }
    setActiveAlert(null);
  };

  const handleOpenAlert = () => {
    if (activeAlert) {
      handleDismissAlert();
      router.push("/admin/messages");
    }
  };

  return (
    <MessagingContext.Provider
      value={{ unreadCount, setUnreadCount, refreshUnreadCount, hubConnection }}
    >
      {children}

      {/* WhatsApp-style floating in-app notification toast */}
      <AnimatePresence>
        {activeAlert && (
          <motion.div
            initial={{ opacity: 0, y: -20, scale: 0.95 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: -20, scale: 0.95 }}
            transition={{ duration: 0.2 }}
            className="fixed top-6 right-6 z-50 max-w-sm w-full bg-white border border-slate-200/90 rounded-2xl shadow-xl p-4 flex items-start gap-3 cursor-pointer group"
            onClick={handleOpenAlert}
          >
            <div className="w-10 h-10 rounded-full bg-emerald-50 text-emerald-600 flex items-center justify-center shrink-0 border border-emerald-100">
              <MessageSquare className="w-5 h-5" />
            </div>

            <div className="flex-1 min-w-0">
              <div className="flex items-center justify-between gap-1 mb-0.5">
                <p className="text-sm font-bold text-slate-900 truncate">
                  {activeAlert.senderName}
                </p>
                <span className="text-[10px] font-semibold text-emerald-600 bg-emerald-50 px-1.5 py-0.5 rounded-full">
                  Now
                </span>
              </div>
              <p className="text-xs text-slate-600 line-clamp-2">
                {activeAlert.content}
              </p>
            </div>

            <button
              onClick={(e) => {
                e.stopPropagation();
                handleDismissAlert();
              }}
              className="p-1 rounded-lg text-slate-400 hover:text-slate-600 hover:bg-slate-100 transition-colors shrink-0"
              aria-label="Dismiss notification"
            >
              <X className="w-4 h-4" />
            </button>
          </motion.div>
        )}
      </AnimatePresence>
    </MessagingContext.Provider>
  );
}
