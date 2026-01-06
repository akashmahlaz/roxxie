"use client";

import { useState, useEffect, useCallback } from "react";
import { 
  Search, MoreHorizontal, Trash2, Eye, Flag, 
  Loader2, Download, CheckCircle, XCircle,
  AlertTriangle, Shield, MessageSquare, Ban
} from "lucide-react";
import { toast } from "sonner";
import { format } from "date-fns";

import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Checkbox } from "@/components/ui/checkbox";
import { Textarea } from "@/components/ui/textarea";
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

interface Report {
  id: string;
  reporterId: string;
  reportedId: string;
  type: "spam" | "harassment" | "inappropriate" | "fake" | "other";
  status: "pending" | "reviewing" | "resolved" | "dismissed";
  priority: "low" | "medium" | "high" | "critical";
  description: string;
  resolution?: string;
  createdAt: string;
  updatedAt?: string;
  reporter: {
    id: string;
    displayName: string;
    email: string;
    photo?: string;
  };
  reported: {
    id: string;
    displayName: string;
    email: string;
    photo?: string;
    role: string;
  };
}

export default function ReportsPage() {
  const [reports, setReports] = useState<Report[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState("");
  const [typeFilter, setTypeFilter] = useState<string>("all");
  const [statusFilter, setStatusFilter] = useState<string>("all");
  const [priorityFilter, setPriorityFilter] = useState<string>("all");
  const [selectedReports, setSelectedReports] = useState<string[]>([]);
  
  const [showResolveDialog, setShowResolveDialog] = useState(false);
  const [showViewDialog, setShowViewDialog] = useState(false);
  const [showBanDialog, setShowBanDialog] = useState(false);
  const [currentReport, setCurrentReport] = useState<Report | null>(null);
  const [resolution, setResolution] = useState("");

  const loadReports = useCallback(async () => {
    try {
      const response = await api.get(endpoints.admin.reports);
      setReports(response.data.reports || response.data);
    } catch {
      // Mock data
      setReports([
        { id: "1", reporterId: "u1", reportedId: "u2", type: "harassment", status: "pending", priority: "high", description: "User sent inappropriate messages repeatedly despite being asked to stop.", createdAt: "2024-01-15T10:30:00", reporter: { id: "u1", displayName: "Sarah Smith", email: "sarah@example.com" }, reported: { id: "u2", displayName: "John Doe", email: "john@example.com", role: "artist" } },
        { id: "2", reporterId: "u3", reportedId: "u4", type: "spam", status: "reviewing", priority: "medium", description: "User is sending promotional messages to multiple users.", createdAt: "2024-01-14T15:20:00", reporter: { id: "u3", displayName: "Mike Wilson", email: "mike@example.com" }, reported: { id: "u4", displayName: "Promo Guy", email: "promo@example.com", role: "artist" } },
        { id: "3", reporterId: "u5", reportedId: "u6", type: "fake", status: "resolved", priority: "high", resolution: "Account verified as legitimate after review.", description: "This account seems to be impersonating a famous artist.", createdAt: "2024-01-13T09:00:00", updatedAt: "2024-01-14T11:00:00", reporter: { id: "u5", displayName: "Emily Chen", email: "emily@example.com" }, reported: { id: "u6", displayName: "Famous Artist", email: "artist@example.com", role: "artist" } },
        { id: "4", reporterId: "u7", reportedId: "u8", type: "inappropriate", status: "pending", priority: "critical", description: "User has uploaded inappropriate profile photos.", createdAt: "2024-01-15T08:00:00", reporter: { id: "u7", displayName: "Jazz Club NYC", email: "nyc@example.com" }, reported: { id: "u8", displayName: "Bad User", email: "bad@example.com", role: "venue" } },
        { id: "5", reporterId: "u9", reportedId: "u10", type: "other", status: "dismissed", priority: "low", resolution: "No violation found after investigation.", description: "User is being rude in conversations.", createdAt: "2024-01-12T14:00:00", updatedAt: "2024-01-13T10:00:00", reporter: { id: "u9", displayName: "Rock Star", email: "rock@example.com" }, reported: { id: "u10", displayName: "Honest Reviewer", email: "honest@example.com", role: "artist" } },
      ]);
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    loadReports();
  }, [loadReports]);

  const filteredReports = reports.filter((report) => {
    const matchesSearch = 
      report.reporter.displayName.toLowerCase().includes(searchQuery.toLowerCase()) ||
      report.reported.displayName.toLowerCase().includes(searchQuery.toLowerCase()) ||
      report.description.toLowerCase().includes(searchQuery.toLowerCase());
    const matchesType = typeFilter === "all" || report.type === typeFilter;
    const matchesStatus = statusFilter === "all" || report.status === statusFilter;
    const matchesPriority = priorityFilter === "all" || report.priority === priorityFilter;
    return matchesSearch && matchesType && matchesStatus && matchesPriority;
  });

  const handleResolve = async () => {
    if (!currentReport || !resolution.trim()) return;
    try {
      await api.patch(`${endpoints.admin.reports}/${currentReport.id}`, {
        status: "resolved",
        resolution: resolution.trim(),
      });
      toast.success("Report resolved");
      setShowResolveDialog(false);
      setCurrentReport(null);
      setResolution("");
      loadReports();
    } catch {
      toast.error("Failed to resolve report");
    }
  };

  const handleDismiss = async (reportId: string) => {
    try {
      await api.patch(`${endpoints.admin.reports}/${reportId}`, {
        status: "dismissed",
        resolution: "Report dismissed - No action taken",
      });
      toast.success("Report dismissed");
      loadReports();
    } catch {
      toast.error("Failed to dismiss report");
    }
  };

  const handleStatusChange = async (reportId: string, newStatus: string) => {
    try {
      await api.patch(`${endpoints.admin.reports}/${reportId}`, { status: newStatus });
      toast.success("Status updated");
      loadReports();
    } catch {
      toast.error("Failed to update status");
    }
  };

  const handleBanUser = async () => {
    if (!currentReport) return;
    try {
      await api.post(`${endpoints.admin.users}/${currentReport.reportedId}/ban`);
      await api.patch(`${endpoints.admin.reports}/${currentReport.id}`, {
        status: "resolved",
        resolution: "User has been banned from the platform.",
      });
      toast.success("User banned and report resolved");
      setShowBanDialog(false);
      setCurrentReport(null);
      loadReports();
    } catch {
      toast.error("Failed to ban user");
    }
  };

  const handleBulkDismiss = async () => {
    try {
      await Promise.all(
        selectedReports.map((id) => 
          api.patch(`${endpoints.admin.reports}/${id}`, {
            status: "dismissed",
            resolution: "Bulk dismissed",
          })
        )
      );
      toast.success(`${selectedReports.length} reports dismissed`);
      setSelectedReports([]);
      loadReports();
    } catch {
      toast.error("Failed to dismiss reports");
    }
  };

  const getStatusBadge = (status: string) => {
    switch (status) {
      case "pending":
        return <Badge variant="outline" className="border-yellow-500 text-yellow-500">Pending</Badge>;
      case "reviewing":
        return <Badge className="bg-blue-500">Reviewing</Badge>;
      case "resolved":
        return <Badge className="bg-green-500">Resolved</Badge>;
      case "dismissed":
        return <Badge variant="secondary">Dismissed</Badge>;
      default:
        return <Badge variant="outline">{status}</Badge>;
    }
  };

  const getTypeBadge = (type: string) => {
    switch (type) {
      case "harassment":
        return <Badge variant="destructive">Harassment</Badge>;
      case "spam":
        return <Badge className="bg-orange-500">Spam</Badge>;
      case "inappropriate":
        return <Badge variant="destructive">Inappropriate</Badge>;
      case "fake":
        return <Badge className="bg-purple-500">Fake Account</Badge>;
      default:
        return <Badge variant="outline">Other</Badge>;
    }
  };

  const getPriorityBadge = (priority: string) => {
    switch (priority) {
      case "critical":
        return <Badge variant="destructive">Critical</Badge>;
      case "high":
        return <Badge className="bg-orange-500">High</Badge>;
      case "medium":
        return <Badge className="bg-yellow-500">Medium</Badge>;
      default:
        return <Badge variant="outline">Low</Badge>;
    }
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
          <h1 className="text-3xl font-bold">Reports</h1>
          <p className="text-muted-foreground">
            Review and manage user reports
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
              <Flag className="w-5 h-5 text-blue-500" />
              <div className="text-2xl font-bold">{reports.length}</div>
            </div>
            <p className="text-xs text-muted-foreground">Total Reports</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center gap-2">
              <AlertTriangle className="w-5 h-5 text-yellow-500" />
              <div className="text-2xl font-bold">
                {reports.filter((r) => r.status === "pending").length}
              </div>
            </div>
            <p className="text-xs text-muted-foreground">Pending</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center gap-2">
              <Shield className="w-5 h-5 text-red-500" />
              <div className="text-2xl font-bold">
                {reports.filter((r) => r.priority === "critical" || r.priority === "high").length}
              </div>
            </div>
            <p className="text-xs text-muted-foreground">High Priority</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center gap-2">
              <CheckCircle className="w-5 h-5 text-green-500" />
              <div className="text-2xl font-bold">
                {reports.filter((r) => r.status === "resolved").length}
              </div>
            </div>
            <p className="text-xs text-muted-foreground">Resolved</p>
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
                placeholder="Search reports..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="pl-8"
              />
            </div>
            <Select value={typeFilter} onValueChange={setTypeFilter}>
              <SelectTrigger className="w-[150px]">
                <SelectValue placeholder="Type" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All Types</SelectItem>
                <SelectItem value="harassment">Harassment</SelectItem>
                <SelectItem value="spam">Spam</SelectItem>
                <SelectItem value="inappropriate">Inappropriate</SelectItem>
                <SelectItem value="fake">Fake Account</SelectItem>
                <SelectItem value="other">Other</SelectItem>
              </SelectContent>
            </Select>
            <Select value={statusFilter} onValueChange={setStatusFilter}>
              <SelectTrigger className="w-[150px]">
                <SelectValue placeholder="Status" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All Status</SelectItem>
                <SelectItem value="pending">Pending</SelectItem>
                <SelectItem value="reviewing">Reviewing</SelectItem>
                <SelectItem value="resolved">Resolved</SelectItem>
                <SelectItem value="dismissed">Dismissed</SelectItem>
              </SelectContent>
            </Select>
            <Select value={priorityFilter} onValueChange={setPriorityFilter}>
              <SelectTrigger className="w-[150px]">
                <SelectValue placeholder="Priority" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All Priority</SelectItem>
                <SelectItem value="critical">Critical</SelectItem>
                <SelectItem value="high">High</SelectItem>
                <SelectItem value="medium">Medium</SelectItem>
                <SelectItem value="low">Low</SelectItem>
              </SelectContent>
            </Select>
          </div>
        </CardContent>
      </Card>

      {/* Bulk Actions */}
      {selectedReports.length > 0 && (
        <Card>
          <CardContent className="py-3">
            <div className="flex items-center justify-between">
              <span className="text-sm text-muted-foreground">
                {selectedReports.length} report(s) selected
              </span>
              <div className="flex gap-2">
                <Button variant="outline" size="sm" onClick={() => setSelectedReports([])}>
                  Clear
                </Button>
                <Button
                  variant="secondary"
                  size="sm"
                  onClick={handleBulkDismiss}
                >
                  Dismiss Selected
                </Button>
              </div>
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
                    checked={selectedReports.length === filteredReports.length && filteredReports.length > 0}
                    onCheckedChange={(checked) => {
                      if (checked) {
                        setSelectedReports(filteredReports.map((r) => r.id));
                      } else {
                        setSelectedReports([]);
                      }
                    }}
                  />
                </TableHead>
                <TableHead>Reporter</TableHead>
                <TableHead>Reported User</TableHead>
                <TableHead>Type</TableHead>
                <TableHead>Priority</TableHead>
                <TableHead>Status</TableHead>
                <TableHead>Date</TableHead>
                <TableHead className="w-12"></TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {filteredReports.map((report) => (
                <TableRow key={report.id}>
                  <TableCell>
                    <Checkbox
                      checked={selectedReports.includes(report.id)}
                      onCheckedChange={(checked) => {
                        if (checked) {
                          setSelectedReports([...selectedReports, report.id]);
                        } else {
                          setSelectedReports(selectedReports.filter((id) => id !== report.id));
                        }
                      }}
                    />
                  </TableCell>
                  <TableCell>
                    <div className="flex items-center gap-3">
                      <Avatar className="w-8 h-8">
                        <AvatarImage src={report.reporter.photo} />
                        <AvatarFallback className="bg-primary/10 text-primary text-xs">
                          {report.reporter.displayName.charAt(0)}
                        </AvatarFallback>
                      </Avatar>
                      <div>
                        <p className="font-medium text-sm">{report.reporter.displayName}</p>
                        <p className="text-xs text-muted-foreground">{report.reporter.email}</p>
                      </div>
                    </div>
                  </TableCell>
                  <TableCell>
                    <div className="flex items-center gap-3">
                      <Avatar className="w-8 h-8">
                        <AvatarImage src={report.reported.photo} />
                        <AvatarFallback className="bg-red-100 text-red-500 text-xs">
                          {report.reported.displayName.charAt(0)}
                        </AvatarFallback>
                      </Avatar>
                      <div>
                        <p className="font-medium text-sm">{report.reported.displayName}</p>
                        <Badge variant="outline" className="text-xs capitalize">
                          {report.reported.role}
                        </Badge>
                      </div>
                    </div>
                  </TableCell>
                  <TableCell>
                    {getTypeBadge(report.type)}
                  </TableCell>
                  <TableCell>
                    {getPriorityBadge(report.priority)}
                  </TableCell>
                  <TableCell>
                    {getStatusBadge(report.status)}
                  </TableCell>
                  <TableCell className="text-muted-foreground">
                    {format(new Date(report.createdAt), "MMM d, yyyy")}
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
                            setCurrentReport(report);
                            setShowViewDialog(true);
                          }}
                        >
                          <Eye className="w-4 h-4 mr-2" />
                          View Details
                        </DropdownMenuItem>
                        {report.status === "pending" && (
                          <DropdownMenuItem
                            onClick={() => handleStatusChange(report.id, "reviewing")}
                          >
                            <MessageSquare className="w-4 h-4 mr-2" />
                            Start Review
                          </DropdownMenuItem>
                        )}
                        <DropdownMenuSeparator />
                        {report.status !== "resolved" && report.status !== "dismissed" && (
                          <>
                            <DropdownMenuItem
                              onClick={() => {
                                setCurrentReport(report);
                                setShowResolveDialog(true);
                              }}
                            >
                              <CheckCircle className="w-4 h-4 mr-2" />
                              Resolve
                            </DropdownMenuItem>
                            <DropdownMenuItem
                              onClick={() => handleDismiss(report.id)}
                            >
                              <XCircle className="w-4 h-4 mr-2" />
                              Dismiss
                            </DropdownMenuItem>
                            <DropdownMenuSeparator />
                            <DropdownMenuItem
                              className="text-destructive"
                              onClick={() => {
                                setCurrentReport(report);
                                setShowBanDialog(true);
                              }}
                            >
                              <Ban className="w-4 h-4 mr-2" />
                              Ban User
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
        <DialogContent className="max-w-lg">
          <DialogHeader>
            <DialogTitle>Report Details</DialogTitle>
            <DialogDescription>
              Report #{currentReport?.id}
            </DialogDescription>
          </DialogHeader>
          {currentReport && (
            <div className="space-y-6">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <p className="text-sm font-medium text-muted-foreground mb-2">Reporter</p>
                  <div className="flex items-center gap-3">
                    <Avatar className="w-10 h-10">
                      <AvatarImage src={currentReport.reporter.photo} />
                      <AvatarFallback className="bg-primary/10 text-primary">
                        {currentReport.reporter.displayName.charAt(0)}
                      </AvatarFallback>
                    </Avatar>
                    <div>
                      <p className="font-medium">{currentReport.reporter.displayName}</p>
                      <p className="text-xs text-muted-foreground">{currentReport.reporter.email}</p>
                    </div>
                  </div>
                </div>
                <div>
                  <p className="text-sm font-medium text-muted-foreground mb-2">Reported User</p>
                  <div className="flex items-center gap-3">
                    <Avatar className="w-10 h-10">
                      <AvatarImage src={currentReport.reported.photo} />
                      <AvatarFallback className="bg-red-100 text-red-500">
                        {currentReport.reported.displayName.charAt(0)}
                      </AvatarFallback>
                    </Avatar>
                    <div>
                      <p className="font-medium">{currentReport.reported.displayName}</p>
                      <p className="text-xs text-muted-foreground capitalize">{currentReport.reported.role}</p>
                    </div>
                  </div>
                </div>
              </div>
              <div className="grid grid-cols-3 gap-4 text-sm">
                <div>
                  <p className="text-muted-foreground">Type</p>
                  <div className="mt-1">{getTypeBadge(currentReport.type)}</div>
                </div>
                <div>
                  <p className="text-muted-foreground">Priority</p>
                  <div className="mt-1">{getPriorityBadge(currentReport.priority)}</div>
                </div>
                <div>
                  <p className="text-muted-foreground">Status</p>
                  <div className="mt-1">{getStatusBadge(currentReport.status)}</div>
                </div>
              </div>
              <div>
                <p className="text-sm font-medium text-muted-foreground mb-2">Description</p>
                <p className="text-sm bg-muted p-3 rounded-md">{currentReport.description}</p>
              </div>
              {currentReport.resolution && (
                <div>
                  <p className="text-sm font-medium text-muted-foreground mb-2">Resolution</p>
                  <p className="text-sm bg-green-50 dark:bg-green-950 p-3 rounded-md border border-green-200 dark:border-green-800">
                    {currentReport.resolution}
                  </p>
                </div>
              )}
              <div className="grid grid-cols-2 gap-4 text-sm">
                <div>
                  <p className="text-muted-foreground">Created</p>
                  <p className="font-medium">
                    {format(new Date(currentReport.createdAt), "MMM d, yyyy h:mm a")}
                  </p>
                </div>
                {currentReport.updatedAt && (
                  <div>
                    <p className="text-muted-foreground">Updated</p>
                    <p className="font-medium">
                      {format(new Date(currentReport.updatedAt), "MMM d, yyyy h:mm a")}
                    </p>
                  </div>
                )}
              </div>
            </div>
          )}
          <DialogFooter>
            <Button variant="outline" onClick={() => setShowViewDialog(false)}>
              Close
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Resolve Dialog */}
      <Dialog open={showResolveDialog} onOpenChange={setShowResolveDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Resolve Report</DialogTitle>
            <DialogDescription>
              Provide a resolution for this report.
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-4">
            <Textarea
              placeholder="Enter resolution details..."
              value={resolution}
              onChange={(e) => setResolution(e.target.value)}
              rows={4}
            />
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setShowResolveDialog(false)}>
              Cancel
            </Button>
            <Button onClick={handleResolve} disabled={!resolution.trim()}>
              <CheckCircle className="w-4 h-4 mr-2" />
              Resolve
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Ban Dialog */}
      <AlertDialog open={showBanDialog} onOpenChange={setShowBanDialog}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Ban User</AlertDialogTitle>
            <AlertDialogDescription>
              Are you sure you want to ban {currentReport?.reported.displayName}?
              This will prevent them from accessing the platform and will resolve
              this report automatically.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancel</AlertDialogCancel>
            <AlertDialogAction
              onClick={handleBanUser}
              className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
            >
              <Ban className="w-4 h-4 mr-2" />
              Ban User
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  );
}
