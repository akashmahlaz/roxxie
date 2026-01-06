"use client";

import { useState, useEffect } from "react";
import Link from "next/link";
import { motion } from "framer-motion";
import { MessageSquare, Loader2, Search, Music2 } from "lucide-react";
import { formatDistanceToNow } from "date-fns";

import { Input } from "@/components/ui/input";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Card, CardContent } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import api, { endpoints } from "@/lib/api";
import { cn } from "@/lib/utils";

interface Conversation {
  matchId: string;
  otherUser: {
    id: string;
    name: string;
    photo?: string;
    type: "artist" | "venue";
  };
  lastMessage: {
    content: string;
    createdAt: string;
    isRead: boolean;
    senderId: string;
  };
}

export default function MessagesPage() {
  const [conversations, setConversations] = useState<Conversation[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState("");

  useEffect(() => {
    loadConversations();
  }, []);

  const loadConversations = async () => {
    try {
      const response = await api.get(endpoints.matches.list);
      // Filter to only show matches with messages
      const matchesWithMessages = (response.data.matches || []).filter(
        (m: { lastMessage?: { content: string } }) => m.lastMessage
      );
      setConversations(matchesWithMessages);
    } catch {
      console.error("Failed to load conversations");
    } finally {
      setIsLoading(false);
    }
  };

  const filteredConversations = conversations.filter((conv) =>
    conv.otherUser.name.toLowerCase().includes(searchQuery.toLowerCase())
  );

  if (isLoading) {
    return (
      <div className="flex items-center justify-center min-h-[60vh]">
        <Loader2 className="w-8 h-8 animate-spin text-primary" />
      </div>
    );
  }

  return (
    <div className="max-w-2xl mx-auto space-y-6">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold">Messages</h1>
        <p className="text-muted-foreground">
          {conversations.length} conversations
        </p>
      </div>

      {/* Search */}
      <div className="relative">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
        <Input
          placeholder="Search conversations..."
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          className="pl-10"
        />
      </div>

      {/* Conversations List */}
      {filteredConversations.length > 0 ? (
        <div className="space-y-2">
          {filteredConversations.map((conv, index) => (
            <motion.div
              key={conv.matchId}
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: index * 0.05 }}
            >
              <ConversationCard conversation={conv} />
            </motion.div>
          ))}
        </div>
      ) : (
        <EmptyState hasSearch={searchQuery.length > 0} />
      )}
    </div>
  );
}

function ConversationCard({ conversation }: { conversation: Conversation }) {
  const isUnread = !conversation.lastMessage.isRead;

  return (
    <Link href={`/dashboard/messages/${conversation.matchId}`}>
      <Card
        className={cn(
          "transition-colors hover:bg-muted/50 cursor-pointer",
          isUnread && "bg-primary/5"
        )}
      >
        <CardContent className="p-4">
          <div className="flex items-center gap-4">
            <Avatar className="w-14 h-14">
              <AvatarImage src={conversation.otherUser.photo} />
              <AvatarFallback className="bg-primary/10 text-primary">
                {conversation.otherUser.name.charAt(0)}
              </AvatarFallback>
            </Avatar>

            <div className="flex-1 min-w-0">
              <div className="flex items-center gap-2">
                <span className="font-semibold truncate">
                  {conversation.otherUser.name}
                </span>
                <Badge variant="secondary" className="text-xs capitalize">
                  {conversation.otherUser.type}
                </Badge>
              </div>

              <p
                className={cn(
                  "text-sm truncate",
                  isUnread
                    ? "text-foreground font-medium"
                    : "text-muted-foreground"
                )}
              >
                {conversation.lastMessage.content}
              </p>
            </div>

            <div className="text-right flex-shrink-0">
              <p className="text-xs text-muted-foreground">
                {formatDistanceToNow(new Date(conversation.lastMessage.createdAt), {
                  addSuffix: true,
                })}
              </p>
              {isUnread && (
                <div className="w-3 h-3 rounded-full bg-primary mt-1 ml-auto" />
              )}
            </div>
          </div>
        </CardContent>
      </Card>
    </Link>
  );
}

function EmptyState({ hasSearch }: { hasSearch: boolean }) {
  return (
    <div className="text-center py-12 space-y-4">
      <div className="w-16 h-16 rounded-full bg-primary/10 flex items-center justify-center mx-auto">
        {hasSearch ? (
          <Search className="w-8 h-8 text-primary" />
        ) : (
          <MessageSquare className="w-8 h-8 text-primary" />
        )}
      </div>
      <div>
        <h3 className="font-semibold">
          {hasSearch ? "No results found" : "No messages yet"}
        </h3>
        <p className="text-sm text-muted-foreground">
          {hasSearch
            ? "Try a different search term"
            : "Match with someone and start chatting!"}
        </p>
      </div>
      {!hasSearch && (
        <Link href="/dashboard">
          <motion.button
            whileHover={{ scale: 1.05 }}
            whileTap={{ scale: 0.95 }}
            className="inline-flex items-center gap-2 px-4 py-2 rounded-lg bg-primary text-primary-foreground font-medium"
          >
            <Music2 className="w-4 h-4" />
            Find Matches
          </motion.button>
        </Link>
      )}
    </div>
  );
}
