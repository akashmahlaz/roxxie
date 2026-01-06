"use client";

import { useState, useEffect } from "react";
import { motion, AnimatePresence, PanInfo } from "framer-motion";
import { 
  Heart, X, Star, Music2, MapPin, Calendar, 
  ChevronLeft, ChevronRight, Loader2, RefreshCw
} from "lucide-react";
import { toast } from "sonner";

import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import api, { endpoints } from "@/lib/api";
import { cn } from "@/lib/utils";

interface DiscoveryCard {
  id: string;
  name: string;
  type: "artist" | "venue";
  photo: string;
  genres?: string[];
  venueType?: string;
  location?: string;
  bio?: string;
  rating?: number;
  yearsExperience?: number;
  capacity?: number;
}

export default function DiscoveryPage() {
  const [cards, setCards] = useState<DiscoveryCard[]>([]);
  const [currentIndex, setCurrentIndex] = useState(0);
  const [isLoading, setIsLoading] = useState(true);
  const [isActioning, setIsActioning] = useState(false);
  const [direction, setDirection] = useState<"left" | "right" | null>(null);
  const [currentPhotoIndex, setCurrentPhotoIndex] = useState(0);

  useEffect(() => {
    loadCards();
  }, []);

  const loadCards = async () => {
    setIsLoading(true);
    try {
      const response = await api.get(endpoints.discovery.cards);
      setCards(response.data.cards || []);
      setCurrentIndex(0);
    } catch {
      toast.error("Failed to load cards", {
        description: "Please try refreshing the page.",
      });
    } finally {
      setIsLoading(false);
    }
  };

  const currentCard = cards[currentIndex];

  const handleSwipe = async (liked: boolean) => {
    if (isActioning || !currentCard) return;
    
    setIsActioning(true);
    setDirection(liked ? "right" : "left");
    
    try {
      const endpoint = liked 
        ? endpoints.discovery.like(currentCard.id)
        : endpoints.discovery.pass(currentCard.id);
      
      const response = await api.post(endpoint);
      
      if (response.data.isMatch) {
        toast.success("It's a Match! 🎉", {
          description: `You matched with ${currentCard.name}!`,
        });
      }
      
      // Move to next card
      setTimeout(() => {
        setDirection(null);
        setCurrentIndex((prev) => prev + 1);
        setCurrentPhotoIndex(0);
        setIsActioning(false);
      }, 300);
    } catch {
      toast.error("Action failed", {
        description: "Please try again.",
      });
      setDirection(null);
      setIsActioning(false);
    }
  };

  const handleDragEnd = (_: unknown, info: PanInfo) => {
    const threshold = 100;
    if (info.offset.x > threshold) {
      handleSwipe(true);
    } else if (info.offset.x < -threshold) {
      handleSwipe(false);
    }
  };

  if (isLoading) {
    return (
      <div className="flex items-center justify-center min-h-[60vh]">
        <div className="text-center space-y-4">
          <Loader2 className="w-8 h-8 animate-spin mx-auto text-primary" />
          <p className="text-muted-foreground">Finding matches for you...</p>
        </div>
      </div>
    );
  }

  if (currentIndex >= cards.length) {
    return (
      <div className="flex items-center justify-center min-h-[60vh]">
        <div className="text-center space-y-4 max-w-sm">
          <div className="w-20 h-20 rounded-full bg-primary/10 flex items-center justify-center mx-auto">
            <Music2 className="w-10 h-10 text-primary" />
          </div>
          <h2 className="text-2xl font-bold">No more cards</h2>
          <p className="text-muted-foreground">
            You&apos;ve seen everyone for now. Check back later for new matches!
          </p>
          <Button onClick={loadCards} className="gap-2">
            <RefreshCw className="w-4 h-4" />
            Refresh
          </Button>
        </div>
      </div>
    );
  }

  return (
    <div className="max-w-lg mx-auto">
      {/* Header */}
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold">Discover</h1>
          <p className="text-muted-foreground">
            {cards.length - currentIndex} cards remaining
          </p>
        </div>
        <Button variant="outline" size="icon" onClick={loadCards}>
          <RefreshCw className="w-4 h-4" />
        </Button>
      </div>

      {/* Card Stack */}
      <div className="relative aspect-[3/4] max-h-[600px]">
        <AnimatePresence>
          {cards.slice(currentIndex, currentIndex + 2).map((card, index) => (
            <motion.div
              key={card.id}
              className={cn(
                "absolute inset-0",
                index === 0 ? "z-10" : "z-0"
              )}
              initial={{ scale: index === 0 ? 1 : 0.95, opacity: index === 0 ? 1 : 0.5 }}
              animate={{
                scale: index === 0 ? 1 : 0.95,
                opacity: index === 0 ? 1 : 0.5,
                x: index === 0 && direction ? (direction === "right" ? 300 : -300) : 0,
                rotate: index === 0 && direction ? (direction === "right" ? 15 : -15) : 0,
              }}
              exit={{
                x: direction === "right" ? 300 : -300,
                rotate: direction === "right" ? 15 : -15,
                opacity: 0,
              }}
              transition={{ duration: 0.3 }}
              drag={index === 0 ? "x" : false}
              dragConstraints={{ left: 0, right: 0 }}
              dragElastic={0.7}
              onDragEnd={index === 0 ? handleDragEnd : undefined}
            >
              <DiscoveryCardComponent
                card={card}
                photoIndex={currentPhotoIndex}
                onPhotoChange={setCurrentPhotoIndex}
                direction={index === 0 ? direction : null}
              />
            </motion.div>
          ))}
        </AnimatePresence>
      </div>

      {/* Action Buttons */}
      <div className="flex items-center justify-center gap-4 mt-6">
        <Button
          size="lg"
          variant="outline"
          className="w-16 h-16 rounded-full border-2 border-destructive text-destructive hover:bg-destructive hover:text-destructive-foreground"
          onClick={() => handleSwipe(false)}
          disabled={isActioning}
        >
          <X className="w-8 h-8" />
        </Button>
        
        <Button
          size="lg"
          variant="outline"
          className="w-14 h-14 rounded-full border-2 border-yellow-500 text-yellow-500 hover:bg-yellow-500 hover:text-white"
          disabled={isActioning}
        >
          <Star className="w-6 h-6" />
        </Button>
        
        <Button
          size="lg"
          className="w-16 h-16 rounded-full bg-green-500 hover:bg-green-600"
          onClick={() => handleSwipe(true)}
          disabled={isActioning}
        >
          <Heart className="w-8 h-8" />
        </Button>
      </div>
    </div>
  );
}

