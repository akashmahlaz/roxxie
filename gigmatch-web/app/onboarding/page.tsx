"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { motion, AnimatePresence } from "framer-motion";
import {
  Music2, Users, Calendar, Star, ArrowRight, ArrowLeft,
  Check, Upload, MapPin, Mic2, Guitar
} from "lucide-react";
import { toast } from "sonner";

import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Badge } from "@/components/ui/badge";
import { Progress } from "@/components/ui/progress";
import { useAuthStore } from "@/lib/auth-store";
import api, { endpoints } from "@/lib/api";
import { cn } from "@/lib/utils";

const GENRES = [
  "Rock", "Jazz", "Pop", "Hip Hop", "Electronic", "Classical",
  "Country", "R&B", "Blues", "Folk", "Metal", "Punk",
  "Reggae", "Soul", "Indie", "Alternative"
];

const VENUE_TYPES = [
  "Bar", "Club", "Restaurant", "Concert Hall", "Theater",
  "Outdoor Venue", "Private Event Space", "Hotel", "Festival Ground"
];

const PERFORMANCE_TYPES = [
  "Solo", "Duo", "Band", "DJ", "Orchestra"
];

interface OnboardingData {
  // Artist fields
  stageName?: string;
  genres?: string[];
  performerType?: string;
  bio?: string;
  yearsExperience?: number;
  // Venue fields
  venueType?: string;
  capacity?: number;
  location?: string;
  description?: string;
  // Common
  photos?: File[];
}

const ONBOARDING_STEPS = {
  artist: ["welcome", "basic", "genres", "bio", "photos", "complete"],
  venue: ["welcome", "basic", "type", "details", "photos", "complete"],
};

export default function OnboardingPage() {
  const router = useRouter();
  const { user } = useAuthStore();
  const role = user?.role || "artist";
  const steps = ONBOARDING_STEPS[role as keyof typeof ONBOARDING_STEPS];

  const [currentStep, setCurrentStep] = useState(0);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [data, setData] = useState<OnboardingData>({
    genres: [],
  });

  const progress = ((currentStep + 1) / steps.length) * 100;
  const currentStepName = steps[currentStep];

  const nextStep = () => {
    if (currentStep < steps.length - 1) {
      setCurrentStep(currentStep + 1);
    }
  };

  const prevStep = () => {
    if (currentStep > 0) {
      setCurrentStep(currentStep - 1);
    }
  };

  const handleComplete = async () => {
    setIsSubmitting(true);
    try {
      const endpoint = role === "artist" ? endpoints.artists.setup : endpoints.venues.setup;

      // Validate required fields before submission
      if (role === "artist") {
        if (!data.stageName || !data.bio || !data.genres || data.genres.length === 0) {
          toast.error("Please complete all required fields", {
            description: "Stage name, bio, and at least one genre are required.",
          });
          setIsSubmitting(false);
          return;
        }
      } else {
        if (!data.location || !data.venueType || !data.description) {
          toast.error("Please complete all required fields", {
            description: "Location, venue type, and description are required.",
          });
          setIsSubmitting(false);
          return;
        }
      }

      // Prepare data - map stageName to displayName for backend
      const submitData = role === "artist"
        ? {
          displayName: data.stageName,
          bio: data.bio,
          genres: data.genres,
          performerType: data.performerType,
          yearsExperience: data.yearsExperience,
        }
        : {
          venueName: data.location,
          venueType: data.venueType,
          description: data.description,
          capacity: data.capacity,
        };

      const response = await api.post(endpoint, submitData);

      // Validate response
      if (response.status === 200 || response.status === 201) {
        // Refresh user state to update hasCompletedSetup flag
        try {
          const profileResponse = await api.get(endpoints.auth.me);
          if (profileResponse.data) {
            useAuthStore.getState().setUser(profileResponse.data);
          }
        } catch (refreshError) {
          console.error("Failed to refresh user state:", refreshError);
        }

        toast.success("Profile setup complete!", {
          description: "You're all set to start using GigMatch.",
        });
        router.push("/dashboard");
      } else {
        throw new Error("Unexpected response status");
      }
    } catch (error: any) {
      const errorMessage = error?.response?.data?.message ||
        error?.response?.data?.error ||
        error?.message ||
        "Failed to save profile. Please try again.";
      toast.error("Setup failed", {
        description: errorMessage,
      });
    } finally {
      setIsSubmitting(false);
    }
  };

  const toggleGenre = (genre: string) => {
    setData((prev) => ({
      ...prev,
      genres: prev.genres?.includes(genre)
        ? prev.genres.filter((g) => g !== genre)
        : [...(prev.genres || []), genre],
    }));
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-background via-background to-primary/5">
      {/* Progress bar */}
      <div className="fixed top-0 left-0 right-0 z-50">
        <Progress value={progress} className="h-1 rounded-none" />
      </div>

      {/* Background decoration */}
      <div className="absolute inset-0 overflow-hidden pointer-events-none">
        <div className="absolute -top-40 -right-40 w-80 h-80 bg-primary/10 rounded-full blur-3xl" />
        <div className="absolute -bottom-40 -left-40 w-80 h-80 bg-primary/10 rounded-full blur-3xl" />
      </div>

      <div className="container max-w-2xl mx-auto px-4 py-20">
        <AnimatePresence mode="wait">
          <motion.div
            key={currentStepName}
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -20 }}
            transition={{ duration: 0.3 }}
            className="space-y-8"
          >
            {/* Welcome Step */}
            {currentStepName === "welcome" && (
              <WelcomeStep role={role} onNext={nextStep} />
            )}

            {/* Basic Info Step */}
            {currentStepName === "basic" && (
              <BasicInfoStep
                role={role}
                data={data}
                setData={setData}
                onNext={nextStep}
                onPrev={prevStep}
              />
            )}

            {/* Genres Step (Artist) */}
            {currentStepName === "genres" && role === "artist" && (
              <GenresStep
                selectedGenres={data.genres || []}
                onToggle={toggleGenre}
                onNext={nextStep}
                onPrev={prevStep}
              />
            )}

            {/* Type Step (Venue) */}
            {currentStepName === "type" && role === "venue" && (
              <VenueTypeStep
                selectedType={data.venueType}
                onSelect={(type) => setData({ ...data, venueType: type })}
                onNext={nextStep}
                onPrev={prevStep}
              />
            )}

            {/* Bio/Details Step */}
            {(currentStepName === "bio" || currentStepName === "details") && (
              <DetailsStep
                role={role}
                data={data}
                setData={setData}
                onNext={nextStep}
                onPrev={prevStep}
              />
            )}

            {/* Photos Step */}
            {currentStepName === "photos" && (
              <PhotosStep
                onNext={nextStep}
                onPrev={prevStep}
              />
            )}

            {/* Complete Step */}
            {currentStepName === "complete" && (
              <CompleteStep
                role={role}
                isSubmitting={isSubmitting}
                onComplete={handleComplete}
                onPrev={prevStep}
              />
            )}
          </motion.div>
        </AnimatePresence>
      </div>
    </div>
  );
}

