"use client";

import { useState, useEffect, useCallback } from "react";
import { 
  Search, MoreHorizontal, Trash2, Eye, CreditCard, 
  Loader2, Download, RefreshCw, XCircle, CheckCircle,
  Calendar, TrendingUp, DollarSign, Users
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

interface Subscription {
  id: string;
  userId: string;
  plan: "free" | "pro" | "premium";
  status: "active" | "canceled" | "expired" | "past_due";
  amount: number;
  interval: "monthly" | "yearly";
  currentPeriodStart: string;
  currentPeriodEnd: string;
  cancelAtPeriodEnd: boolean;
  stripeSubscriptionId?: string;
  createdAt: string;
  user: {
    id: string;
    displayName: string;
    email: string;
    photo?: string;
    role: string;
  };
}

export default function SubscriptionsPage() {
  const [subscriptions, setSubscriptions] = useState<Subscription[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState("");
  const [planFilter, setPlanFilter] = useState<string>("all");
  const [statusFilter, setStatusFilter] = useState<string>("all");
  const [selectedSubscriptions, setSelectedSubscriptions] = useState<string[]>([]);
  
  const [showCancelDialog, setShowCancelDialog] = useState(false);
  const [showViewDialog, setShowViewDialog] = useState(false);
  const [currentSubscription, setCurrentSubscription] = useState<Subscription | null>(null);

  const loadSubscriptions = useCallback(async () => {
    try {
      const response = await api.get(endpoints.admin.subscriptions);
      setSubscriptions(response.data.subscriptions || response.data);
    } catch {
      // Mock data
      setSubscriptions([
        { id: "1", userId: "u1", plan: "premium", status: "active", amount: 29.99, interval: "monthly", currentPeriodStart: "2024-01-01", currentPeriodEnd: "2024-02-01", cancelAtPeriodEnd: false, stripeSubscriptionId: "sub_abc123", createdAt: "2023-12-15", user: { id: "u1", displayName: "John Doe", email: "john@example.com", role: "artist" } },
        { id: "2", userId: "u2", plan: "pro", status: "active", amount: 14.99, interval: "monthly", currentPeriodStart: "2024-01-05", currentPeriodEnd: "2024-02-05", cancelAtPeriodEnd: false, stripeSubscriptionId: "sub_def456", createdAt: "2024-01-05", user: { id: "u2", displayName: "Sarah Smith", email: "sarah@example.com", role: "venue" } },
        { id: "3", userId: "u3", plan: "premium", status: "canceled", amount: 299.99, interval: "yearly", currentPeriodStart: "2023-06-01", currentPeriodEnd: "2024-06-01", cancelAtPeriodEnd: true, stripeSubscriptionId: "sub_ghi789", createdAt: "2023-06-01", user: { id: "u3", displayName: "Mike Wilson", email: "mike@example.com", role: "artist" } },
        { id: "4", userId: "u4", plan: "pro", status: "past_due", amount: 14.99, interval: "monthly", currentPeriodStart: "2024-01-10", currentPeriodEnd: "2024-02-10", cancelAtPeriodEnd: false, stripeSubscriptionId: "sub_jkl012", createdAt: "2024-01-10", user: { id: "u4", displayName: "Emily Chen", email: "emily@example.com", role: "artist" } },
        { id: "5", userId: "u5", plan: "free", status: "active", amount: 0, interval: "monthly", currentPeriodStart: "2024-01-12", currentPeriodEnd: "2024-02-12", cancelAtPeriodEnd: false, createdAt: "2024-01-12", user: { id: "u5", displayName: "Rock Venue LA", email: "la@example.com", role: "venue" } },
        { id: "6", userId: "u6", plan: "premium", status: "expired", amount: 29.99, interval: "monthly", currentPeriodStart: "2023-11-01", currentPeriodEnd: "2023-12-01", cancelAtPeriodEnd: false, stripeSubscriptionId: "sub_mno345", createdAt: "2023-11-01", user: { id: "u6", displayName: "Jazz Master", email: "jazz@example.com", role: "artist" } },
      ]);
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    loadSubscriptions();
  }, [loadSubscriptions]);

  const filteredSubscriptions = subscriptions.filter((sub) => {
    const matchesSearch = 
      sub.user.displayName.toLowerCase().includes(searchQuery.toLowerCase()) ||
      sub.user.email.toLowerCase().includes(searchQuery.toLowerCase());
    const matchesPlan = planFilter === "all" || sub.plan === planFilter;
    const matchesStatus = statusFilter === "all" || sub.status === statusFilter;
    return matchesSearch && matchesPlan && matchesStatus;
  });

  const handleCancel = async () => {
    if (!currentSubscription) return;
    try {
      await api.post(`${endpoints.admin.subscriptions}/${currentSubscription.id}/cancel`);
      toast.success("Subscription canceled");
      setShowCancelDialog(false);
      setCurrentSubscription(null);
      loadSubscriptions();
    } catch {
      toast.error("Failed to cancel subscription");
    }
  };

  const handleRefund = async (subscriptionId: string) => {
    try {
      await api.post(`${endpoints.admin.subscriptions}/${subscriptionId}/refund`);
      toast.success("Refund initiated");
      loadSubscriptions();
    } catch {
      toast.error("Failed to process refund");
    }
  };

  const handleReactivate = async (subscriptionId: string) => {
    try {
      await api.post(`${endpoints.admin.subscriptions}/${subscriptionId}/reactivate`);
      toast.success("Subscription reactivated");
      loadSubscriptions();
    } catch {
      toast.error("Failed to reactivate subscription");
    }
  };

  const getStatusBadge = (status: string) => {
    switch (status) {
      case "active":
        return <Badge className="bg-green-500">Active</Badge>;
      case "canceled":
        return <Badge variant="secondary">Canceled</Badge>;
      case "expired":
        return <Badge variant="outline">Expired</Badge>;
      case "past_due":
        return <Badge variant="destructive">Past Due</Badge>;
      default:
        return <Badge variant="outline">{status}</Badge>;
    }
  };

  const getPlanBadge = (plan: string) => {
    switch (plan) {
      case "premium":
        return <Badge className="bg-gradient-to-r from-amber-500 to-orange-500">Premium</Badge>;
      case "pro":
        return <Badge className="bg-gradient-to-r from-purple-500 to-indigo-500">Pro</Badge>;
      default:
        return <Badge variant="outline">Free</Badge>;
    }
  };

  const totalMRR = subscriptions
    .filter((s) => s.status === "active" && s.plan !== "free")
    .reduce((acc, s) => acc + (s.interval === "yearly" ? s.amount / 12 : s.amount), 0);

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
          <h1 className="text-3xl font-bold">Subscriptions</h1>
          <p className="text-muted-foreground">
            Manage user subscriptions and billing
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
            <div className="flex items-center gap-2">
              <DollarSign className="w-5 h-5 text-green-500" />
              <div className="text-2xl font-bold">${totalMRR.toFixed(2)}</div>
            </div>
            <p className="text-xs text-muted-foreground">Monthly Recurring Revenue</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center gap-2">
              <Users className="w-5 h-5 text-blue-500" />
              <div className="text-2xl font-bold">
                {subscriptions.filter((s) => s.status === "active").length}
              </div>
            </div>
            <p className="text-xs text-muted-foreground">Active Subscriptions</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center gap-2">
              <TrendingUp className="w-5 h-5 text-purple-500" />
              <div className="text-2xl font-bold">
                {subscriptions.filter((s) => s.plan === "premium").length}
              </div>
            </div>
            <p className="text-xs text-muted-foreground">Premium Users</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center gap-2">
              <XCircle className="w-5 h-5 text-red-500" />
              <div className="text-2xl font-bold">
                {subscriptions.filter((s) => s.status === "past_due").length}
              </div>
            </div>
            <p className="text-xs text-muted-foreground">Past Due</p>
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
                placeholder="Search by name or email..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="pl-8"
              />
            </div>
            <Select value={planFilter} onValueChange={setPlanFilter}>
              <SelectTrigger className="w-[150px]">
                <SelectValue placeholder="Plan" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All Plans</SelectItem>
                <SelectItem value="free">Free</SelectItem>
                <SelectItem value="pro">Pro</SelectItem>
                <SelectItem value="premium">Premium</SelectItem>
              </SelectContent>
            </Select>
            <Select value={statusFilter} onValueChange={setStatusFilter}>
              <SelectTrigger className="w-[150px]">
                <SelectValue placeholder="Status" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All Status</SelectItem>
                <SelectItem value="active">Active</SelectItem>
                <SelectItem value="canceled">Canceled</SelectItem>
                <SelectItem value="expired">Expired</SelectItem>
                <SelectItem value="past_due">Past Due</SelectItem>
              </SelectContent>
            </Select>
          </div>
        </CardContent>
      </Card>

      {/* Bulk Actions */}
      {selectedSubscriptions.length > 0 && (
        <Card>
          <CardContent className="py-3">
            <div className="flex items-center justify-between">
              <span className="text-sm text-muted-foreground">
                {selectedSubscriptions.length} subscription(s) selected
              </span>
              <Button variant="outline" size="sm" onClick={() => setSelectedSubscriptions([])}>
                Clear
              </Button>
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
                    checked={selectedSubscriptions.length === filteredSubscriptions.length && filteredSubscriptions.length > 0}
                    onCheckedChange={(checked) => {
                      if (checked) {
                        setSelectedSubscriptions(filteredSubscriptions.map((s) => s.id));
                      } else {
                        setSelectedSubscriptions([]);
                      }
                    }}
                  />
                </TableHead>
                <TableHead>User</TableHead>
                <TableHead>Plan</TableHead>
                <TableHead>Status</TableHead>
                <TableHead>Amount</TableHead>
                <TableHead>Period End</TableHead>
                <TableHead>Created</TableHead>
                <TableHead className="w-12"></TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {filteredSubscriptions.map((subscription) => (
                <TableRow key={subscription.id}>
                  <TableCell>
                    <Checkbox
                      checked={selectedSubscriptions.includes(subscription.id)}
                      onCheckedChange={(checked) => {
                        if (checked) {
                          setSelectedSubscriptions([...selectedSubscriptions, subscription.id]);
                        } else {
                          setSelectedSubscriptions(selectedSubscriptions.filter((id) => id !== subscription.id));
                        }
                      }}
                    />
                  </TableCell>
                  <TableCell>
                    <div className="flex items-center gap-3">
                      <Avatar className="w-8 h-8">
                        <AvatarImage src={subscription.user.photo} />
                        <AvatarFallback className="bg-primary/10 text-primary text-xs">
                          {subscription.user.displayName.charAt(0)}
                        </AvatarFallback>
                      </Avatar>
                      <div>
                        <p className="font-medium text-sm">{subscription.user.displayName}</p>
                        <p className="text-xs text-muted-foreground">{subscription.user.email}</p>
                      </div>
                    </div>
                  </TableCell>
                  <TableCell>
                    {getPlanBadge(subscription.plan)}
                  </TableCell>
                  <TableCell>
                    <div className="space-y-1">
                      {getStatusBadge(subscription.status)}
                      {subscription.cancelAtPeriodEnd && (
                        <p className="text-xs text-muted-foreground">Cancels at period end</p>
                      )}
                    </div>
                  </TableCell>
                  <TableCell>
                    <div>
                      <p className="font-medium">${subscription.amount.toFixed(2)}</p>
                      <p className="text-xs text-muted-foreground">/{subscription.interval}</p>
                    </div>
                  </TableCell>
                  <TableCell className="text-muted-foreground">
                    <div className="flex items-center gap-1">
                      <Calendar className="w-4 h-4" />
                      {format(new Date(subscription.currentPeriodEnd), "MMM d, yyyy")}
                    </div>
                  </TableCell>
                  <TableCell className="text-muted-foreground">
                    {format(new Date(subscription.createdAt), "MMM d, yyyy")}
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
                            setCurrentSubscription(subscription);
                            setShowViewDialog(true);
                          }}
                        >
                          <Eye className="w-4 h-4 mr-2" />
                          View Details
                        </DropdownMenuItem>
                        {subscription.stripeSubscriptionId && (
                          <DropdownMenuItem
                            onClick={() => window.open(`https://dashboard.stripe.com/subscriptions/${subscription.stripeSubscriptionId}`, '_blank')}
                          >
                            <CreditCard className="w-4 h-4 mr-2" />
                            View in Stripe
                          </DropdownMenuItem>
                        )}
                        <DropdownMenuSeparator />
                        {subscription.status === "canceled" && (
                          <DropdownMenuItem
                            onClick={() => handleReactivate(subscription.id)}
                          >
                            <CheckCircle className="w-4 h-4 mr-2" />
                            Reactivate
                          </DropdownMenuItem>
                        )}
                        {subscription.status === "active" && subscription.plan !== "free" && (
                          <>
                            <DropdownMenuItem
                              onClick={() => handleRefund(subscription.id)}
                            >
                              <RefreshCw className="w-4 h-4 mr-2" />
                              Process Refund
                            </DropdownMenuItem>
                            <DropdownMenuItem
                              className="text-destructive"
                              onClick={() => {
                                setCurrentSubscription(subscription);
                                setShowCancelDialog(true);
                              }}
                            >
                              <Trash2 className="w-4 h-4 mr-2" />
                              Cancel Subscription
                            </DropdownMenuItem>
                          </>
                        )}
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
            <DialogTitle>Subscription Details</DialogTitle>
            <DialogDescription>
              Subscription #{currentSubscription?.id}
            </DialogDescription>
          </DialogHeader>
          {currentSubscription && (
            <div className="space-y-6">
              <div className="flex items-center gap-4">
                <Avatar className="w-16 h-16">
                  <AvatarImage src={currentSubscription.user.photo} />
                  <AvatarFallback className="bg-primary text-primary-foreground text-xl">
                    {currentSubscription.user.displayName.charAt(0)}
                  </AvatarFallback>
                </Avatar>
                <div>
                  <p className="font-semibold text-lg">{currentSubscription.user.displayName}</p>
                  <p className="text-sm text-muted-foreground">{currentSubscription.user.email}</p>
                  <Badge variant="outline" className="mt-1 capitalize">
                    {currentSubscription.user.role}
                  </Badge>
                </div>
              </div>
              <div className="grid grid-cols-2 gap-4 text-sm">
                <div>
                  <p className="text-muted-foreground">Plan</p>
                  <div className="mt-1">{getPlanBadge(currentSubscription.plan)}</div>
                </div>
                <div>
                  <p className="text-muted-foreground">Status</p>
                  <div className="mt-1">{getStatusBadge(currentSubscription.status)}</div>
                </div>
                <div>
                  <p className="text-muted-foreground">Amount</p>
                  <p className="font-medium">
                    ${currentSubscription.amount.toFixed(2)}/{currentSubscription.interval}
                  </p>
                </div>
                <div>
                  <p className="text-muted-foreground">Stripe ID</p>
                  <p className="font-mono text-xs">
                    {currentSubscription.stripeSubscriptionId || "N/A"}
                  </p>
                </div>
                <div>
                  <p className="text-muted-foreground">Period Start</p>
                  <p className="font-medium">
                    {format(new Date(currentSubscription.currentPeriodStart), "MMM d, yyyy")}
                  </p>
                </div>
                <div>
                  <p className="text-muted-foreground">Period End</p>
                  <p className="font-medium">
                    {format(new Date(currentSubscription.currentPeriodEnd), "MMM d, yyyy")}
                  </p>
                </div>
                <div>
                  <p className="text-muted-foreground">Created</p>
                  <p className="font-medium">
                    {format(new Date(currentSubscription.createdAt), "MMM d, yyyy")}
                  </p>
                </div>
                <div>
                  <p className="text-muted-foreground">Cancel at End</p>
                  <p className="font-medium">
                    {currentSubscription.cancelAtPeriodEnd ? "Yes" : "No"}
                  </p>
                </div>
              </div>
            </div>
          )}
          <DialogFooter>
            <Button variant="outline" onClick={() => setShowViewDialog(false)}>
              Close
            </Button>
            {currentSubscription?.stripeSubscriptionId && (
              <Button
                onClick={() => window.open(`https://dashboard.stripe.com/subscriptions/${currentSubscription.stripeSubscriptionId}`, '_blank')}
              >
                <CreditCard className="w-4 h-4 mr-2" />
                Open in Stripe
              </Button>
            )}
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Cancel Dialog */}
      <AlertDialog open={showCancelDialog} onOpenChange={setShowCancelDialog}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Cancel Subscription</AlertDialogTitle>
            <AlertDialogDescription>
              Are you sure you want to cancel the subscription for{" "}
              {currentSubscription?.user.displayName}? This will end their access
              at the end of the current billing period.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Keep Subscription</AlertDialogCancel>
            <AlertDialogAction
              onClick={handleCancel}
              className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
            >
              Cancel Subscription
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  );
}
