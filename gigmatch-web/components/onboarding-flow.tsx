"use client";

import { useState, useEffect } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { 
  Search, Heart, Calendar, ChevronRight, ChevronLeft, 
  X, Music, MapPin, Sparkles 
} from "lucide-react";
import { Button } from "@/components/ui/button";

interface OnboardingSlide {
  icon: React.ReactNode;
  title: string;
  description: string;
  linear: string;
}

const slides: OnboardingSlide[] = [
  {
    icon: <Search className="w-16 h-16" />,
    title: "Discover Local Gigs",
    description: "Find the perfect venues and events that match your style. Swipe through opportunities near you.",
    linear: "from-red-600/30 to-rose-600/10",
  },
  {
    icon: <Heart className="w-16 h-16" />,
    title: "Match with Venues",
    description: "Connect with venues that love your music. When it's mutual, the conversation begins.",
    linear: "from-rose-600/30 to-pink-600/10",
  },
  {
    icon: <Calendar className="w-16 h-16" />,
    title: "Book & Perform",
    description: "Manage your gigs seamlessly. Accept bookings, track payments, and build your reputation.",
    linear: "from-pink-600/30 to-cyan-600/10",
  },
];

const ONBOARDING_KEY = "roxxie_onboarding_completed";

export function OnboardingFlow() {
  const [isOpen, setIsOpen] = useState(false);
  const [currentSlide, setCurrentSlide] = useState(0);
  const [direction, setDirection] = useState(0);

  useEffect(() => {
    // Check if user has seen onboarding
    const hasSeenOnboarding = localStorage.getItem(ONBOARDING_KEY);
    if (!hasSeenOnboarding) {
      // Small delay for better UX
      const timer = setTimeout(() => setIsOpen(true), 500);
      return () => clearTimeout(timer);
    }
  }, []);

  const handleComplete = () => {
    localStorage.setItem(ONBOARDING_KEY, "true");
    setIsOpen(false);
  };

  const handleSkip = () => {
    handleComplete();
  };

  const nextSlide = () => {
    if (currentSlide < slides.length - 1) {
      setDirection(1);
      setCurrentSlide((prev) => prev + 1);
    } else {
      handleComplete();
    }
  };

  const prevSlide = () => {
    if (currentSlide > 0) {
      setDirection(-1);
      setCurrentSlide((prev) => prev - 1);
    }
  };

  const variants = {
    enter: (direction: number) => ({
      x: direction > 0 ? 300 : -300,
      opacity: 0,
    }),
    center: {
      x: 0,
      opacity: 1,
    },
    exit: (direction: number) => ({
      x: direction < 0 ? 300 : -300,
      opacity: 0,
    }),
  };

  if (!isOpen) return null;

  const slide = slides[currentSlide];

  return (
    <AnimatePresence>
      {isOpen && (
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          className="fixed inset-0 z-[100] flex items-center justify-center bg-black/80 backdrop-blur-sm p-4"
        >
          <motion.div
            initial={{ scale: 0.95, opacity: 0 }}
            animate={{ scale: 1, opacity: 1 }}
            exit={{ scale: 0.95, opacity: 0 }}
            className="relative w-full max-w-md bg-card rounded-3xl overflow-hidden border border-border shadow-2xl"
          >
            {/* Skip button */}
            <button
              onClick={handleSkip}
              className="absolute top-4 right-4 z-10 p-2 rounded-full hover:bg-muted transition-colors text-muted-foreground hover:text-foreground"
            >
              <X className="w-5 h-5" />
            </button>

            {/* Content */}
            <div className="relative overflow-hidden">
              <AnimatePresence initial={false} custom={direction} mode="wait">
                <motion.div
                  key={currentSlide}
                  custom={direction}
                  variants={variants}
                  initial="enter"
                  animate="center"
                  exit="exit"
                  transition={{ duration: 0.3, ease: "easeInOut" }}
                  className="p-8 pt-12"
                >
                  {/* Icon */}
                  <div className="flex justify-center mb-8">
                    <div
                      className={`w-32 h-32 rounded-full bg-linear-to-br ${slide.linear} flex items-center justify-center shadow-lg`}
                    >
                      <div className="text-foreground">
                        {slide.icon}
                      </div>
                    </div>
                  </div>

                  {/* Title */}
                  <h2 className="text-2xl font-bold text-center mb-4">
                    {slide.title}
                  </h2>

                  {/* Description */}
                  <p className="text-muted-foreground text-center text-lg leading-relaxed">
                    {slide.description}
                  </p>
                </motion.div>
              </AnimatePresence>
            </div>

            {/* Bottom section */}
            <div className="p-8 pt-4">
              {/* Dots indicator */}
              <div className="flex justify-center gap-2 mb-6">
                {slides.map((_, index) => (
                  <button
                    key={index}
                    onClick={() => {
                      setDirection(index > currentSlide ? 1 : -1);
                      setCurrentSlide(index);
                    }}
                    className={`h-2 rounded-full transition-all duration-300 ${
                      index === currentSlide
                        ? "w-8 bg-red-500 shadow-[0_0_8px_rgba(220,38,38,0.5)]"
                        : "w-2 bg-muted hover:bg-muted-foreground/50"
                    }`}
                  />
                ))}
              </div>

              {/* Navigation buttons */}
              <div className="flex gap-3">
                {currentSlide > 0 && (
                  <Button
                    variant="outline"
                    onClick={prevSlide}
                    className="flex-1"
                  >
                    <ChevronLeft className="w-4 h-4 mr-2" />
                    Back
                  </Button>
                )}
                <Button
                  onClick={nextSlide}
                  className={`flex-1 bg-linear-to-r from-red-600 to-rose-600 hover:from-red-700 hover:to-rose-700 ${
                    currentSlide === 0 ? "w-full" : ""
                  }`}
                >
                  {currentSlide === slides.length - 1 ? (
                    <>
                      Get Started
                      <Sparkles className="w-4 h-4 ml-2" />
                    </>
                  ) : (
                    <>
                      Next
                      <ChevronRight className="w-4 h-4 ml-2" />
                    </>
                  )}
                </Button>
              </div>
            </div>

            {/* Decorative elements */}
            <div className="absolute -top-20 -right-20 w-40 h-40 bg-linear-to-br from-red-500/20 to-transparent rounded-full blur-3xl" />
            <div className="absolute -bottom-20 -left-20 w-40 h-40 bg-linear-to-br from-rose-500/20 to-transparent rounded-full blur-3xl" />
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>
  );
}

// Hook to manually trigger onboarding
export function useOnboarding() {
  const resetOnboarding = () => {
    localStorage.removeItem(ONBOARDING_KEY);
    window.location.reload();
  };

  const markComplete = () => {
    localStorage.setItem(ONBOARDING_KEY, "true");
  };

  return { resetOnboarding, markComplete };
}