// Step Components

interface WelcomeStepProps {
  role: string;
  onNext: () => void;
}

function WelcomeStep({ role, onNext }: WelcomeStepProps) {
  const features = role === "artist"
    ? [
      { icon: Users, text: "Connect with venues looking for talent" },
      { icon: Calendar, text: "Book gigs that match your style" },
      { icon: Star, text: "Build your reputation with reviews" },
    ]
    : [
      { icon: Mic2, text: "Discover talented artists" },
      { icon: Calendar, text: "Manage bookings easily" },
      { icon: Star, text: "Find the perfect fit for your venue" },
    ];

  return (
    <div className="text-center space-y-8">
      <motion.div
        initial={{ scale: 0 }}
        animate={{ scale: 1 }}
        transition={{ type: "spring", delay: 0.2 }}
        className="mx-auto w-24 h-24 bg-primary/10 rounded-3xl flex items-center justify-center"
      >
        <Music2 className="w-12 h-12 text-primary" />
      </motion.div>

      <div className="space-y-2">
        <h1 className="text-3xl font-bold">
          Welcome to GigMatch!
        </h1>
        <p className="text-muted-foreground text-lg">
          Let&apos;s set up your {role === "artist" ? "artist" : "venue"} profile
        </p>
      </div>

      <div className="space-y-4 max-w-sm mx-auto">
        {features.map((feature, index) => (
          <motion.div
            key={index}
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.4 + index * 0.1 }}
            className="flex items-center gap-4 text-left"
          >
            <div className="w-10 h-10 rounded-xl bg-primary/10 flex items-center justify-center flex-shrink-0">
              <feature.icon className="w-5 h-5 text-primary" />
            </div>
            <span className="text-muted-foreground">{feature.text}</span>
          </motion.div>
        ))}
      </div>

      <Button size="lg" className="gap-2" onClick={onNext}>
        Get Started
        <ArrowRight className="w-4 h-4" />
      </Button>
    </div>
  );
}

interface BasicInfoStepProps {
  role: string;
  data: OnboardingData;
  setData: (data: OnboardingData) => void;
  onNext: () => void;
  onPrev: () => void;
}

