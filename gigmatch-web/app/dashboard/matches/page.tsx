"use client";

import { useState, useEffect } from "react";
import Link from "next/link";
import { motion } from "framer-motion";
import { 
  MessageSquare, Heart, MoreVertical, Archive, 
  Ban, Music2, Loader2, Search
} from "lucide-react";
import { toast } from "sonner";
import { formatDistanceToNow } from "date-fns";

import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Card, CardContent } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog";
import api, { endpoints } from "@/lib/api";
import { cn } from "@/lib/utils";

interface Match {
  id: string;
  otherUser: {
    id: string;
    name: string;
    photo?: string;
    type: "artist" | "venue";
  };
  lastMessage?: {
    content: string;
    createdAt: string;
    isRead: boolean;
  };
  matchedAt: string;
  isArchived: boolean;
}

export default function MatchesPage() {
  const [matches, setMatches] = useState<Match[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState("");
  const [selectedMatch, setSelectedMatch] = useState<Match | null>(null);
  const [showBlockDialog, setShowBlockDialog] = useState(false);
  const [activeTab, setActiveTab] = useState("all");

  useEffect(() => {
    loadMatches();
  }, []);

  const loadMatches = async () => {
    try {
      const response = await api.get(endpoints.matches.list);
      setMatches(response.data.matches || []);
    } catch {
      toast.error("Failed to load matches");
    } finally {
      setIsLoading(false);
    }
  };

  const handleArchive = async (match: Match) => {
    try {
      await api.post(endpoints.matches.archive(match.id));
      setMatches((prev) =>
        prev.map((m) =>
          m.id === match.id ? { ...m, isArchived: !m.isArchived } : m
        )
      );
      toast.success(match.isArchived ? "Match unarchived" : "Match archived");
    } catch {
      toast.error("Failed to update match");
    }
  };

  const handleBlock = async () => {
    if (!selectedMatch) return;
    try {
      await api.post(endpoints.matches.block(selectedMatch.id));
      setMatches((prev) => prev.filter((m) => m.id !== selectedMatch.id));
      toast.success("User blocked");
      setShowBlockDialog(false);
      setSelectedMatch(null);
    } catch {
      toast.error("Failed to block user");
    }
  };

  const filteredMatches = matches.filter((match) => {
    const matchesSearch = match.otherUser.name
      .toLowerCase()
      .includes(searchQuery.toLowerCase());
    
    if (activeTab === "archived") return match.isArchived && matchesSearch;
    if (activeTab === "unread") return !match.lastMessage?.isRead && matchesSearch;
    return !match.isArchived && matchesSearch;
  });

  const newMatches = filteredMatches.filter((m) => !m.lastMessage);
  const conversations = filteredMatches.filter((m) => m.lastMessage);

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
        <h1 className="text-2xl font-bold">Matches</h1>
        <p className="text-muted-foreground">
          {matches.length} total matches
        </p>
      </div>

      {/* Search */}
      <div className="relative">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
        <Input
          placeholder="Search matches..."
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          className="pl-10"
        />
      </div>

      {/* Tabs */}
      <Tabs value={activeTab} onValueChange={setActiveTab}>
        <TabsList className="grid w-full grid-cols-3">
          <TabsTrigger value="all">All</TabsTrigger>
          <TabsTrigger value="unread">Unread</TabsTrigger>
          <TabsTrigger value="archived">Archived</TabsTrigger>
        </TabsList>

        <TabsContent value={activeTab} className="space-y-6 mt-6">
          {/* New Matches Section */}
          {newMatches.length > 0 && activeTab !== "archived" && (
            <div className="space-y-4">
              <h2 className="text-sm font-semibold text-muted-foreground uppercase tracking-wide">
                New Matches
              </h2>
              <div className="flex gap-4 overflow-x-auto pb-2 -mx-4 px-4">
                {newMatches.map((match) => (
                  <NewMatchCard key={match.id} match={match} />
                ))}
              </div>
            </div>
          )}

          {/* Conversations */}
          {conversations.length > 0 ? (
            <div className="space-y-4">
              {activeTab !== "archived" && newMatches.length > 0 && (
                <h2 className="text-sm font-semibold text-muted-foreground uppercase tracking-wide">
                  Messages
                </h2>
              )}
              <div className="space-y-2">
                {conversations.map((match, index) => (
                  <motion.div
                    key={match.id}
                    initial={{ opacity: 0, y: 10 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ delay: index * 0.05 }}
                  >
                    <MatchCard
                      match={match}
                      onArchive={() => handleArchive(match)}
                      onBlock={() => {
                        setSelectedMatch(match);
                        setShowBlockDialog(true);
                      }}
                    />
                  </motion.div>
                ))}
              </div>
            </div>
          ) : (
            <EmptyState activeTab={activeTab} />
          )}
        </TabsContent>
      </Tabs>

      {/* Block Dialog */}
      <AlertDialog open={showBlockDialog} onOpenChange={setShowBlockDialog}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Block {selectedMatch?.otherUser.name}?</AlertDialogTitle>
            <AlertDialogDescription>
              They won&apos;t be able to contact you and you won&apos;t see them in your matches anymore. This action cannot be undone.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancel</AlertDialogCancel>
            <AlertDialogAction
              onClick={handleBlock}
              className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
            >
              Block
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  );
}

