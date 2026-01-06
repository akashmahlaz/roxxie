"use client";

import { useState, useEffect, useCallback } from "react";
import { 
  Search, Plus, MoreHorizontal, Pencil, Trash2, 
  Eye, Star, Music2, MapPin, Calendar, Loader2,
  Download, CheckCircle, XCircle
} from "lucide-react";
import { toast } from "sonner";

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
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import api, { endpoints } from "@/lib/api";
import { cn } from "@/lib/utils";

const ALL_GENRES = [
  "Rock", "Jazz", "Pop", "Hip Hop", "Electronic", "Classical",
  "Country", "R&B", "Blues", "Folk", "Metal", "Punk",
];

interface Artist {
  id: string;
  userId: string;
  displayName: string;
  bio?: string;
  photo?: string;
  genres: string[];
  location?: string;
  performerType?: string;
  yearsExperience?: number;
  rating?: number;
  totalReviews?: number;
  isVerified: boolean;
  isProfileVisible: boolean;
  hasCompletedSetup: boolean;
  createdAt: string;
  user?: {
    email: string;
    status: string;
  };
}

export default function ArtistsPage() {
  const [artists, setArtists] = useState<Artist[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState("");
  const [genreFilter, setGenreFilter] = useState<string>("all");
  const [verifiedFilter, setVerifiedFilter] = useState<string>("all");
  const [selectedArtists, setSelectedArtists] = useState<string[]>([]);
  
  const [showEditDialog, setShowEditDialog] = useState(false);
  const [showDeleteDialog, setShowDeleteDialog] = useState(false);
  const [showViewDialog, setShowViewDialog] = useState(false);
  const [currentArtist, setCurrentArtist] = useState<Artist | null>(null);
  const [isSaving, setIsSaving] = useState(false);

  const [formData, setFormData] = useState({
    displayName: "",
    bio: "",
    location: "",
    performerType: "",
    yearsExperience: 0,
    genres: [] as string[],
    isVerified: false,
    isProfileVisible: true,
  });

  const loadArtists = useCallback(async () => {
    try {
      const response = await api.get(endpoints.admin.artists);
      setArtists(response.data.artists || response.data);
    } catch {
      // Mock data
      setArtists([
        { id: "1", userId: "u1", displayName: "John Doe", bio: "Experienced rock guitarist", genres: ["Rock", "Blues"], location: "New York", performerType: "Solo", yearsExperience: 10, rating: 4.8, totalReviews: 24, isVerified: true, isProfileVisible: true, hasCompletedSetup: true, createdAt: "2024-01-15", user: { email: "john@example.com", status: "active" } },
        { id: "2", userId: "u2", displayName: "Sarah Smith", bio: "Jazz vocalist", genres: ["Jazz", "Soul"], location: "Chicago", performerType: "Solo", yearsExperience: 5, rating: 4.5, totalReviews: 12, isVerified: true, isProfileVisible: true, hasCompletedSetup: true, createdAt: "2024-01-13", user: { email: "sarah@example.com", status: "active" } },
        { id: "3", userId: "u3", displayName: "The Rockers", bio: "Classic rock band", genres: ["Rock", "Classic Rock"], location: "Los Angeles", performerType: "Band", yearsExperience: 15, rating: 4.9, totalReviews: 45, isVerified: false, isProfileVisible: true, hasCompletedSetup: true, createdAt: "2024-01-10", user: { email: "rockers@band.com", status: "active" } },
        { id: "4", userId: "u4", displayName: "DJ Mike", bio: "Electronic music DJ", genres: ["Electronic", "House"], location: "Miami", performerType: "DJ", yearsExperience: 8, rating: 4.3, totalReviews: 18, isVerified: true, isProfileVisible: false, hasCompletedSetup: true, createdAt: "2024-01-08", user: { email: "dj.mike@example.com", status: "inactive" } },
      ]);
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    loadArtists();
  }, [loadArtists]);

  const filteredArtists = artists.filter((artist) => {
    const matchesSearch = 
      artist.displayName.toLowerCase().includes(searchQuery.toLowerCase()) ||
      artist.bio?.toLowerCase().includes(searchQuery.toLowerCase()) ||
      artist.location?.toLowerCase().includes(searchQuery.toLowerCase());
    const matchesGenre = genreFilter === "all" || artist.genres.includes(genreFilter);
    const matchesVerified = 
      verifiedFilter === "all" || 
      (verifiedFilter === "verified" && artist.isVerified) ||
      (verifiedFilter === "unverified" && !artist.isVerified);
    return matchesSearch && matchesGenre && matchesVerified;
  });

  const handleEdit = async () => {
    if (!currentArtist) return;
    setIsSaving(true);
    try {
      await api.patch(`${endpoints.admin.artists}/${currentArtist.id}`, formData);
      toast.success("Artist updated successfully");
      setShowEditDialog(false);
      loadArtists();
    } catch {
      toast.error("Failed to update artist");
    } finally {
      setIsSaving(false);
    }
  };

  const handleDelete = async () => {
    if (!currentArtist) return;
    try {
      await api.delete(`${endpoints.admin.artists}/${currentArtist.id}`);
      toast.success("Artist deleted successfully");
      setShowDeleteDialog(false);
      setCurrentArtist(null);
      loadArtists();
    } catch {
      toast.error("Failed to delete artist");
    }
  };

  const handleVerify = async (artistId: string, verified: boolean) => {
    try {
      await api.patch(`${endpoints.admin.artists}/${artistId}`, { isVerified: verified });
      toast.success(verified ? "Artist verified" : "Verification removed");
      loadArtists();
    } catch {
      toast.error("Failed to update verification");
    }
  };

  const openEditDialog = (artist: Artist) => {
    setCurrentArtist(artist);
    setFormData({
      displayName: artist.displayName,
      bio: artist.bio || "",
      location: artist.location || "",
      performerType: artist.performerType || "",
      yearsExperience: artist.yearsExperience || 0,
      genres: artist.genres,
      isVerified: artist.isVerified,
      isProfileVisible: artist.isProfileVisible,
    });
    setShowEditDialog(true);
  };

  const toggleGenre = (genre: string) => {
    setFormData((prev) => ({
      ...prev,
      genres: prev.genres.includes(genre)
        ? prev.genres.filter((g) => g !== genre)
        : [...prev.genres, genre],
    }));
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
          <h1 className="text-3xl font-bold">Artists</h1>
          <p className="text-muted-foreground">
            Manage artist profiles
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
            <div className="text-2xl font-bold">{artists.length}</div>
            <p className="text-xs text-muted-foreground">Total Artists</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6">
            <div className="text-2xl font-bold">
              {artists.filter((a) => a.isVerified).length}
            </div>
            <p className="text-xs text-muted-foreground">Verified</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6">
            <div className="text-2xl font-bold">
              {artists.filter((a) => a.hasCompletedSetup).length}
            </div>
            <p className="text-xs text-muted-foreground">Complete Profiles</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6">
            <div className="text-2xl font-bold">
              {(artists.reduce((acc, a) => acc + (a.rating || 0), 0) / artists.length).toFixed(1)}
            </div>
            <p className="text-xs text-muted-foreground">Avg. Rating</p>
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
                placeholder="Search artists..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="pl-8"
              />
            </div>
            <Select value={genreFilter} onValueChange={setGenreFilter}>
              <SelectTrigger className="w-[150px]">
                <SelectValue placeholder="Genre" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All Genres</SelectItem>
                {ALL_GENRES.map((genre) => (
                  <SelectItem key={genre} value={genre}>{genre}</SelectItem>
                ))}
              </SelectContent>
            </Select>
            <Select value={verifiedFilter} onValueChange={setVerifiedFilter}>
              <SelectTrigger className="w-[150px]">
                <SelectValue placeholder="Verified" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All</SelectItem>
                <SelectItem value="verified">Verified</SelectItem>
                <SelectItem value="unverified">Unverified</SelectItem>
              </SelectContent>
            </Select>
          </div>
        </CardContent>
      </Card>

      {/* Table */}
      <Card>
        <CardContent className="p-0">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead className="w-12">
                  <Checkbox
                    checked={selectedArtists.length === filteredArtists.length && filteredArtists.length > 0}
                    onCheckedChange={(checked) => {
                      if (checked) {
                        setSelectedArtists(filteredArtists.map((a) => a.id));
                      } else {
                        setSelectedArtists([]);
                      }
                    }}
                  />
                </TableHead>
                <TableHead>Artist</TableHead>
                <TableHead>Genres</TableHead>
                <TableHead>Location</TableHead>
                <TableHead>Rating</TableHead>
                <TableHead>Verified</TableHead>
                <TableHead>Profile</TableHead>
                <TableHead className="w-12"></TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {filteredArtists.map((artist) => (
                <TableRow key={artist.id}>
                  <TableCell>
                    <Checkbox
                      checked={selectedArtists.includes(artist.id)}
                      onCheckedChange={(checked) => {
                        if (checked) {
                          setSelectedArtists([...selectedArtists, artist.id]);
                        } else {
                          setSelectedArtists(selectedArtists.filter((id) => id !== artist.id));
                        }
                      }}
                    />
                  </TableCell>
                  <TableCell>
                    <div className="flex items-center gap-3">
                      <Avatar>
                        <AvatarImage src={artist.photo} />
                        <AvatarFallback className="bg-primary/10 text-primary">
                          {artist.displayName.charAt(0)}
                        </AvatarFallback>
                      </Avatar>
                      <div>
                        <div className="flex items-center gap-2">
                          <p className="font-medium">{artist.displayName}</p>
                          {artist.isVerified && (
                            <CheckCircle className="w-4 h-4 text-blue-500" />
                          )}
                        </div>
                        <p className="text-sm text-muted-foreground">
                          {artist.performerType} • {artist.yearsExperience}y exp.
                        </p>
                      </div>
                    </div>
                  </TableCell>
                  <TableCell>
                    <div className="flex flex-wrap gap-1">
                      {artist.genres.slice(0, 2).map((genre) => (
                        <Badge key={genre} variant="secondary" className="text-xs">
                          {genre}
                        </Badge>
                      ))}
                      {artist.genres.length > 2 && (
                        <Badge variant="outline" className="text-xs">
                          +{artist.genres.length - 2}
                        </Badge>
                      )}
                    </div>
                  </TableCell>
                  <TableCell>
                    <div className="flex items-center gap-1 text-muted-foreground">
                      <MapPin className="w-3 h-3" />
                      {artist.location || "Not set"}
                    </div>
                  </TableCell>
                  <TableCell>
                    {artist.rating ? (
                      <div className="flex items-center gap-1">
                        <Star className="w-4 h-4 fill-yellow-500 text-yellow-500" />
                        <span>{artist.rating}</span>
                        <span className="text-muted-foreground text-xs">
                          ({artist.totalReviews})
                        </span>
                      </div>
                    ) : (
                      <span className="text-muted-foreground">No ratings</span>
                    )}
                  </TableCell>
                  <TableCell>
                    {artist.isVerified ? (
                      <Badge className="bg-blue-500">Verified</Badge>
                    ) : (
                      <Badge variant="outline">Unverified</Badge>
                    )}
                  </TableCell>
                  <TableCell>
                    {artist.isProfileVisible ? (
                      <Badge variant="secondary">Visible</Badge>
                    ) : (
                      <Badge variant="outline">Hidden</Badge>
                    )}
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
                            setCurrentArtist(artist);
                            setShowViewDialog(true);
                          }}
                        >
                          <Eye className="w-4 h-4 mr-2" />
                          View Details
                        </DropdownMenuItem>
                        <DropdownMenuItem onClick={() => openEditDialog(artist)}>
                          <Pencil className="w-4 h-4 mr-2" />
                          Edit
                        </DropdownMenuItem>
                        <DropdownMenuSeparator />
                        {artist.isVerified ? (
                          <DropdownMenuItem
                            onClick={() => handleVerify(artist.id, false)}
                          >
                            <XCircle className="w-4 h-4 mr-2" />
                            Remove Verification
                          </DropdownMenuItem>
                        ) : (
                          <DropdownMenuItem
                            onClick={() => handleVerify(artist.id, true)}
                          >
                            <CheckCircle className="w-4 h-4 mr-2" />
                            Verify Artist
                          </DropdownMenuItem>
                        )}
                        <DropdownMenuItem
                          className="text-destructive"
                          onClick={() => {
                            setCurrentArtist(artist);
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

      {/* Edit Dialog */}
      <Dialog open={showEditDialog} onOpenChange={setShowEditDialog}>
        <DialogContent className="max-w-lg">
          <DialogHeader>
            <DialogTitle>Edit Artist</DialogTitle>
            <DialogDescription>
              Update artist profile information
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-4 py-4 max-h-[60vh] overflow-y-auto">
            <div className="space-y-2">
              <Label>Display Name</Label>
              <Input
                value={formData.displayName}
                onChange={(e) =>
                  setFormData({ ...formData, displayName: e.target.value })
                }
              />
            </div>
            <div className="space-y-2">
              <Label>Bio</Label>
              <Textarea
                value={formData.bio}
                onChange={(e) =>
                  setFormData({ ...formData, bio: e.target.value })
                }
                rows={3}
              />
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>Location</Label>
                <Input
                  value={formData.location}
                  onChange={(e) =>
                    setFormData({ ...formData, location: e.target.value })
                  }
                />
              </div>
              <div className="space-y-2">
                <Label>Performer Type</Label>
                <Input
                  value={formData.performerType}
                  onChange={(e) =>
                    setFormData({ ...formData, performerType: e.target.value })
                  }
                />
              </div>
            </div>
            <div className="space-y-2">
              <Label>Years Experience</Label>
              <Input
                type="number"
                value={formData.yearsExperience}
                onChange={(e) =>
                  setFormData({ ...formData, yearsExperience: parseInt(e.target.value) })
                }
              />
            </div>
            <div className="space-y-2">
              <Label>Genres</Label>
              <div className="flex flex-wrap gap-2">
                {ALL_GENRES.map((genre) => (
                  <Badge
                    key={genre}
                    variant={formData.genres.includes(genre) ? "default" : "outline"}
                    className="cursor-pointer"
                    onClick={() => toggleGenre(genre)}
                  >
                    {genre}
                  </Badge>
                ))}
              </div>
            </div>
            <div className="flex items-center gap-4">
              <div className="flex items-center gap-2">
                <Checkbox
                  id="verified"
                  checked={formData.isVerified}
                  onCheckedChange={(checked) =>
                    setFormData({ ...formData, isVerified: !!checked })
                  }
                />
                <Label htmlFor="verified">Verified</Label>
              </div>
              <div className="flex items-center gap-2">
                <Checkbox
                  id="visible"
                  checked={formData.isProfileVisible}
                  onCheckedChange={(checked) =>
                    setFormData({ ...formData, isProfileVisible: !!checked })
                  }
                />
                <Label htmlFor="visible">Profile Visible</Label>
              </div>
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setShowEditDialog(false)}>
              Cancel
            </Button>
            <Button onClick={handleEdit} disabled={isSaving}>
              {isSaving && <Loader2 className="w-4 h-4 animate-spin mr-2" />}
              Save Changes
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* View Dialog */}
      <Dialog open={showViewDialog} onOpenChange={setShowViewDialog}>
        <DialogContent className="max-w-md">
          <DialogHeader>
            <DialogTitle>Artist Details</DialogTitle>
          </DialogHeader>
          {currentArtist && (
            <div className="space-y-6">
              <div className="flex items-center gap-4">
                <Avatar className="w-16 h-16">
                  <AvatarImage src={currentArtist.photo} />
                  <AvatarFallback className="bg-primary text-primary-foreground text-xl">
                    {currentArtist.displayName.charAt(0)}
                  </AvatarFallback>
                </Avatar>
                <div>
                  <div className="flex items-center gap-2">
                    <h3 className="font-semibold text-lg">{currentArtist.displayName}</h3>
                    {currentArtist.isVerified && (
                      <CheckCircle className="w-5 h-5 text-blue-500" />
                    )}
                  </div>
                  <p className="text-muted-foreground">{currentArtist.user?.email}</p>
                </div>
              </div>
              {currentArtist.bio && (
                <p className="text-sm text-muted-foreground">{currentArtist.bio}</p>
              )}
              <div className="flex flex-wrap gap-2">
                {currentArtist.genres.map((genre) => (
                  <Badge key={genre} variant="secondary">{genre}</Badge>
                ))}
              </div>
              <div className="grid grid-cols-2 gap-4 text-sm">
                <div>
                  <p className="text-muted-foreground">Location</p>
                  <p className="font-medium">{currentArtist.location || "Not set"}</p>
                </div>
                <div>
                  <p className="text-muted-foreground">Type</p>
                  <p className="font-medium">{currentArtist.performerType || "Not set"}</p>
                </div>
                <div>
                  <p className="text-muted-foreground">Experience</p>
                  <p className="font-medium">{currentArtist.yearsExperience} years</p>
                </div>
                <div>
                  <p className="text-muted-foreground">Rating</p>
                  <p className="font-medium">
                    {currentArtist.rating || "No ratings"} ({currentArtist.totalReviews} reviews)
                  </p>
                </div>
              </div>
            </div>
          )}
          <DialogFooter>
            <Button variant="outline" onClick={() => setShowViewDialog(false)}>
              Close
            </Button>
            <Button
              onClick={() => {
                setShowViewDialog(false);
                if (currentArtist) openEditDialog(currentArtist);
              }}
            >
              <Pencil className="w-4 h-4 mr-2" />
              Edit
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Delete Dialog */}
      <AlertDialog open={showDeleteDialog} onOpenChange={setShowDeleteDialog}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Delete Artist</AlertDialogTitle>
            <AlertDialogDescription>
              Are you sure you want to delete {currentArtist?.displayName}? This action
              cannot be undone.
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