function BasicInfoStep({ role, data, setData, onNext, onPrev }: BasicInfoStepProps) {
  return (
    <div className="space-y-8">
      <div className="text-center space-y-2">
        <h2 className="text-2xl font-bold">Basic Information</h2>
        <p className="text-muted-foreground">
          Tell us about {role === "artist" ? "yourself" : "your venue"}
        </p>
      </div>

      <div className="space-y-4 max-w-md mx-auto">
        {role === "artist" ? (
          <>
            <div className="space-y-2">
              <Label>Stage Name</Label>
              <Input
                placeholder="Your stage name"
                value={data.stageName || ""}
                onChange={(e) => setData({ ...data, stageName: e.target.value })}
                className="h-12"
              />
            </div>
            <div className="space-y-2">
              <Label>Performer Type</Label>
              <div className="grid grid-cols-2 gap-2">
                {PERFORMANCE_TYPES.map((type) => (
                  <Button
                    key={type}
                    variant={data.performerType === type ? "default" : "outline"}
                    className="h-12"
                    onClick={() => setData({ ...data, performerType: type })}
                  >
                    {type}
                  </Button>
                ))}
              </div>
            </div>
          </>
        ) : (
          <>
            <div className="space-y-2">
              <Label>Location</Label>
              <div className="relative">
                <MapPin className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                <Input
                  placeholder="City, State"
                  value={data.location || ""}
                  onChange={(e) => setData({ ...data, location: e.target.value })}
                  className="h-12 pl-10"
                />
              </div>
            </div>
            <div className="space-y-2">
              <Label>Capacity</Label>
              <Input
                type="number"
                placeholder="Maximum capacity"
                value={data.capacity || ""}
                onChange={(e) => setData({ ...data, capacity: parseInt(e.target.value) })}
                className="h-12"
              />
            </div>
          </>
        )}
      </div>

      <div className="flex justify-center gap-4">
        <Button variant="outline" onClick={onPrev}>
          <ArrowLeft className="w-4 h-4 mr-2" />
          Back
        </Button>
        <Button onClick={onNext}>
          Continue
          <ArrowRight className="w-4 h-4 ml-2" />
        </Button>
      </div>
    </div>
  );
}

interface GenresStepProps {
  selectedGenres: string[];
  onToggle: (genre: string) => void;
  onNext: () => void;
  onPrev: () => void;
}

function GenresStep({ selectedGenres, onToggle, onNext, onPrev }: GenresStepProps) {
  return (
    <div className="space-y-8">
      <div className="text-center space-y-2">
        <div className="mx-auto w-16 h-16 bg-primary/10 rounded-2xl flex items-center justify-center mb-4">
          <Guitar className="w-8 h-8 text-primary" />
        </div>
        <h2 className="text-2xl font-bold">What genres do you play?</h2>
        <p className="text-muted-foreground">Select all that apply</p>
      </div>

      <div className="flex flex-wrap justify-center gap-2 max-w-lg mx-auto">
        {GENRES.map((genre) => (
          <Badge
            key={genre}
            variant={selectedGenres.includes(genre) ? "default" : "outline"}
            className={cn(
              "cursor-pointer text-sm py-2 px-4 transition-all",
              selectedGenres.includes(genre) && "bg-primary"
            )}
            onClick={() => onToggle(genre)}
          >
            {selectedGenres.includes(genre) && <Check className="w-3 h-3 mr-1" />}
            {genre}
          </Badge>
        ))}
      </div>

      <div className="flex justify-center gap-4">
        <Button variant="outline" onClick={onPrev}>
          <ArrowLeft className="w-4 h-4 mr-2" />
          Back
        </Button>
        <Button onClick={onNext} disabled={selectedGenres.length === 0}>
          Continue
          <ArrowRight className="w-4 h-4 ml-2" />
        </Button>
      </div>
    </div>
  );
}

interface VenueTypeStepProps {
  selectedType?: string;
  onSelect: (type: string) => void;
  onNext: () => void;
  onPrev: () => void;
}

function VenueTypeStep({ selectedType, onSelect, onNext, onPrev }: VenueTypeStepProps) {
  return (
    <div className="space-y-8">
      <div className="text-center space-y-2">
        <h2 className="text-2xl font-bold">What type of venue?</h2>
        <p className="text-muted-foreground">Select your venue category</p>
      </div>

      <div className="grid grid-cols-2 md:grid-cols-3 gap-3 max-w-lg mx-auto">
        {VENUE_TYPES.map((type) => (
          <Button
            key={type}
            variant={selectedType === type ? "default" : "outline"}
            className="h-auto py-4 flex-col gap-1"
            onClick={() => onSelect(type)}
          >
            {type}
          </Button>
        ))}
      </div>

      <div className="flex justify-center gap-4">
        <Button variant="outline" onClick={onPrev}>
          <ArrowLeft className="w-4 h-4 mr-2" />
          Back
        </Button>
        <Button onClick={onNext} disabled={!selectedType}>
          Continue
          <ArrowRight className="w-4 h-4 ml-2" />
        </Button>
      </div>
    </div>
  );
}

