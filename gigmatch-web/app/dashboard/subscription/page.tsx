"use client";

import { useState, useEffect } from "react";
import { motion } from "framer-motion";
import { 
  Check, Crown, Zap, Star, 
  Loader2, CreditCard, Calendar, AlertCircle
} from "lucide-react";
import { toast } from "sonner";

import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Tabs, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert";
import { Progress } from "@/components/ui/progress";
import { Separator } from "@/components/ui/separator";
import api, { endpoints } from "@/lib/api";
import { cn } from "@/lib/utils";

interface Plan {
  id: string;
  name: string;
  description: string;
  priceMonthly: number;
  priceYearly: number;
  features: string[];
  highlighted?: boolean;
  icon: React.ReactNode;
}

interface Subscription {
  id: string;
  plan: string;
  status: string;
  currentPeriodStart: string;
  currentPeriodEnd: string;
  cancelAtPeriodEnd: boolean;
  swipesUsed: number;
  swipesLimit: number;
  messagesUsed: number;
  messagesLimit: number;
}

const PLANS: Plan[] = [
  {
    id: "free",
    name: "Free",
    description: "Get started with basic features",
    priceMonthly: 0,
    priceYearly: 0,
    features: [
      "10 swipes per day",
      "Basic discovery",
      "5 messages per match",
      "Standard support",
    ],
    icon: <Star className="w-6 h-6" />,
  },
  {
    id: "pro",
    name: "Pro",
    description: "Perfect for serious performers",
    priceMonthly: 9.99,
    priceYearly: 99.99,
    features: [
      "Unlimited swipes",
      "Advanced filters",
      "Unlimited messages",
      "Priority support",
      "See who liked you",
      "Profile boost (1x/month)",
    ],
    highlighted: true,
    icon: <Zap className="w-6 h-6" />,
  },
  {
    id: "premium",
    name: "Premium",
    description: "Maximum visibility and features",
    priceMonthly: 19.99,
    priceYearly: 199.99,
    features: [
      "Everything in Pro",
      "Weekly profile boost",
      "Featured listing",
      "Analytics dashboard",
      "Contract templates",
      "Dedicated support",
      "Early access to features",
    ],
    icon: <Crown className="w-6 h-6" />,
  },
];

