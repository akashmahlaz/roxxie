"use client";

import { useState, useEffect } from "react";
import { 
  Users, Music2, Building2, Heart, CreditCard, 
  TrendingUp, TrendingDown, Activity, ArrowUpRight,
  DollarSign, UserPlus, Loader2
} from "lucide-react";
import { toast } from "sonner";

import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Progress } from "@/components/ui/progress";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import {
  ChartContainer,
  ChartTooltip,
  ChartTooltipContent,
} from "@/components/ui/chart";
import {
  AreaChart,
  Area,
  BarChart,
  Bar,
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  ResponsiveContainer,
  PieChart,
  Pie,
  Cell,
} from "recharts";
import api, { endpoints } from "@/lib/api";
import { cn } from "@/lib/utils";

// Mock data for charts
const revenueData = [
  { month: "Jan", revenue: 4500, users: 120 },
  { month: "Feb", revenue: 5200, users: 145 },
  { month: "Mar", revenue: 4800, users: 132 },
  { month: "Apr", revenue: 6100, users: 178 },
  { month: "May", revenue: 7200, users: 210 },
  { month: "Jun", revenue: 6800, users: 195 },
  { month: "Jul", revenue: 8500, users: 248 },
];

const matchesData = [
  { day: "Mon", matches: 45, messages: 320 },
  { day: "Tue", matches: 52, messages: 380 },
  { day: "Wed", matches: 48, messages: 340 },
  { day: "Thu", matches: 61, messages: 420 },
  { day: "Fri", matches: 72, messages: 510 },
  { day: "Sat", matches: 85, messages: 620 },
  { day: "Sun", matches: 68, messages: 480 },
];

const subscriptionDistribution = [
  { name: "Free", value: 65, color: "hsl(var(--muted))" },
  { name: "Pro", value: 25, color: "hsl(var(--primary))" },
  { name: "Premium", value: 10, color: "hsl(var(--chart-3))" },
];

interface DashboardStats {
  totalUsers: number;
  totalArtists: number;
  totalVenues: number;
  totalMatches: number;
  activeSubscriptions: number;
  monthlyRevenue: number;
  userGrowth: number;
  matchRate: number;
}

interface RecentUser {
  id: string;
  fullName: string;
  email: string;
  role: string;
  photo?: string;
  createdAt: string;
}