interface DiscoveryCardComponentProps {
  card: DiscoveryCard;
  photoIndex: number;
  onPhotoChange: (index: number) => void;
  direction: "left" | "right" | null;
}

function DiscoveryCardComponent({ 
  card, 
  photoIndex, 
  onPhotoChange, 
  direction 
}: DiscoveryCardComponentProps) {
  // Mock multiple photos - in real app this would come from API
  const photos = [card.photo, card.photo, card.photo].filter(Boolean);

  return (
    <Card className="h-full overflow-hidden border-0 shadow-2xl">
      <CardContent className="p-0 h-full relative">
        {/* Photo */}
        <div className="absolute inset-0 bg-gradient-to-b from-transparent via-transparent to-black/80">
          {photos.length > 0 ? (
            <div 
              className="w-full h-full bg-cover bg-center"
              style={{ backgroundImage: `url(${photos[photoIndex]})` }}
            />
          ) : (
            <div className="w-full h-full bg-gradient-to-br from-primary/20 to-primary/5 flex items-center justify-center">
              <Music2 className="w-20 h-20 text-primary/30" />
            </div>
          )}
        </div>

        {/* Photo navigation */}
        {photos.length > 1 && (
          <>
            <div className="absolute top-2 left-0 right-0 flex justify-center gap-1 z-20">
              {photos.map((_, i) => (
                <div
                  key={i}
                  className={cn(
                    "h-1 rounded-full transition-all",
                    i === photoIndex ? "w-8 bg-white" : "w-4 bg-white/50"
                  )}
                />
              ))}
            </div>
            <button
              onClick={() => onPhotoChange(Math.max(0, photoIndex - 1))}
              className="absolute left-0 top-0 bottom-20 w-1/3 z-10"
            />
            <button
              onClick={() => onPhotoChange(Math.min(photos.length - 1, photoIndex + 1))}
              className="absolute right-0 top-0 bottom-20 w-1/3 z-10"
            />
          </>
        )}

        {/* Like/Nope indicators */}
        <AnimatePresence>
          {direction === "right" && (
            <motion.div
              initial={{ opacity: 0, scale: 0.5 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0 }}
              className="absolute top-10 left-10 z-30"
            >
              <div className="border-4 border-green-500 text-green-500 font-bold text-3xl px-4 py-2 rounded-lg rotate-[-20deg]">
                LIKE
              </div>
            </motion.div>
          )}
          {direction === "left" && (
            <motion.div
              initial={{ opacity: 0, scale: 0.5 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0 }}
              className="absolute top-10 right-10 z-30"
            >
              <div className="border-4 border-red-500 text-red-500 font-bold text-3xl px-4 py-2 rounded-lg rotate-[20deg]">
                NOPE
              </div>
            </motion.div>
          )}
        </AnimatePresence>

        {/* Content overlay */}
        <div className="absolute bottom-0 left-0 right-0 p-6 z-20">
          <div className="space-y-3">
            <div className="flex items-end justify-between">
              <div>
                <h2 className="text-3xl font-bold text-white">{card.name}</h2>
                <div className="flex items-center gap-2 text-white/80">
                  {card.location && (
                    <span className="flex items-center gap-1">
                      <MapPin className="w-4 h-4" />
                      {card.location}
                    </span>
                  )}
                  {card.yearsExperience && (
                    <span className="flex items-center gap-1">
                      <Calendar className="w-4 h-4" />
                      {card.yearsExperience} years
                    </span>
                  )}
                </div>
              </div>
              {card.rating && (
                <div className="flex items-center gap-1 text-yellow-400">
                  <Star className="w-5 h-5 fill-current" />
                  <span className="font-semibold">{card.rating}</span>
                </div>
              )}
            </div>

            {/* Genres/Type badges */}
            <div className="flex flex-wrap gap-2">
              {card.type === "artist" && card.genres?.slice(0, 3).map((genre) => (
                <Badge key={genre} variant="secondary" className="bg-white/20 text-white border-0">
                  {genre}
                </Badge>
              ))}
              {card.type === "venue" && card.venueType && (
                <Badge variant="secondary" className="bg-white/20 text-white border-0">
                  {card.venueType}
                </Badge>
              )}
              {card.capacity && (
                <Badge variant="secondary" className="bg-white/20 text-white border-0">
                  Capacity: {card.capacity}
                </Badge>
              )}
            </div>

            {/* Bio */}
            {card.bio && (
              <p className="text-white/80 text-sm line-clamp-2">
                {card.bio}
              </p>
            )}
          </div>
        </div>
      </CardContent>
    </Card>
  );
}
