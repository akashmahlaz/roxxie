"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { motion } from "framer-motion";
import { 
  Music, MapPin, Heart, ArrowRight, Star, 
  Sparkles, Users, Calendar, CheckCircle 
} from "lucide-react";

import { Button } from "@/components/ui/button";
import { useAuthStore } from "@/lib/auth-store";
import { ThemeToggle } from "@/components/theme-toggle";
import { OnboardingFlow } from "@/components/onboarding-flow";

export default function HomePage() {
  const router = useRouter();
  const { user, accessToken } = useAuthStore();

  useEffect(() => {
    if (user && accessToken) {
      router.push("/dashboard");
    }
  }, [user, accessToken, router]);

  return (
    <div className="min-h-screen bg-background">
      {/* Onboarding for first-time visitors */}
      <OnboardingFlow />
      
      {/* Navigation */}
      <nav className="fixed top-0 left-0 right-0 z-50 bg-background/80 backdrop-blur-lg border-b border-border">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center justify-between h-16">
            <div className="flex items-center gap-2">
              <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-red-600 to-rose-600 flex items-center justify-center">
                <Music className="w-6 h-6 text-white" />
              </div>
              <span className="text-xl font-bold text-foreground">Roxxie</span>
            </div>
            <div className="flex items-center gap-2">
              <ThemeToggle />
              <Link href="/login">
                <Button variant="ghost">Log In</Button>
              </Link>
              <Link href="/signup">
                <Button className="bg-gradient-to-r from-red-600 to-rose-600 hover:from-red-700 hover:to-rose-700">
                  Get Started
                  <ArrowRight className="w-4 h-4 ml-2" />
                </Button>
              </Link>
            </div>
          </div>
        </div>
      </nav>

      {/* Hero Section */}
      <section className="pt-32 pb-20 px-4 sm:px-6 lg:px-8">
        <div className="max-w-7xl mx-auto">
          <div className="text-center">
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.5 }}
            >
              <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-red-500/10 text-red-500 mb-6">
                <Sparkles className="w-4 h-4" />
                <span className="text-sm font-medium">The #1 Platform for Live Music</span>
              </div>
            </motion.div>

            <motion.h1
              className="text-5xl sm:text-6xl lg:text-7xl font-bold tracking-tight mb-6"
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.5, delay: 0.1 }}
            >
              Where Artists Meet
              <br />
              <span className="text-transparent bg-clip-text bg-gradient-to-r from-red-600 via-rose-500 to-pink-500">
                Amazing Venues
              </span>
            </motion.h1>

            <motion.p
              className="text-xl text-muted-foreground max-w-2xl mx-auto mb-10"
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.5, delay: 0.2 }}
            >
              Roxxie connects talented musicians with the perfect venues. 
              Swipe, match, and book your next unforgettable performance.
            </motion.p>

            <motion.div
              className="flex flex-col sm:flex-row items-center justify-center gap-4"
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.5, delay: 0.3 }}
            >
              <Link href="/signup">
                <Button size="lg" className="text-lg px-8 h-14 bg-gradient-to-r from-red-600 to-rose-600 hover:from-red-700 hover:to-rose-700">
                  <Music className="w-5 h-5 mr-2" />
                  I&apos;m an Artist
                </Button>
              </Link>
              <Link href="/signup">
                <Button size="lg" variant="outline" className="text-lg px-8 h-14 border-cyan-500 text-cyan-500 hover:bg-cyan-500/10">
                  <MapPin className="w-5 h-5 mr-2" />
                  I&apos;m a Venue
                </Button>
              </Link>
            </motion.div>

            {/* Stats */}
            <motion.div
              className="flex items-center justify-center gap-8 sm:gap-16 mt-16"
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.5, delay: 0.4 }}
            >
              <div className="text-center">
                <div className="text-3xl sm:text-4xl font-bold text-red-500">10K+</div>
                <div className="text-sm text-muted-foreground">Artists</div>
              </div>
              <div className="text-center">
                <div className="text-3xl sm:text-4xl font-bold text-cyan-500">5K+</div>
                <div className="text-sm text-muted-foreground">Venues</div>
              </div>
              <div className="text-center">
                <div className="text-3xl sm:text-4xl font-bold text-rose-500">50K+</div>
                <div className="text-sm text-muted-foreground">Gigs Booked</div>
              </div>
            </motion.div>
          </div>
        </div>
      </section>

      {/* Features Section */}
      <section className="py-20 px-4 sm:px-6 lg:px-8 bg-card/50">
        <div className="max-w-7xl mx-auto">
          <div className="text-center mb-16">
            <h2 className="text-3xl sm:text-4xl font-bold mb-4">How It Works</h2>
            <p className="text-muted-foreground text-lg max-w-2xl mx-auto">
              Finding your perfect match has never been easier
            </p>
          </div>

          <div className="grid md:grid-cols-3 gap-8">
            {[
              {
                icon: Users,
                title: "Create Your Profile",
                description: "Showcase your talent or venue with photos, videos, and details about what makes you unique.",
                color: "text-red-500",
                bgColor: "bg-red-500/10",
              },
              {
                icon: Heart,
                title: "Swipe & Match",
                description: "Browse through profiles and swipe right on those you like. When both swipe right, it&apos;s a match!",
                color: "text-rose-500",
                bgColor: "bg-rose-500/10",
              },
              {
                icon: Calendar,
                title: "Book Your Gig",
                description: "Chat with your matches, negotiate terms, and book performances directly through the app.",
                color: "text-cyan-500",
                bgColor: "bg-cyan-500/10",
              },
            ].map((feature, index) => (
              <motion.div
                key={feature.title}
                className="bg-card rounded-2xl p-8 shadow-lg border border-border"
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.5, delay: index * 0.1 }}
                viewport={{ once: true }}
              >
                <div className={`w-14 h-14 rounded-xl ${feature.bgColor} flex items-center justify-center mb-6`}>
                  <feature.icon className={`w-7 h-7 ${feature.color}`} />
                </div>
                <h3 className="text-xl font-semibold mb-3">{feature.title}</h3>
                <p className="text-muted-foreground">{feature.description}</p>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* For Artists Section */}
      <section className="py-20 px-4 sm:px-6 lg:px-8">
        <div className="max-w-7xl mx-auto">
          <div className="grid lg:grid-cols-2 gap-12 items-center">
            <div>
              <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-red-500/10 text-red-500 mb-6">
                <Music className="w-4 h-4" />
                <span className="text-sm font-medium">For Artists</span>
              </div>
              <h2 className="text-3xl sm:text-4xl font-bold mb-6">
                Find Your Stage, Share Your Sound
              </h2>
              <p className="text-lg text-muted-foreground mb-8">
                Whether you&apos;re a solo act, band, or DJ, Roxxie helps you discover 
                venues that match your style and grow your music career.
              </p>
              <ul className="space-y-4">
                {[
                  "Browse thousands of venues in your area",
                  "Showcase your music with audio & video samples",
                  "Get discovered by venue owners looking for talent",
                  "Manage bookings and grow your fanbase",
                ].map((item) => (
                  <li key={item} className="flex items-start gap-3">
                    <CheckCircle className="w-5 h-5 text-red-500 shrink-0 mt-0.5" />
                    <span>{item}</span>
                  </li>
                ))}
              </ul>
              <Link href="/signup" className="inline-block mt-8">
                <Button size="lg" className="bg-gradient-to-r from-red-600 to-rose-600 hover:from-red-700 hover:to-rose-700">
                  Join as Artist
                  <ArrowRight className="w-4 h-4 ml-2" />
                </Button>
              </Link>
            </div>
            <div className="relative">
              <div className="aspect-square rounded-3xl bg-gradient-to-br from-red-500/20 to-rose-500/20 p-8">
                <div className="w-full h-full rounded-2xl bg-gradient-to-br from-red-600 to-rose-600 flex items-center justify-center">
                  <Music className="w-32 h-32 text-white/80" />
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* For Venues Section */}
      <section className="py-20 px-4 sm:px-6 lg:px-8 bg-card/50">
        <div className="max-w-7xl mx-auto">
          <div className="grid lg:grid-cols-2 gap-12 items-center">
            <div className="order-2 lg:order-1 relative">
              <div className="aspect-square rounded-3xl bg-gradient-to-br from-cyan-500/20 to-blue-500/20 p-8">
                <div className="w-full h-full rounded-2xl bg-gradient-to-br from-cyan-500 to-blue-500 flex items-center justify-center">
                  <MapPin className="w-32 h-32 text-white/80" />
                </div>
              </div>
            </div>
            <div className="order-1 lg:order-2">
              <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-cyan-500/10 text-cyan-500 mb-6">
                <MapPin className="w-4 h-4" />
                <span className="text-sm font-medium">For Venues</span>
              </div>
              <h2 className="text-3xl sm:text-4xl font-bold mb-6">
                Discover Amazing Talent for Your Venue
              </h2>
              <p className="text-lg text-muted-foreground mb-8">
                From intimate jazz clubs to large concert halls, find the perfect 
                performers to create unforgettable experiences for your audience.
              </p>
              <ul className="space-y-4">
                {[
                  "Access a diverse pool of talented artists",
                  "Filter by genre, availability, and experience",
                  "Read reviews from other venue owners",
                  "Streamline your booking process",
                ].map((item) => (
                  <li key={item} className="flex items-start gap-3">
                    <CheckCircle className="w-5 h-5 text-cyan-500 shrink-0 mt-0.5" />
                    <span>{item}</span>
                  </li>
                ))}
              </ul>
              <Link href="/signup" className="inline-block mt-8">
                <Button size="lg" className="bg-gradient-to-r from-cyan-500 to-blue-500 hover:from-cyan-600 hover:to-blue-600">
                  Join as Venue
                  <ArrowRight className="w-4 h-4 ml-2" />
                </Button>
              </Link>
            </div>
          </div>
        </div>
      </section>

      {/* Testimonials */}
      <section className="py-20 px-4 sm:px-6 lg:px-8">
        <div className="max-w-7xl mx-auto">
          <div className="text-center mb-16">
            <h2 className="text-3xl sm:text-4xl font-bold mb-4">Loved by Artists & Venues</h2>
            <p className="text-muted-foreground text-lg">See what our community has to say</p>
          </div>

          <div className="grid md:grid-cols-3 gap-8">
            {[
              {
                quote: "Roxxie helped me book 20+ gigs in my first month. The matching system really understands what venues are looking for.",
                author: "Sarah M.",
                role: "Jazz Vocalist",
                rating: 5,
              },
              {
                quote: "We&apos;ve found some incredible local talent through Roxxie. Our customers love the variety of performers we now feature.",
                author: "The Blue Note",
                role: "Jazz Club, NYC",
                rating: 5,
              },
              {
                quote: "As an indie band, getting discovered was always tough. Roxxie changed everything for us. Highly recommend!",
                author: "The Midnight Echo",
                role: "Indie Rock Band",
                rating: 5,
              },
            ].map((testimonial, index) => (
              <motion.div
                key={testimonial.author}
                className="bg-card rounded-2xl p-8 shadow-lg border border-border"
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.5, delay: index * 0.1 }}
                viewport={{ once: true }}
              >
                <div className="flex gap-1 mb-4">
                  {Array.from({ length: testimonial.rating }).map((_, i) => (
                    <Star key={i} className="w-5 h-5 fill-amber-400 text-amber-400" />
                  ))}
                </div>
                <p className="text-muted-foreground mb-6">&quot;{testimonial.quote}&quot;</p>
                <div>
                  <p className="font-semibold">{testimonial.author}</p>
                  <p className="text-sm text-muted-foreground">{testimonial.role}</p>
                </div>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* CTA Section */}
      <section className="py-20 px-4 sm:px-6 lg:px-8">
        <div className="max-w-4xl mx-auto">
          <div className="bg-gradient-to-br from-red-600 to-rose-600 rounded-3xl p-12 text-center text-white">
            <h2 className="text-3xl sm:text-4xl font-bold mb-4">
              Ready to Find Your Perfect Match?
            </h2>
            <p className="text-lg opacity-90 mb-8 max-w-2xl mx-auto">
              Join thousands of artists and venues already making meaningful 
              connections on Roxxie.
            </p>
            <Link href="/signup">
              <Button size="lg" variant="secondary" className="text-lg px-8 h-14 bg-white text-red-600 hover:bg-white/90">
                Get Started for Free
                <ArrowRight className="w-5 h-5 ml-2" />
              </Button>
            </Link>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="py-12 px-4 sm:px-6 lg:px-8 border-t border-border">
        <div className="max-w-7xl mx-auto">
          <div className="flex flex-col md:flex-row items-center justify-between gap-4">
            <div className="flex items-center gap-2">
              <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-red-600 to-rose-600 flex items-center justify-center">
                <Music className="w-4 h-4 text-white" />
              </div>
              <span className="font-semibold">Roxxie</span>
            </div>
            <div className="flex items-center gap-6 text-sm text-muted-foreground">
              <Link href="/about" className="hover:text-foreground transition-colors">About</Link>
              <Link href="/privacy" className="hover:text-foreground transition-colors">Privacy</Link>
              <Link href="/terms" className="hover:text-foreground transition-colors">Terms</Link>
              <Link href="/contact" className="hover:text-foreground transition-colors">Contact</Link>
            </div>
            <p className="text-sm text-muted-foreground">
              © {new Date().getFullYear()} Roxxie. All rights reserved.
            </p>
          </div>
        </div>
      </footer>
    </div>
  );
}