export default function AdminDashboardPage() {
  const [isLoading, setIsLoading] = useState(true);
  const [stats, setStats] = useState<DashboardStats>({
    totalUsers: 0,
    totalArtists: 0,
    totalVenues: 0,
    totalMatches: 0,
    activeSubscriptions: 0,
    monthlyRevenue: 0,
    userGrowth: 0,
    matchRate: 0,
  });
  const [recentUsers, setRecentUsers] = useState<RecentUser[]>([]);

  useEffect(() => {
    loadDashboardData();
  }, []);

  const loadDashboardData = async () => {
    try {
      const response = await api.get(endpoints.admin.dashboard);
      setStats(response.data.stats);
      setRecentUsers(response.data.recentUsers || []);
    } catch {
      // Use mock data for now
      setStats({
        totalUsers: 1247,
        totalArtists: 892,
        totalVenues: 355,
        totalMatches: 3420,
        activeSubscriptions: 312,
        monthlyRevenue: 8524,
        userGrowth: 12.5,
        matchRate: 68,
      });
      setRecentUsers([
        { id: "1", fullName: "John Doe", email: "john@example.com", role: "artist", createdAt: "2024-01-15" },
        { id: "2", fullName: "Jazz Club NYC", email: "jazz@club.com", role: "venue", createdAt: "2024-01-14" },
        { id: "3", fullName: "Sarah Smith", email: "sarah@example.com", role: "artist", createdAt: "2024-01-13" },
        { id: "4", fullName: "Rock Venue LA", email: "rock@venue.com", role: "venue", createdAt: "2024-01-12" },
      ]);
    } finally {
      setIsLoading(false);
    }
  };

  if (isLoading) {
    return (
      <div className="flex items-center justify-center min-h-[60vh]">
        <Loader2 className="w-8 h-8 animate-spin text-primary" />
      </div>
    );
  }

  const statCards = [
    {
      title: "Total Users",
      value: stats.totalUsers.toLocaleString(),
      change: `+${stats.userGrowth}%`,
      changeType: "positive" as const,
      icon: Users,
      description: "from last month",
    },
    {
      title: "Monthly Revenue",
      value: `$${stats.monthlyRevenue.toLocaleString()}`,
      change: "+18.2%",
      changeType: "positive" as const,
      icon: DollarSign,
      description: "from last month",
    },
    {
      title: "Active Subscriptions",
      value: stats.activeSubscriptions.toLocaleString(),
      change: "+7.4%",
      changeType: "positive" as const,
      icon: CreditCard,
      description: "paid users",
    },
    {
      title: "Match Rate",
      value: `${stats.matchRate}%`,
      change: "-2.1%",
      changeType: "negative" as const,
      icon: Heart,
      description: "conversion rate",
    },
  ];

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">Dashboard</h1>
          <p className="text-muted-foreground">
            Welcome back! Here&apos;s what&apos;s happening with GigMatch.
          </p>
        </div>
        <Button>
          <ArrowUpRight className="w-4 h-4 mr-2" />
          View Reports
        </Button>
      </div>

      {/* Stats Cards */}
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        {statCards.map((stat) => (
          <Card key={stat.title}>
            <CardHeader className="flex flex-row items-center justify-between pb-2">
              <CardTitle className="text-sm font-medium text-muted-foreground">
                {stat.title}
              </CardTitle>
              <stat.icon className="w-4 h-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stat.value}</div>
              <div className="flex items-center text-xs text-muted-foreground">
                <span
                  className={cn(
                    "flex items-center",
                    stat.changeType === "positive"
                      ? "text-green-600"
                      : "text-red-600"
                  )}
                >
                  {stat.changeType === "positive" ? (
                    <TrendingUp className="w-3 h-3 mr-1" />
                  ) : (
                    <TrendingDown className="w-3 h-3 mr-1" />
                  )}
                  {stat.change}
                </span>
                <span className="ml-1">{stat.description}</span>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      {/* Charts Row */}
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-7">
        {/* Revenue Chart */}
        <Card className="lg:col-span-4">
          <CardHeader>
            <CardTitle>Revenue Overview</CardTitle>
            <CardDescription>Monthly revenue and user growth</CardDescription>
          </CardHeader>
          <CardContent>
            <ChartContainer
              config={{
                revenue: { label: "Revenue", color: "hsl(var(--primary))" },
                users: { label: "Users", color: "hsl(var(--muted-foreground))" },
              }}
              className="h-[300px]"
            >
              <ResponsiveContainer width="100%" height="100%">
                <AreaChart data={revenueData}>
                  <defs>
                    <linearGradient id="colorRevenue" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor="hsl(var(--primary))" stopOpacity={0.3} />
                      <stop offset="95%" stopColor="hsl(var(--primary))" stopOpacity={0} />
                    </linearGradient>
                  </defs>
                  <CartesianGrid strokeDasharray="3 3" className="stroke-muted" />
                  <XAxis dataKey="month" className="text-xs" />
                  <YAxis className="text-xs" />
                  <ChartTooltip content={<ChartTooltipContent />} />
                  <Area
                    type="monotone"
                    dataKey="revenue"
                    stroke="hsl(var(--primary))"
                    fillOpacity={1}
                    fill="url(#colorRevenue)"
                  />
                </AreaChart>
              </ResponsiveContainer>
            </ChartContainer>
          </CardContent>
        </Card>

        {/* Subscription Distribution */}
        <Card className="lg:col-span-3">
          <CardHeader>
            <CardTitle>Subscription Distribution</CardTitle>
            <CardDescription>User breakdown by plan</CardDescription>
          </CardHeader>
          <CardContent>
            <ChartContainer
              config={{
                value: { label: "Users" },
              }}
              className="h-[300px]"
            >
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie
                    data={subscriptionDistribution}
                    cx="50%"
                    cy="50%"
                    innerRadius={60}
                    outerRadius={100}
                    paddingAngle={5}
                    dataKey="value"
                  >
                    {subscriptionDistribution.map((entry, index) => (
                      <Cell key={`cell-${index}`} fill={entry.color} />
                    ))}
                  </Pie>
                  <ChartTooltip content={<ChartTooltipContent />} />
                </PieChart>
              </ResponsiveContainer>
            </ChartContainer>
            <div className="flex justify-center gap-4 mt-4">
              {subscriptionDistribution.map((item) => (
                <div key={item.name} className="flex items-center gap-2">
                  <div
                    className="w-3 h-3 rounded-full"
                    style={{ backgroundColor: item.color }}
                  />
                  <span className="text-sm text-muted-foreground">
                    {item.name} ({item.value}%)
                  </span>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Second Charts Row */}
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-7">
        {/* Matches Activity */}
        <Card className="lg:col-span-4">
          <CardHeader>
            <CardTitle>Weekly Activity</CardTitle>
            <CardDescription>Matches and messages this week</CardDescription>
          </CardHeader>
          <CardContent>
            <ChartContainer
              config={{
                matches: { label: "Matches", color: "hsl(var(--primary))" },
                messages: { label: "Messages", color: "hsl(var(--muted-foreground))" },
              }}
              className="h-[250px]"
            >
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={matchesData}>
                  <CartesianGrid strokeDasharray="3 3" className="stroke-muted" />
                  <XAxis dataKey="day" className="text-xs" />
                  <YAxis className="text-xs" />
                  <ChartTooltip content={<ChartTooltipContent />} />
                  <Bar dataKey="matches" fill="hsl(var(--primary))" radius={4} />
                  <Bar dataKey="messages" fill="hsl(var(--muted-foreground))" radius={4} opacity={0.5} />
                </BarChart>
              </ResponsiveContainer>
            </ChartContainer>
          </CardContent>
        </Card>

        {/* Recent Users */}
        <Card className="lg:col-span-3">
          <CardHeader>
            <CardTitle>Recent Users</CardTitle>
            <CardDescription>Latest sign ups</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              {recentUsers.map((user) => (
                <div key={user.id} className="flex items-center gap-4">
                  <Avatar>
                    <AvatarImage src={user.photo} />
                    <AvatarFallback className="bg-primary/10 text-primary">
                      {user.fullName.charAt(0)}
                    </AvatarFallback>
                  </Avatar>
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-medium truncate">{user.fullName}</p>
                    <p className="text-xs text-muted-foreground truncate">
                      {user.email}
                    </p>
                  </div>
                  <Badge variant="outline" className="capitalize">
                    {user.role}
                  </Badge>
                </div>
              ))}
            </div>
            <Button variant="outline" className="w-full mt-4">
              View all users
            </Button>
          </CardContent>
        </Card>
      </div>

      {/* Quick Stats */}
      <div className="grid gap-4 md:grid-cols-3">
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium flex items-center gap-2">
              <Music2 className="w-4 h-4 text-primary" />
              Artists
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.totalArtists}</div>
            <Progress value={70} className="mt-2" />
            <p className="text-xs text-muted-foreground mt-1">
              70% have completed profiles
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium flex items-center gap-2">
              <Building2 className="w-4 h-4 text-primary" />
              Venues
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.totalVenues}</div>
            <Progress value={82} className="mt-2" />
            <p className="text-xs text-muted-foreground mt-1">
              82% are verified
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium flex items-center gap-2">
              <Heart className="w-4 h-4 text-primary" />
              Total Matches
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.totalMatches.toLocaleString()}</div>
            <Progress value={stats.matchRate} className="mt-2" />
            <p className="text-xs text-muted-foreground mt-1">
              {stats.matchRate}% match success rate
            </p>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
