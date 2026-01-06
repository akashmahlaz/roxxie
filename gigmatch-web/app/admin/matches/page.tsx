"use client";

import { useState, useEffect, useCallback } from "react";
import { 
  Search, MoreHorizontal, Trash2, Eye, Heart, 
  MessageSquare, Loader2, Download, CheckCircle,
  XCircle, Calendar, ArrowRight
} from "lucide-react";
import { toast } from "sonner";
import { format } from "date-fns";

import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Checkbox } from "@/components/ui/checkbox";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import {
  Card,
  CardContent,
} from "@/components/ui/card";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
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
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import api, { endpoints } from "@/lib/api";

interface Match {
  id: string;
  artistId: string;
  venueId: string;
  status: "active" | "archived" | "blocked";
  messageCount: number;
  lastMessageAt?: string;
  createdAt: string;
  artist: {
    id: string;
    displayName: string;
    photo?: string;
  };
  venue: {
    id: string;
    venueName: string;
    photo?: string;
  };
}

export default function MatchesPage() {
  const [matches, setMatches] = useState<Match[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState("");
  const [statusFilter, setStatusFilter] = useState<string>("all");
  const [selectedMatches, setSelectedMatches] = useState<string[]>([]);
  
  const [showDeleteDialog, setShowDeleteDialog] = useState(false);
  const [showViewDialog, setShowViewDialog] = useState(false);
  const [currentMatch, setCurrentMatch] = useState<Match | null>(null);

  const loadMatches = useCallback(async () => {
    try {
      const response = await api.get(endpoints.admin.matches);
      setMatches(response.data.matches || response.data);
    } catch {
      // Mock data
      setMatches([
        { id: "1", artistId: "a1", venueId: "v1", status: "active", messageCount: 45, lastMessageAt: "2024-01-15T10:30:00", createdAt: "2024-01-10", artist: { id: "a1", displayName: "John Doe" }, venue: { id: "v1", venueName: "Jazz Club NYC" } },
        { id: "2", artistId: "a2", venueId: "v2", status: "active", messageCount: 12, lastMessageAt: "2024-01-14T15:20:00", createdAt: "2024-01-08", artist: { id: "a2", displayName: "Sarah Smith" }, venue: { id: "v2", venueName: "Rock Arena LA" } },
        { id: "3", artistId: "a3", venueId: "v1", status: "archived", messageCount: 8, createdAt: "2024-01-05", artist: { id: "a3", displayName: "The Rockers" }, venue: { id: "v1", venueName: "Jazz Club NYC" } },
        { id: "4", artistId: "a1", venueId: "v3", status: "blocked", messageCount: 3, createdAt: "2024-01-03", artist: { id: "a1", displayName: "John Doe" }, venue: { id: "v3", venueName: "Blues Bar Chicago" } },
        { id: "5", artistId: "a4", venueId: "v4", status: "active", messageCount: 28, lastMessageAt: "2024-01-15T08:00:00", createdAt: "2024-01-12", artist: { id: "a4", displayName: "DJ Mike" }, venue: { id: "v4", venueName: "Sky Lounge Miami" } },
      ]);
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    loadMatches();
  }, [loadMatches]);

  const filteredMatches = matches.filter((match) => {
    const matchesSearch = 
      match.artist.displayName.toLowerCase().includes(searchQuery.toLowerCase()) ||
      match.venue.venueName.toLowerCase().includes(searchQuery.toLowerCase());
    const matchesStatus = statusFilter === "all" || match.status === statusFilter;
    return matchesSearch && matchesStatus;
  });

  const handleDelete = async () => {
    if (!currentMatch) return;
    try {
      await api.delete(`${endpoints.admin.matches}/${currentMatch.id}`);
      toast.success("Match deleted successfully");
      setShowDeleteDialog(false);
      setCurrentMatch(null);
      loadMatches();
    } catch {
      toast.error("Failed to delete match");
    }
  };

  const handleStatusChange = async (matchId: string, newStatus: string) => {
    try {
      await api.patch(`${endpoints.admin.matches}/${matchId}`, { status: newStatus });
      toast.success("Status updated");
      loadMatches();
    } catch {
      toast.error("Failed to update status");
    }
  };

  const handleBulkDelete = async () => {
    try {
      await Promise.all(
        selectedMatches.map((id) => api.delete(`${endpoints.admin.matches}/${id}`))
      );
      toast.success(`${selectedMatches.length} matches deleted`);
      setSelectedMatches([]);
      loadMatches();
    } catch {
      toast.error("Failed to delete matches");
    }
  };

  const getStatusBadge = (status: string) => {
    switch (status) {
      case "active":
        return <Badge className="bg-green-500">Active</Badge>;
      case "archived":
        return <Badge variant="secondary">Archived</Badge>;
      case "blocked":
        return <Badge variant="destructive">Blocked</Badge>;
      default:
        return <Badge variant="outline">{status}</Badge>;
    }
  };

  if (isLoading) {
    return (
      <div className="flex items-center justify-center min-h-[60vh]">
        <Loader2 className="w-8 h-8 animate-spin text-primary" />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">Matches</h1>
          <p className="text-muted-foreground">
            View and manage all matches
          </p>
        </div>
        <Button variant="outline">
          <Download className="w-4 h-4 mr-2" />
          Export
        </Button>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-4 gap-4">
        <Card>
          <CardContent className="pt-6">
            <div className="text-2xl font-bold">{matches.length}</div>
            <p className="text-xs text-muted-foreground">Total Matches</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6">
            <div className="text-2xl font-bold">
              {matches.filter((m) => m.status === "active").length}
            </div>
            <p className="text-xs text-muted-foreground">Active</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6">
            <div className="text-2xl font-bold">
              {matches.reduce((acc, m) => acc + m.messageCount, 0)}
            </div>
            <p className="text-xs text-muted-foreground">Total Messages</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6">
            <div className="text-2xl font-bold">
              {Math.round(matches.reduce((acc, m) => acc + m.messageCount, 0) / matches.length)}
            </div>
            <p className="text-xs text-muted-foreground">Avg. Messages</p>
          </CardContent>
        </Card>
      </div>

      {/* Filters */}
      <Card>
        <CardContent className="pt-6">
          <div className="flex flex-col md:flex-row gap-4">
            <div className="relative flex-1">
              <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
              <Input
                placeholder="Search by artist or venue..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="pl-8"
              />
            </div>
            <Select value={statusFilter} onValueChange={setStatusFilter}>
              <SelectTrigger className="w-[150px]">
                <SelectValue placeholder="Status" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All Status</SelectItem>
                <SelectItem value="active">Active</SelectItem>
                <SelectItem value="archived">Archived</SelectItem>
                <SelectItem value="blocked">Blocked</SelectItem>
              </SelectContent>
            </Select>
          </div>
        </CardContent>
      </Card>

      {/* Bulk Actions */}
      {selectedMatches.length > 0 && (
        <Card>
          <CardContent className="py-3">
            <div className="flex items-center justify-between">
              <span className="text-sm text-muted-foreground">
                {selectedMatches.length} match(es) selected
              </span>
              <div className="flex gap-2">
                <Button variant="outline" size="sm" onClick={() => setSelectedMatches([])}>
                  Clear
                </Button>
                <Button
                  variant="destructive"
                  size="sm"
                  onClick={handleBulkDelete}
                >
                  Delete Selected
                </Button>
              </div>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Table */}
      <Card>
        <CardContent className="p-0">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead className="w-12">
                  <Checkbox
                    checked={selectedMatches.length === filteredMatches.length && filteredMatches.length > 0}
                    onCheckedChange={(checked) => {
                      if (checked) {
                        setSelectedMatches(filteredMatches.map((m) => m.id));
                      } else {
                        setSelectedMatches([]);
                      }
                    }}
                  />
                </TableHead>
                <TableHead>Match</TableHead>
                <TableHead>Status</TableHead>
                <TableHead>Messages</TableHead>
                <TableHead>Last Activity</TableHead>
                <TableHead>Created</TableHead>
                <TableHead className="w-12"></TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {filteredMatches.map((match) => (
                <TableRow key={match.id}>
                  <TableCell>
                    <Checkbox
                      checked={selectedMatches.includes(match.id)}
                      onCheckedChange={(checked) => {
                        if (checked) {
                          setSelectedMatches([...selectedMatches, match.id]);
                        } else {
                          setSelectedMatches(selectedMatches.filter((id) => id !== match.id));
                        }
                      }}
                    />
                  </TableCell>
                  <TableCell>
                    <div className="flex items-center gap-2">
                      <Avatar className="w-8 h-8">
                        <AvatarImage src={match.artist.photo} />
                        <AvatarFallback className="bg-primary/10 text-primary text-xs">
                          {match.artist.displayName.charAt(0)}
                        </AvatarFallback>
                      </Avatar>
                      <span className="font-medium text-sm">{match.artist.displayName}</span>
                      <ArrowRight className="w-4 h-4 text-muted-foreground" />
                      <Avatar className="w-8 h-8">
                        <AvatarImage src={match.venue.photo} />
                        <AvatarFallback className="bg-primary/10 text-primary text-xs">
                          {match.venue.venueName.charAt(0)}
                        </AvatarFallback>
                      </Avatar>
                      <span className="font-medium text-sm">{match.venue.venueName}</span>
                    </div>
                  </TableCell>
                  <TableCell>
                    {getStatusBadge(match.status)}
                  </TableCell>
                  <TableCell>
                    <div className="flex items-center gap-1">
                      <MessageSquare className="w-4 h-4 text-muted-foreground" />
                      {match.messageCount}
                    </div>
                  </TableCell>
                  <TableCell className="text-muted-foreground">
                    {match.lastMessageAt 
                      ? format(new Date(match.lastMessageAt), "MMM d, h:mm a")
                      : "No messages"}
                  </TableCell>
                  <TableCell className="text-muted-foreground">
                    {format(new Date(match.createdAt), "MMM d, yyyy")}
                  </TableCell>
                  <TableCell>
                    <DropdownMenu>
                      <DropdownMenuTrigger asChild>
                        <Button variant="ghost" size="icon">
                          <MoreHorizontal className="w-4 h-4" />
                        </Button>
                      </DropdownMenuTrigger>
                      <DropdownMenuContent align="end">
                        <DropdownMenuLabel>Actions</DropdownMenuLabel>
                        <DropdownMenuSeparator />
                        <DropdownMenuItem
                          onClick={() => {
                            setCurrentMatch(match);
                            setShowViewDialog(true);
                          }}
                        >
                          <Eye className="w-4 h-4 mr-2" />
                          View Details
                        </DropdownMenuItem>
                        <DropdownMenuSeparator />
                        {match.status !== "active" && (
                          <DropdownMenuItem
                            onClick={() => handleStatusChange(match.id, "active")}
                          >
                            <CheckCircle className="w-4 h-4 mr-2" />
                            Set Active
                          </DropdownMenuItem>
                        )}
                        {match.status !== "archived" && (
                          <DropdownMenuItem
                            onClick={() => handleStatusChange(match.id, "archived")}
                          >
                            <XCircle className="w-4 h-4 mr-2" />
                            Archive
                          </DropdownMenuItem>
                        )}
                        <DropdownMenuItem
                          className="text-destructive"
                          onClick={() => {
                            setCurrentMatch(match);
                            setShowDeleteDialog(true);
                          }}
                        >
                          <Trash2 className="w-4 h-4 mr-2" />
                          Delete
                        </DropdownMenuItem>
                      </DropdownMenuContent>
                    </DropdownMenu>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </CardContent>
      </Card>

      {/* View Dialog */}
      <Dialog open={showViewDialog} onOpenChange={setShowViewDialog}>
        <DialogContent className="max-w-md">
          <DialogHeader>
            <DialogTitle>Match Details</DialogTitle>
          </DialogHeader>
          {currentMatch && (
            <div className="space-y-6">
              <div className="flex items-center justify-center gap-4">
                <div className="text-center">
                  <Avatar className="w-16 h-16 mx-auto">
                    <AvatarImage src={currentMatch.artist.photo} />
                    <AvatarFallback className="bg-primary text-primary-foreground text-xl">
                      {currentMatch.artist.displayName.charAt(0)}
                    </AvatarFallback>
                  </Avatar>
                  <p className="font-medium mt-2">{currentMatch.artist.displayName}</p>
                  <Badge variant="outline" className="mt-1">Artist</Badge>
                </div>
                <Heart className="w-8 h-8 text-red-500 fill-red-500" />
                <div className="text-center">
                  <Avatar className="w-16 h-16 mx-auto">
                    <AvatarImage src={currentMatch.venue.photo} />
                    <AvatarFallback className="bg-primary text-primary-foreground text-xl">
                      {currentMatch.venue.venueName.charAt(0)}
                    </AvatarFallback>
                  </Avatar>
                  <p className="font-medium mt-2">{currentMatch.venue.venueName}</p>
                  <Badge variant="outline" className="mt-1">Venue</Badge>
                </div>
              </div>
              <div className="grid grid-cols-2 gap-4 text-sm">
                <div>
                  <p className="text-muted-foreground">Status</p>
                  <div className="mt-1">{getStatusBadge(currentMatch.status)}</div>
                </div>
                <div>
                  <p className="text-muted-foreground">Messages</p>
                  <p className="font-medium">{currentMatch.messageCount}</p>
                </div>
                <div>
                  <p className="text-muted-foreground">Created</p>
                  <p className="font-medium">
                    {format(new Date(currentMatch.createdAt), "MMM d, yyyy")}
                  </p>
                </div>
                <div>
                  <p className="text-muted-foreground">Last Activity</p>
                  <p className="font-medium">
                    {currentMatch.lastMessageAt 
                      ? format(new Date(currentMatch.lastMessageAt), "MMM d, h:mm a")
                      : "No activity"}
                  </p>
                </div>
              </div>
            </div>
          )}
          <DialogFooter>
            <Button variant="outline" onClick={() => setShowViewDialog(false)}>
              Close
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Delete Dialog */}
      <AlertDialog open={showDeleteDialog} onOpenChange={setShowDeleteDialog}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Delete Match</AlertDialogTitle>
            <AlertDialogDescription>
              Are you sure you want to delete this match between{" "}
              {currentMatch?.artist.displayName} and {currentMatch?.venue.venueName}? 
              This will also delete all messages. This action cannot be undone.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancel</AlertDialogCancel>
            <AlertDialogAction
              onClick={handleDelete}
              className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
            >
              Delete
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  );
}