function NewMatchCard({ match }: { match: Match }) {
  return (
    <Link href={`/dashboard/messages/${match.id}`}>
      <motion.div
        whileHover={{ scale: 1.05 }}
        whileTap={{ scale: 0.95 }}
        className="flex flex-col items-center gap-2 flex-shrink-0"
      >
        <div className="relative">
          <Avatar className="w-20 h-20 ring-2 ring-primary ring-offset-2 ring-offset-background">
            <AvatarImage src={match.otherUser.photo} />
            <AvatarFallback className="bg-primary/10 text-primary text-xl">
              {match.otherUser.name.charAt(0)}
            </AvatarFallback>
          </Avatar>
          <div className="absolute -bottom-1 -right-1 w-6 h-6 rounded-full bg-primary flex items-center justify-center">
            <Heart className="w-3 h-3 text-primary-foreground fill-current" />
          </div>
        </div>
        <span className="text-sm font-medium truncate max-w-[80px]">
          {match.otherUser.name}
        </span>
      </motion.div>
    </Link>
  );
}

interface MatchCardProps {
  match: Match;
  onArchive: () => void;
  onBlock: () => void;
}

function MatchCard({ match, onArchive, onBlock }: MatchCardProps) {
  const isUnread = match.lastMessage && !match.lastMessage.isRead;

  return (
    <Card className={cn(
      "transition-colors hover:bg-muted/50",
      isUnread && "bg-primary/5"
    )}>
      <CardContent className="p-4">
        <div className="flex items-center gap-4">
          <Link href={`/dashboard/messages/${match.id}`} className="flex-1 flex items-center gap-4">
            <Avatar className="w-14 h-14">
              <AvatarImage src={match.otherUser.photo} />
              <AvatarFallback className="bg-primary/10 text-primary">
                {match.otherUser.name.charAt(0)}
              </AvatarFallback>
            </Avatar>
            
            <div className="flex-1 min-w-0">
              <div className="flex items-center gap-2">
                <span className="font-semibold truncate">
                  {match.otherUser.name}
                </span>
                <Badge variant="secondary" className="text-xs capitalize">
                  {match.otherUser.type}
                </Badge>
              </div>
              
              {match.lastMessage ? (
                <p className={cn(
                  "text-sm truncate",
                  isUnread ? "text-foreground font-medium" : "text-muted-foreground"
                )}>
                  {match.lastMessage.content}
                </p>
              ) : (
                <p className="text-sm text-muted-foreground italic">
                  Start a conversation!
                </p>
              )}
            </div>

            <div className="text-right flex-shrink-0">
              <p className="text-xs text-muted-foreground">
                {match.lastMessage
                  ? formatDistanceToNow(new Date(match.lastMessage.createdAt), { addSuffix: true })
                  : formatDistanceToNow(new Date(match.matchedAt), { addSuffix: true })}
              </p>
              {isUnread && (
                <div className="w-3 h-3 rounded-full bg-primary mt-1 ml-auto" />
              )}
            </div>
          </Link>

          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <Button variant="ghost" size="icon" className="flex-shrink-0">
                <MoreVertical className="w-4 h-4" />
              </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="end">
              <DropdownMenuItem onClick={onArchive}>
                <Archive className="w-4 h-4 mr-2" />
                {match.isArchived ? "Unarchive" : "Archive"}
              </DropdownMenuItem>
              <DropdownMenuSeparator />
              <DropdownMenuItem onClick={onBlock} className="text-destructive">
                <Ban className="w-4 h-4 mr-2" />
                Block
              </DropdownMenuItem>
            </DropdownMenuContent>
          </DropdownMenu>
        </div>
      </CardContent>
    </Card>
  );
}

function EmptyState({ activeTab }: { activeTab: string }) {
  return (
    <div className="text-center py-12 space-y-4">
      <div className="w-16 h-16 rounded-full bg-primary/10 flex items-center justify-center mx-auto">
        {activeTab === "archived" ? (
          <Archive className="w-8 h-8 text-primary" />
        ) : (
          <Music2 className="w-8 h-8 text-primary" />
        )}
      </div>
      <div>
        <h3 className="font-semibold">
          {activeTab === "archived"
            ? "No archived matches"
            : activeTab === "unread"
            ? "All caught up!"
            : "No matches yet"}
        </h3>
        <p className="text-sm text-muted-foreground">
          {activeTab === "archived"
            ? "Archived conversations will appear here"
            : activeTab === "unread"
            ? "You've read all your messages"
            : "Start swiping to find your perfect match"}
        </p>
      </div>
      {activeTab === "all" && (
        <Link href="/dashboard">
          <Button>Start Discovering</Button>
        </Link>
      )}
    </div>
  );
}
