"use client";

import { useState, useEffect } from "react";
import { 
  Camera, MapPin, Calendar, Star, Edit2, 
  Plus, X, Loader2, Save, ExternalLink
} from "lucide-react";
import { toast } from "sonner";

import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Separator } from "@/components/ui/separator";
import { Switch } from "@/components/ui/switch";
import api, { endpoints } from "@/lib/api";
import { useAuthStore } from "@/lib/auth-store";

const ALL_GENRES = [
  "Rock", "Jazz", "Pop", "Hip Hop", "Electronic", "Classical",
  "Country", "R&B", "Blues", "Folk", "Metal", "Punk",
  "Reggae", "Soul", "Indie", "Alternative"
];

interface Profile {
  id: string;
  displayName?: string;
  venueName?: string;
  bio?: string;
  description?: string;
  photo?: string;
  photos?: string[];
  genres?: string[];
  location?: string;
  performerType?: string;
  venueType?: string;
  yearsExperience?: number;
  capacity?: number;
  rating?: number;
  totalReviews?: number;
  isProfileVisible: boolean;
  hasCompletedSetup: boolean;
}

export default function ProfilePage() {
  const { user } = useAuthStore();
  const [profile, setProfile] = useState<Profile | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isSaving, setIsSaving] = useState(false);
  const [isEditing, setIsEditing] = useState(false);
  const [editedProfile, setEditedProfile] = useState<Partial<Profile>>({});

  useEffect(() => {
    loadProfile();
  }, []);

  const loadProfile = async () => {
    try {
      const response = await api.get(endpoints.auth.profile);
      setProfile(response.data.profile);
      setEditedProfile(response.data.profile || {});
    } catch {
      toast.error("Failed to load profile");
    } finally {
      setIsLoading(false);
    }
  };

  const handleSave = async () => {
    setIsSaving(true);
    try {
      const endpoint = user?.role === "artist"
        ? endpoints.artists.update(profile?.id || "")
        : endpoints.venues.update(profile?.id || "");
      
      await api.patch(endpoint, editedProfile);
      setProfile({ ...profile, ...editedProfile } as Profile);
      setIsEditing(false);
      toast.success("Profile updated successfully");
    } catch {
      toast.error("Failed to update profile");
    } finally {
      setIsSaving(false);
    }
  };

  const toggleGenre = (genre: string) => {
    const currentGenres = editedProfile.genres || [];
    setEditedProfile({
      ...editedProfile,
      genres: currentGenres.includes(genre)
        ? currentGenres.filter((g) => g !== genre)
        : [...currentGenres, genre],
    });
  };

  if (isLoading) {
    return (
      <div className="flex items-center justify-center min-h-[60vh]">
        <Loader2 className="w-8 h-8 animate-spin text-primary" />
      </div>
    );
  }

  const isArtist = user?.role === "artist";
  const name = isArtist ? profile?.displayName : profile?.venueName;
  const description = isArtist ? profile?.bio : profile?.description;

  return (
    <div className="max-w-3xl mx-auto space-y-6">
      {/* Header Card */}
      <Card className="overflow-hidden">
        {/* Cover Photo */}
        <div className="h-32 bg-gradient-to-r from-primary/20 via-primary/10 to-primary/20 relative">
          <Button
            variant="secondary"
            size="sm"
            className="absolute top-4 right-4 gap-2"
          >
            <Camera className="w-4 h-4" />
            Edit Cover
          </Button>
        </div>

        {/* Profile Info */}
        <CardContent className="pt-0">
          <div className="flex flex-col md:flex-row gap-6 -mt-12">
            {/* Avatar */}
            <div className="relative">
              <Avatar className="w-28 h-28 border-4 border-background">
                <AvatarImage src={profile?.photo} />
                <AvatarFallback className="bg-primary text-primary-foreground text-3xl">
                  {name?.charAt(0) || user?.fullName?.charAt(0)}
                </AvatarFallback>
              </Avatar>
              <Button
                variant="secondary"
                size="icon"
                className="absolute bottom-0 right-0 rounded-full w-8 h-8"
              >
                <Camera className="w-4 h-4" />
              </Button>
            </div>

            {/* Info */}
            <div className="flex-1 pt-4 md:pt-8">
              <div className="flex flex-col md:flex-row md:items-start justify-between gap-4">
                <div>
                  <h1 className="text-2xl font-bold">{name || user?.fullName}</h1>
                  <div className="flex flex-wrap items-center gap-3 text-muted-foreground mt-1">
                    <Badge variant="secondary" className="capitalize">
                      {user?.role}
                    </Badge>
                    {profile?.location && (
                      <span className="flex items-center gap-1">
                        <MapPin className="w-4 h-4" />
                        {profile.location}
                      </span>
                    )}
                    {profile?.yearsExperience && (
                      <span className="flex items-center gap-1">
                        <Calendar className="w-4 h-4" />
                        {profile.yearsExperience} years exp.
                      </span>
                    )}
                    {profile?.rating && (
                      <span className="flex items-center gap-1 text-yellow-500">
                        <Star className="w-4 h-4 fill-current" />
                        {profile.rating} ({profile.totalReviews} reviews)
                      </span>
                    )}
                  </div>
                </div>

                <div className="flex gap-2">
                  {isEditing ? (
                    <>
                      <Button
                        variant="outline"
                        onClick={() => {
                          setIsEditing(false);
                          setEditedProfile(profile || {});
                        }}
                      >
                        Cancel
                      </Button>
                      <Button onClick={handleSave} disabled={isSaving}>
                        {isSaving ? (
                          <Loader2 className="w-4 h-4 animate-spin mr-2" />
                        ) : (
                          <Save className="w-4 h-4 mr-2" />
                        )}
                        Save
                      </Button>
                    </>
                  ) : (
                    <Button onClick={() => setIsEditing(true)}>
                      <Edit2 className="w-4 h-4 mr-2" />
                      Edit Profile
                    </Button>
                  )}
                </div>
              </div>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Tabs */}
      <Tabs defaultValue="about" className="space-y-6">
        <TabsList>
          <TabsTrigger value="about">About</TabsTrigger>
          <TabsTrigger value="photos">Photos</TabsTrigger>
          <TabsTrigger value="settings">Settings</TabsTrigger>
        </TabsList>

        {/* About Tab */}
        <TabsContent value="about" className="space-y-6">
          {/* Bio/Description */}
          <Card>
            <CardHeader>
              <CardTitle className="text-lg">
                {isArtist ? "Bio" : "Description"}
              </CardTitle>
            </CardHeader>
            <CardContent>
              {isEditing ? (
                <Textarea
                  value={isArtist ? editedProfile.bio : editedProfile.description}
                  onChange={(e) =>
                    setEditedProfile({
                      ...editedProfile,
                      [isArtist ? "bio" : "description"]: e.target.value,
                    })
                  }
                  placeholder={`Tell ${isArtist ? "venues" : "artists"} about yourself...`}
                  className="min-h-[150px]"
                />
              ) : (
                <p className="text-muted-foreground whitespace-pre-wrap">
                  {description || "No description yet. Click edit to add one!"}
                </p>
              )}
            </CardContent>
          </Card>

          {/* Genres (Artist only) */}
          {isArtist && (
            <Card>
              <CardHeader>
                <CardTitle className="text-lg">Genres</CardTitle>
              </CardHeader>
              <CardContent>
                {isEditing ? (
                  <div className="flex flex-wrap gap-2">
                    {ALL_GENRES.map((genre) => (
                      <Badge
                        key={genre}
                        variant={
                          editedProfile.genres?.includes(genre)
                            ? "default"
                            : "outline"
                        }
                        className="cursor-pointer"
                        onClick={() => toggleGenre(genre)}
                      >
                        {editedProfile.genres?.includes(genre) && (
                          <X className="w-3 h-3 mr-1" />
                        )}
                        {genre}
                      </Badge>
                    ))}
                  </div>
                ) : (
                  <div className="flex flex-wrap gap-2">
                    {profile?.genres?.length ? (
                      profile.genres.map((genre) => (
                        <Badge key={genre} variant="secondary">
                          {genre}
                        </Badge>
                      ))
                    ) : (
                      <p className="text-muted-foreground">No genres selected</p>
                    )}
                  </div>
                )}
              </CardContent>
            </Card>
          )}

          {/* Additional Info */}
          <Card>
            <CardHeader>
              <CardTitle className="text-lg">Details</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              {isArtist ? (
                <>
                  <div className="grid grid-cols-2 gap-4">
                    <div className="space-y-2">
                      <Label>Performer Type</Label>
                      {isEditing ? (
                        <Input
                          value={editedProfile.performerType || ""}
                          onChange={(e) =>
                            setEditedProfile({
                              ...editedProfile,
                              performerType: e.target.value,
                            })
                          }
                          placeholder="e.g., Solo, Band, DJ"
                        />
                      ) : (
                        <p className="text-muted-foreground">
                          {profile?.performerType || "Not specified"}
                        </p>
                      )}
                    </div>
                    <div className="space-y-2">
                      <Label>Years Experience</Label>
                      {isEditing ? (
                        <Input
                          type="number"
                          value={editedProfile.yearsExperience || ""}
                          onChange={(e) =>
                            setEditedProfile({
                              ...editedProfile,
                              yearsExperience: parseInt(e.target.value),
                            })
                          }
                          placeholder="0"
                        />
                      ) : (
                        <p className="text-muted-foreground">
                          {profile?.yearsExperience || "Not specified"}
                        </p>
                      )}
                    </div>
                  </div>
                </>
              ) : (
                <>
                  <div className="grid grid-cols-2 gap-4">
                    <div className="space-y-2">
                      <Label>Venue Type</Label>
                      {isEditing ? (
                        <Input
                          value={editedProfile.venueType || ""}
                          onChange={(e) =>
                            setEditedProfile({
                              ...editedProfile,
                              venueType: e.target.value,
                            })
                          }
                          placeholder="e.g., Bar, Club, Restaurant"
                        />
                      ) : (
                        <p className="text-muted-foreground">
                          {profile?.venueType || "Not specified"}
                        </p>
                      )}
                    </div>
                    <div className="space-y-2">
                      <Label>Capacity</Label>
                      {isEditing ? (
                        <Input
                          type="number"
                          value={editedProfile.capacity || ""}
                          onChange={(e) =>
                            setEditedProfile({
                              ...editedProfile,
                              capacity: parseInt(e.target.value),
                            })
                          }
                          placeholder="0"
                        />
                      ) : (
                        <p className="text-muted-foreground">
                          {profile?.capacity || "Not specified"}
                        </p>
                      )}
                    </div>
                  </div>
                </>
              )}
            </CardContent>
          </Card>
        </TabsContent>

        {/* Photos Tab */}
        <TabsContent value="photos">
          <Card>
            <CardHeader>
              <div className="flex items-center justify-between">
                <CardTitle className="text-lg">Photos</CardTitle>
                <Button size="sm">
                  <Plus className="w-4 h-4 mr-2" />
                  Add Photo
                </Button>
              </div>
            </CardHeader>
            <CardContent>
              {profile?.photos?.length ? (
                <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
                  {profile.photos.map((photo, index) => (
                    <div
                      key={index}
                      className="aspect-square rounded-lg bg-muted overflow-hidden relative group"
                    >
                      <img
                        src={photo}
                        alt={`Photo ${index + 1}`}
                        className="w-full h-full object-cover"
                      />
                      <div className="absolute inset-0 bg-black/50 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center gap-2">
                        <Button size="icon" variant="secondary">
                          <ExternalLink className="w-4 h-4" />
                        </Button>
                        <Button size="icon" variant="destructive">
                          <X className="w-4 h-4" />
                        </Button>
                      </div>
                    </div>
                  ))}
                </div>
              ) : (
                <div className="text-center py-12 text-muted-foreground">
                  <Camera className="w-12 h-12 mx-auto mb-4 opacity-50" />
                  <p>No photos yet. Add some to showcase your work!</p>
                </div>
              )}
            </CardContent>
          </Card>
        </TabsContent>

        {/* Settings Tab */}
        <TabsContent value="settings">
          <Card>
            <CardHeader>
              <CardTitle className="text-lg">Profile Settings</CardTitle>
            </CardHeader>
            <CardContent className="space-y-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="font-medium">Profile Visibility</p>
                  <p className="text-sm text-muted-foreground">
                    Make your profile visible to others
                  </p>
                </div>
                <Switch
                  checked={profile?.isProfileVisible}
                  onCheckedChange={async (checked) => {
                    try {
                      const endpoint = isArtist
                        ? endpoints.artists.update(profile?.id || "")
                        : endpoints.venues.update(profile?.id || "");
                      await api.patch(endpoint, { isProfileVisible: checked });
                      setProfile((prev) =>
                        prev ? { ...prev, isProfileVisible: checked } : null
                      );
                      toast.success(
                        checked
                          ? "Profile is now visible"
                          : "Profile is now hidden"
                      );
                    } catch {
                      toast.error("Failed to update visibility");
                    }
                  }}
                />
              </div>
              <Separator />
              <div className="space-y-2">
                <p className="font-medium">Account</p>
                <p className="text-sm text-muted-foreground">
                  Email: {user?.email}
                </p>
                <p className="text-sm text-muted-foreground capitalize">
                  Role: {user?.role}
                </p>
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  );
}