interface DetailsStepProps {
  role: string;
  data: OnboardingData;
  setData: (data: OnboardingData) => void;
  onNext: () => void;
  onPrev: () => void;
}

function DetailsStep({ role, data, setData, onNext, onPrev }: DetailsStepProps) {
  return (
    <div className="space-y-8">
      <div className="text-center space-y-2">
        <h2 className="text-2xl font-bold">
          {role === "artist" ? "Your Bio" : "Venue Details"}
        </h2>
        <p className="text-muted-foreground">
          {role === "artist"
            ? "Tell venues what makes you unique"
            : "Describe your venue and what you're looking for"}
        </p>
      </div>

      <div className="space-y-4 max-w-md mx-auto">
        <div className="space-y-2">
          <Label>{role === "artist" ? "Bio" : "Description"}</Label>
          <Textarea
            placeholder={
              role === "artist"
                ? "Share your musical journey, style, and what you bring to performances..."
                : "Describe your venue, atmosphere, typical events, and the kind of artists you're looking for..."
            }
            value={role === "artist" ? data.bio : data.description}
            onChange={(e) =>
              setData({
                ...data,
                [role === "artist" ? "bio" : "description"]: e.target.value,
              })
            }
            className="min-h-[150px] resize-none"
          />
          <p className="text-xs text-muted-foreground text-right">
            {(role === "artist" ? data.bio : data.description)?.length || 0}/500
          </p>
        </div>

        {role === "artist" && (
          <div className="space-y-2">
            <Label>Years of Experience</Label>
            <Input
              type="number"
              placeholder="0"
              min="0"
              max="50"
              value={data.yearsExperience || ""}
              onChange={(e) =>
                setData({ ...data, yearsExperience: parseInt(e.target.value) })
              }
              className="h-12"
            />
          </div>
        )}
      </div>

      <div className="flex justify-center gap-4">
        <Button variant="outline" onClick={onPrev}>
          <ArrowLeft className="w-4 h-4 mr-2" />
          Back
        </Button>
        <Button onClick={onNext}>
          Continue
          <ArrowRight className="w-4 h-4 ml-2" />
        </Button>
      </div>
    </div>
  );
}

interface PhotosStepProps {
  onNext: () => void;
  onPrev: () => void;
}

function PhotosStep({ onNext, onPrev }: PhotosStepProps) {
  return (
    <div className="space-y-8">
      <div className="text-center space-y-2">
        <h2 className="text-2xl font-bold">Add Photos (Optional)</h2>
        <p className="text-muted-foreground">
          Photo upload coming soon! You can skip this step for now.
        </p>
        <p className="text-xs text-muted-foreground">
          You can add photos later from your profile page
        </p>
      </div>

      <div className="max-w-md mx-auto">
        <div className="border-2 border-dashed border-border rounded-xl p-12 text-center opacity-50 cursor-not-allowed">
          <Upload className="w-12 h-12 mx-auto text-muted-foreground mb-4" />
          <p className="text-muted-foreground">
            Photo upload will be enabled soon
          </p>
          <p className="text-xs text-muted-foreground mt-2">
            Coming in next update
          </p>
        </div>
      </div>

      <div className="flex justify-center gap-4">
        <Button variant="outline" onClick={onPrev}>
          <ArrowLeft className="w-4 h-4 mr-2" />
          Back
        </Button>
        <Button onClick={onNext}>
          Skip for Now
          <ArrowRight className="w-4 h-4 ml-2" />
        </Button>
      </div>
    </div>
  );
}

interface CompleteStepProps {
  role: string;
  isSubmitting: boolean;
  onComplete: () => void;
  onPrev: () => void;
}

function CompleteStep({ role, isSubmitting, onComplete, onPrev }: CompleteStepProps) {
  return (
    <div className="text-center space-y-8">
      <motion.div
        initial={{ scale: 0 }}
        animate={{ scale: 1 }}
        transition={{ type: "spring" }}
        className="mx-auto w-24 h-24 bg-green-500/10 rounded-3xl flex items-center justify-center"
      >
        <Check className="w-12 h-12 text-green-500" />
      </motion.div>

      <div className="space-y-2">
        <h2 className="text-3xl font-bold">You&apos;re all set!</h2>
        <p className="text-muted-foreground text-lg">
          Your {role === "artist" ? "artist" : "venue"} profile is ready
        </p>
      </div>

      <div className="flex justify-center gap-4">
        <Button variant="outline" onClick={onPrev}>
          <ArrowLeft className="w-4 h-4 mr-2" />
          Back
        </Button>
        <Button size="lg" onClick={onComplete} disabled={isSubmitting}>
          {isSubmitting ? "Saving..." : "Start Discovering"}
          <ArrowRight className="w-4 h-4 ml-2" />
        </Button>
      </div>
    </div>
  );
}
