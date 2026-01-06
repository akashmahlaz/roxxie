"use client";

import { useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { motion } from "framer-motion";
import { Music2, Eye, EyeOff, Loader2, User, Building2, Check } from "lucide-react";
import { toast } from "sonner";

import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from "@/components/ui/card";
import { useAuthStore, RegisterData } from "@/lib/auth-store";
import { cn } from "@/lib/utils";

type Role = "artist" | "venue";

export default function SignupPage() {
  const router = useRouter();
  const { register, isLoading } = useAuthStore();
  const [showPassword, setShowPassword] = useState(false);
  const [step, setStep] = useState<"role" | "details">("role");
  const [formData, setFormData] = useState<RegisterData>({
    email: "",
    password: "",
    fullName: "",
    role: "artist",
    phone: "",
  });

  const passwordRequirements = [
    { label: "At least 8 characters", valid: formData.password.length >= 8 },
    { label: "One uppercase letter", valid: /[A-Z]/.test(formData.password) },
    { label: "One lowercase letter", valid: /[a-z]/.test(formData.password) },
    { label: "One number", valid: /\d/.test(formData.password) },
  ];

  const isPasswordValid = passwordRequirements.every((r) => r.valid);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!isPasswordValid) {
      toast.error("Password requirements not met", {
        description: "Please make sure your password meets all requirements.",
      });
      return;
    }

    try {
      await register(formData);
      toast.success("Account created!", {
        description: "Please check your email to verify your account.",
      });
      router.push("/onboarding");
    } catch {
      toast.error("Registration failed", {
        description: "An account with this email may already exist.",
      });
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-background via-background to-primary/5 p-4">
      {/* Background decoration */}
      <div className="absolute inset-0 overflow-hidden pointer-events-none">
        <div className="absolute -top-40 -right-40 w-80 h-80 bg-primary/10 rounded-full blur-3xl" />
        <div className="absolute -bottom-40 -left-40 w-80 h-80 bg-primary/10 rounded-full blur-3xl" />
      </div>

      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5 }}
        className="w-full max-w-md relative z-10"
      >
        <Card className="border-border/50 shadow-2xl backdrop-blur-sm bg-card/95">
          <CardHeader className="space-y-4 text-center">
            <motion.div
              initial={{ scale: 0 }}
              animate={{ scale: 1 }}
              transition={{ delay: 0.2, type: "spring" }}
              className="mx-auto w-16 h-16 bg-primary/10 rounded-2xl flex items-center justify-center"
            >
              <Music2 className="w-8 h-8 text-primary" />
            </motion.div>
            <div>
              <CardTitle className="text-2xl font-bold">
                {step === "role" ? "Join GigMatch" : "Create your account"}
              </CardTitle>
              <CardDescription className="text-muted-foreground">
                {step === "role"
                  ? "Choose how you want to use GigMatch"
                  : `Sign up as ${formData.role === "artist" ? "an Artist" : "a Venue"}`}
              </CardDescription>
            </div>
          </CardHeader>

          {step === "role" ? (
            <CardContent className="space-y-4">
              <RoleOption
                role="artist"
                selected={formData.role === "artist"}
                onClick={() => setFormData({ ...formData, role: "artist" })}
                icon={<User className="w-6 h-6" />}
                title="I'm an Artist"
                description="Looking for gigs and performance opportunities"
              />
              <RoleOption
                role="venue"
                selected={formData.role === "venue"}
                onClick={() => setFormData({ ...formData, role: "venue" })}
                icon={<Building2 className="w-6 h-6" />}
                title="I'm a Venue"
                description="Looking to book artists for events"
              />
              <Button
                className="w-full h-11 mt-4"
                onClick={() => setStep("details")}
              >
                Continue
              </Button>
            </CardContent>
          ) : (
            <form onSubmit={handleSubmit}>
              <CardContent className="space-y-4">
                <div className="space-y-2">
                  <Label htmlFor="fullName">
                    {formData.role === "artist" ? "Full Name" : "Venue Name"}
                  </Label>
                  <Input
                    id="fullName"
                    type="text"
                    placeholder={formData.role === "artist" ? "John Doe" : "The Blue Note"}
                    value={formData.fullName}
                    onChange={(e) => setFormData({ ...formData, fullName: e.target.value })}
                    required
                    className="h-11"
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="email">Email</Label>
                  <Input
                    id="email"
                    type="email"
                    placeholder="you@example.com"
                    value={formData.email}
                    onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                    required
                    className="h-11"
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="phone">Phone (optional)</Label>
                  <Input
                    id="phone"
                    type="tel"
                    placeholder="+1 (555) 000-0000"
                    value={formData.phone}
                    onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                    className="h-11"
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="password">Password</Label>
                  <div className="relative">
                    <Input
                      id="password"
                      type={showPassword ? "text" : "password"}
                      placeholder="••••••••"
                      value={formData.password}
                      onChange={(e) => setFormData({ ...formData, password: e.target.value })}
                      required
                      className="h-11 pr-10"
                    />
                    <button
                      type="button"
                      onClick={() => setShowPassword(!showPassword)}
                      className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground"
                    >
                      {showPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                    </button>
                  </div>
                  
                  {/* Password requirements */}
                  <div className="grid grid-cols-2 gap-2 mt-2">
                    {passwordRequirements.map((req, i) => (
                      <div
                        key={i}
                        className={cn(
                          "flex items-center gap-1.5 text-xs",
                          req.valid ? "text-green-500" : "text-muted-foreground"
                        )}
                      >
                        <Check className={cn("h-3 w-3", !req.valid && "opacity-30")} />
                        {req.label}
                      </div>
                    ))}
                  </div>
                </div>
              </CardContent>

              <CardFooter className="flex flex-col gap-4">
                <div className="flex gap-2 w-full">
                  <Button
                    type="button"
                    variant="outline"
                    className="flex-1 h-11"
                    onClick={() => setStep("role")}
                  >
                    Back
                  </Button>
                  <Button
                    type="submit"
                    className="flex-1 h-11"
                    disabled={isLoading || !isPasswordValid}
                  >
                    {isLoading ? (
                      <>
                        <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                        Creating...
                      </>
                    ) : (
                      "Create account"
                    )}
                  </Button>
                </div>
              </CardFooter>
            </form>
          )}
        </Card>

        <p className="text-center text-sm text-muted-foreground mt-6">
          Already have an account?{" "}
          <Link href="/login" className="text-primary hover:underline font-medium">
            Sign in
          </Link>
        </p>
      </motion.div>
    </div>
  );
}

interface RoleOptionProps {
  role: Role;
  selected: boolean;
  onClick: () => void;
  icon: React.ReactNode;
  title: string;
  description: string;
}

function RoleOption({ selected, onClick, icon, title, description }: RoleOptionProps) {
  return (
    <motion.button
      type="button"
      whileHover={{ scale: 1.02 }}
      whileTap={{ scale: 0.98 }}
      onClick={onClick}
      className={cn(
        "w-full p-4 rounded-xl border-2 text-left transition-all",
        selected
          ? "border-primary bg-primary/5"
          : "border-border hover:border-primary/50"
      )}
    >
      <div className="flex items-center gap-4">
        <div
          className={cn(
            "w-12 h-12 rounded-xl flex items-center justify-center",
            selected ? "bg-primary text-primary-foreground" : "bg-muted text-muted-foreground"
          )}
        >
          {icon}
        </div>
        <div>
          <h3 className="font-semibold">{title}</h3>
          <p className="text-sm text-muted-foreground">{description}</p>
        </div>
      </div>
    </motion.button>
  );
}