export default function SubscriptionPage() {
  const [subscription, setSubscription] = useState<Subscription | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [processingPlan, setProcessingPlan] = useState<string | null>(null);
  const [billingCycle, setBillingCycle] = useState<"monthly" | "yearly">("monthly");

  useEffect(() => {
    loadSubscription();
  }, []);

  const loadSubscription = async () => {
    try {
      const response = await api.get(endpoints.subscriptions.current);
      setSubscription(response.data);
    } catch {
      // User might not have a subscription
    } finally {
      setIsLoading(false);
    }
  };

  const handleSubscribe = async (planId: string) => {
    if (planId === "free") {
      toast.info("You're already on the free plan!");
      return;
    }

    setProcessingPlan(planId);
    try {
      // Create checkout session on the backend
      const response = await api.post(endpoints.subscriptions.checkout, {
        planId,
        billingCycle,
      });

      const { url } = response.data;

      // Redirect to Stripe Checkout
      if (url) {
        window.location.href = url;
      } else {
        toast.error("Failed to get checkout URL");
      }
    } catch {
      toast.error("Failed to start checkout. Please try again.");
    } finally {
      setProcessingPlan(null);
    }
  };

  const handleManageSubscription = async () => {
    try {
      const response = await api.post(endpoints.subscriptions.portal);
      window.location.href = response.data.url;
    } catch {
      toast.error("Failed to open billing portal");
    }
  };

  const handleCancelSubscription = async () => {
    try {
      await api.post(endpoints.subscriptions.cancel);
      toast.success("Subscription will be canceled at period end");
      loadSubscription();
    } catch {
      toast.error("Failed to cancel subscription");
    }
  };

  if (isLoading) {
    return (
      <div className="flex items-center justify-center min-h-[60vh]">
        <Loader2 className="w-8 h-8 animate-spin text-primary" />
      </div>
    );
  }

  const currentPlan = subscription?.plan || "free";
  const swipesPercent = subscription 
    ? (subscription.swipesUsed / subscription.swipesLimit) * 100 
    : 0;
  const messagesPercent = subscription 
    ? (subscription.messagesUsed / subscription.messagesLimit) * 100 
    : 0;

  return (
    <div className="max-w-5xl mx-auto space-y-8">
      {/* Header */}
      <div className="text-center space-y-2">
        <h1 className="text-3xl font-bold">Choose Your Plan</h1>
        <p className="text-muted-foreground">
          Unlock more features to grow your music career
        </p>
      </div>

      {/* Current Subscription Status */}
      {subscription && subscription.plan !== "free" && (
        <Card className="border-primary/50">
          <CardHeader>
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <div className="p-2 bg-primary/10 rounded-lg">
                  {subscription.plan === "pro" ? (
                    <Zap className="w-5 h-5 text-primary" />
                  ) : (
                    <Crown className="w-5 h-5 text-primary" />
                  )}
                </div>
                <div>
                  <CardTitle className="capitalize">
                    {subscription.plan} Plan
                  </CardTitle>
                  <CardDescription>
                    {subscription.status === "active" 
                      ? subscription.cancelAtPeriodEnd
                        ? "Cancels at period end"
                        : "Active subscription"
                      : "Subscription ended"}
                  </CardDescription>
                </div>
              </div>
              <Badge 
                variant={subscription.status === "active" ? "default" : "secondary"}
              >
                {subscription.status}
              </Badge>
            </div>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="grid grid-cols-2 gap-4 text-sm">
              <div className="flex items-center gap-2">
                <Calendar className="w-4 h-4 text-muted-foreground" />
                <span>
                  Renews:{" "}
                  {new Date(subscription.currentPeriodEnd).toLocaleDateString()}
                </span>
              </div>
              <div className="flex items-center gap-2">
                <CreditCard className="w-4 h-4 text-muted-foreground" />
                <span className="capitalize">{billingCycle} billing</span>
              </div>
            </div>

            {/* Usage */}
            <div className="space-y-3">
              <div className="space-y-1">
                <div className="flex justify-between text-sm">
                  <span>Swipes Used</span>
                  <span>
                    {subscription.swipesUsed} / {subscription.swipesLimit === -1 ? "∞" : subscription.swipesLimit}
                  </span>
                </div>
                {subscription.swipesLimit !== -1 && (
                  <Progress value={swipesPercent} />
                )}
              </div>
              <div className="space-y-1">
                <div className="flex justify-between text-sm">
                  <span>Messages Sent</span>
                  <span>
                    {subscription.messagesUsed} / {subscription.messagesLimit === -1 ? "∞" : subscription.messagesLimit}
                  </span>
                </div>
                {subscription.messagesLimit !== -1 && (
                  <Progress value={messagesPercent} />
                )}
              </div>
            </div>

            <Separator />

            <div className="flex gap-2">
              <Button
                variant="outline"
                onClick={handleManageSubscription}
                className="flex-1"
              >
                Manage Billing
              </Button>
              {!subscription.cancelAtPeriodEnd && (
                <Button
                  variant="ghost"
                  onClick={handleCancelSubscription}
                  className="text-destructive hover:text-destructive"
                >
                  Cancel
                </Button>
              )}
            </div>
          </CardContent>
        </Card>
      )}

      {/* Billing Toggle */}
      <div className="flex justify-center">
        <Tabs 
          value={billingCycle} 
          onValueChange={(v) => setBillingCycle(v as "monthly" | "yearly")}
        >
          <TabsList>
            <TabsTrigger value="monthly">Monthly</TabsTrigger>
            <TabsTrigger value="yearly" className="relative">
              Yearly
              <Badge 
                variant="secondary" 
                className="absolute -top-3 -right-3 text-xs bg-green-500 text-white"
              >
                Save 17%
              </Badge>
            </TabsTrigger>
          </TabsList>
        </Tabs>
      </div>

      {/* Plans Grid */}
      <div className="grid md:grid-cols-3 gap-6">
        {PLANS.map((plan, index) => (
          <motion.div
            key={plan.id}
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: index * 0.1 }}
          >
            <Card 
              className={cn(
                "relative h-full flex flex-col",
                plan.highlighted && "border-primary shadow-lg"
              )}
            >
              {plan.highlighted && (
                <div className="absolute -top-3 left-1/2 -translate-x-1/2">
                  <Badge className="bg-primary">Most Popular</Badge>
                </div>
              )}

              <CardHeader>
                <div className="flex items-center gap-3 mb-2">
                  <div 
                    className={cn(
                      "p-2 rounded-lg",
                      plan.highlighted 
                        ? "bg-primary text-primary-foreground" 
                        : "bg-muted"
                    )}
                  >
                    {plan.icon}
                  </div>
                  <div>
                    <CardTitle>{plan.name}</CardTitle>
                    <CardDescription>{plan.description}</CardDescription>
                  </div>
                </div>
                <div className="flex items-baseline gap-1">
                  <span className="text-4xl font-bold">
                    ${billingCycle === "monthly" ? plan.priceMonthly : plan.priceYearly}
                  </span>
                  <span className="text-muted-foreground">
                    /{billingCycle === "monthly" ? "mo" : "yr"}
                  </span>
                </div>
              </CardHeader>

              <CardContent className="flex-1">
                <ul className="space-y-3">
                  {plan.features.map((feature, i) => (
                    <li key={i} className="flex items-center gap-2">
                      <Check className="w-4 h-4 text-green-500 flex-shrink-0" />
                      <span className="text-sm">{feature}</span>
                    </li>
                  ))}
                </ul>
              </CardContent>

              <CardFooter>
                <Button
                  className="w-full"
                  variant={plan.highlighted ? "default" : "outline"}
                  disabled={
                    currentPlan === plan.id || processingPlan === plan.id
                  }
                  onClick={() => handleSubscribe(plan.id)}
                >
                  {processingPlan === plan.id ? (
                    <>
                      <Loader2 className="w-4 h-4 animate-spin mr-2" />
                      Processing...
                    </>
                  ) : currentPlan === plan.id ? (
                    "Current Plan"
                  ) : plan.priceMonthly === 0 ? (
                    "Get Started"
                  ) : (
                    "Subscribe"
                  )}
                </Button>
              </CardFooter>
            </Card>
          </motion.div>
        ))}
      </div>

      {/* Features Comparison */}
      <Card>
        <CardHeader>
          <CardTitle>Feature Comparison</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b">
                  <th className="text-left py-3 font-medium">Feature</th>
                  <th className="text-center py-3 font-medium">Free</th>
                  <th className="text-center py-3 font-medium text-primary">Pro</th>
                  <th className="text-center py-3 font-medium">Premium</th>
                </tr>
              </thead>
              <tbody className="divide-y">
                <tr>
                  <td className="py-3">Daily Swipes</td>
                  <td className="text-center">10</td>
                  <td className="text-center text-primary">Unlimited</td>
                  <td className="text-center">Unlimited</td>
                </tr>
                <tr>
                  <td className="py-3">Messages per Match</td>
                  <td className="text-center">5</td>
                  <td className="text-center text-primary">Unlimited</td>
                  <td className="text-center">Unlimited</td>
                </tr>
                <tr>
                  <td className="py-3">See Who Liked You</td>
                  <td className="text-center">-</td>
                  <td className="text-center text-primary">✓</td>
                  <td className="text-center">✓</td>
                </tr>
                <tr>
                  <td className="py-3">Profile Boost</td>
                  <td className="text-center">-</td>
                  <td className="text-center text-primary">1x/month</td>
                  <td className="text-center">Weekly</td>
                </tr>
                <tr>
                  <td className="py-3">Analytics</td>
                  <td className="text-center">-</td>
                  <td className="text-center text-primary">Basic</td>
                  <td className="text-center">Advanced</td>
                </tr>
                <tr>
                  <td className="py-3">Contract Templates</td>
                  <td className="text-center">-</td>
                  <td className="text-center">-</td>
                  <td className="text-center">✓</td>
                </tr>
                <tr>
                  <td className="py-3">Dedicated Support</td>
                  <td className="text-center">-</td>
                  <td className="text-center">-</td>
                  <td className="text-center">✓</td>
                </tr>
              </tbody>
            </table>
          </div>
        </CardContent>
      </Card>

      {/* FAQ or Help */}
      <Alert>
        <AlertCircle className="h-4 w-4" />
        <AlertTitle>Need help choosing?</AlertTitle>
        <AlertDescription>
          Contact our support team and we&apos;ll help you find the perfect plan for your needs.
          All plans come with a 7-day money-back guarantee.
        </AlertDescription>
      </Alert>
    </div>
  );
}
