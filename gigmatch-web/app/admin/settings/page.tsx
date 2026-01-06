"use client";

import { useState } from "react";
import { 
  Save, Shield, Bell, Globe, CreditCard, 
  Database, Mail, Loader2, Eye, EyeOff,
  RefreshCw, Trash2, AlertTriangle
} from "lucide-react";
import { toast } from "sonner";

import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Switch } from "@/components/ui/switch";
import { Textarea } from "@/components/ui/textarea";
import { Separator } from "@/components/ui/separator";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
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
  Tabs,
  TabsContent,
  TabsList,
  TabsTrigger,
} from "@/components/ui/tabs";
import api from "@/lib/api";

export default function SettingsPage() {
  const [isSaving, setIsSaving] = useState(false);
  const [showApiKey, setShowApiKey] = useState(false);
  const [showStripeKey, setShowStripeKey] = useState(false);
  const [showDangerDialog, setShowDangerDialog] = useState(false);
  const [dangerAction, setDangerAction] = useState<string | null>(null);

  // General settings
  const [siteName, setSiteName] = useState("GigMatch");
  const [siteDescription, setSiteDescription] = useState("Connect artists with venues for amazing performances");
  const [supportEmail, setSupportEmail] = useState("support@gigmatch.com");
  const [timezone, setTimezone] = useState("America/New_York");

  // Security settings
  const [twoFactorRequired, setTwoFactorRequired] = useState(false);
  const [sessionTimeout, setSessionTimeout] = useState("30");
  const [maxLoginAttempts, setMaxLoginAttempts] = useState("5");
  const [apiKey, setApiKey] = useState("gm_sk_live_xxxxxxxxxxxxxxxxxxxxx");

  // Notification settings
  const [emailNotifications, setEmailNotifications] = useState(true);
  const [pushNotifications, setPushNotifications] = useState(true);
  const [newUserAlerts, setNewUserAlerts] = useState(true);
  const [reportAlerts, setReportAlerts] = useState(true);
  const [paymentAlerts, setPaymentAlerts] = useState(true);

  // Payment settings
  const [stripePublicKey, setStripePublicKey] = useState("pk_test_xxxxxxxxxxxxxxxxxxxxx");
  const [stripeSecretKey, setStripeSecretKey] = useState("sk_test_xxxxxxxxxxxxxxxxxxxxx");
  const [currency, setCurrency] = useState("USD");
  const [freeTierEnabled, setFreeTierEnabled] = useState(true);
  const [proPrice, setProPrice] = useState("14.99");
  const [premiumPrice, setPremiumPrice] = useState("29.99");

  // Email settings
  const [smtpHost, setSmtpHost] = useState("smtp.resend.com");
  const [smtpPort, setSmtpPort] = useState("587");
  const [smtpUser, setSmtpUser] = useState("resend");
  const [smtpPassword, setSmtpPassword] = useState("re_xxxxxxxxxxxxx");
  const [fromEmail, setFromEmail] = useState("noreply@gigmatch.com");
  const [fromName, setFromName] = useState("GigMatch");

  const handleSave = async () => {
    setIsSaving(true);
    try {
      await api.post("/admin/settings", {
        general: { siteName, siteDescription, supportEmail, timezone },
        security: { twoFactorRequired, sessionTimeout, maxLoginAttempts },
        notifications: { emailNotifications, pushNotifications, newUserAlerts, reportAlerts, paymentAlerts },
        payment: { stripePublicKey, stripeSecretKey, currency, freeTierEnabled, proPrice, premiumPrice },
        email: { smtpHost, smtpPort, smtpUser, smtpPassword, fromEmail, fromName },
      });
      toast.success("Settings saved successfully");
    } catch {
      toast.error("Failed to save settings");
    } finally {
      setIsSaving(false);
    }
  };

  const handleDangerAction = async () => {
    try {
      switch (dangerAction) {
        case "clearCache":
          await api.post("/admin/clear-cache");
          toast.success("Cache cleared successfully");
          break;
        case "resetAnalytics":
          await api.post("/admin/reset-analytics");
          toast.success("Analytics reset successfully");
          break;
        case "purgeInactive":
          await api.post("/admin/purge-inactive");
          toast.success("Inactive users purged successfully");
          break;
      }
    } catch {
      toast.error("Action failed");
    } finally {
      setShowDangerDialog(false);
      setDangerAction(null);
    }
  };

  const regenerateApiKey = async () => {
    try {
      const response = await api.post("/admin/regenerate-api-key");
      setApiKey(response.data.apiKey || "gm_sk_live_newkey123456789");
      toast.success("API key regenerated");
    } catch {
      toast.error("Failed to regenerate API key");
    }
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">Settings</h1>
          <p className="text-muted-foreground">
            Manage application configuration
          </p>
        </div>
        <Button onClick={handleSave} disabled={isSaving}>
          {isSaving ? (
            <Loader2 className="w-4 h-4 mr-2 animate-spin" />
          ) : (
            <Save className="w-4 h-4 mr-2" />
          )}
          Save Changes
        </Button>
      </div>

      <Tabs defaultValue="general" className="space-y-6">
        <TabsList className="grid w-full grid-cols-6 lg:w-auto lg:inline-grid">
          <TabsTrigger value="general">
            <Globe className="w-4 h-4 mr-2" />
            General
          </TabsTrigger>
          <TabsTrigger value="security">
            <Shield className="w-4 h-4 mr-2" />
            Security
          </TabsTrigger>
          <TabsTrigger value="notifications">
            <Bell className="w-4 h-4 mr-2" />
            Notifications
          </TabsTrigger>
          <TabsTrigger value="payment">
            <CreditCard className="w-4 h-4 mr-2" />
            Payment
          </TabsTrigger>
          <TabsTrigger value="email">
            <Mail className="w-4 h-4 mr-2" />
            Email
          </TabsTrigger>
          <TabsTrigger value="danger">
            <AlertTriangle className="w-4 h-4 mr-2" />
            Danger
          </TabsTrigger>
        </TabsList>

        {/* General Settings */}
        <TabsContent value="general">
          <Card>
            <CardHeader>
              <CardTitle>General Settings</CardTitle>
              <CardDescription>
                Configure basic application settings
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-6">
              <div className="grid grid-cols-2 gap-6">
                <div className="space-y-2">
                  <Label htmlFor="siteName">Site Name</Label>
                  <Input
                    id="siteName"
                    value={siteName}
                    onChange={(e) => setSiteName(e.target.value)}
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="supportEmail">Support Email</Label>
                  <Input
                    id="supportEmail"
                    type="email"
                    value={supportEmail}
                    onChange={(e) => setSupportEmail(e.target.value)}
                  />
                </div>
              </div>
              <div className="space-y-2">
                <Label htmlFor="siteDescription">Site Description</Label>
                <Textarea
                  id="siteDescription"
                  value={siteDescription}
                  onChange={(e) => setSiteDescription(e.target.value)}
                  rows={3}
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="timezone">Timezone</Label>
                <Select value={timezone} onValueChange={setTimezone}>
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="America/New_York">Eastern Time (ET)</SelectItem>
                    <SelectItem value="America/Chicago">Central Time (CT)</SelectItem>
                    <SelectItem value="America/Denver">Mountain Time (MT)</SelectItem>
                    <SelectItem value="America/Los_Angeles">Pacific Time (PT)</SelectItem>
                    <SelectItem value="Europe/London">London (GMT)</SelectItem>
                    <SelectItem value="Europe/Paris">Paris (CET)</SelectItem>
                    <SelectItem value="Asia/Tokyo">Tokyo (JST)</SelectItem>
                  </SelectContent>
                </Select>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Security Settings */}
        <TabsContent value="security">
          <Card>
            <CardHeader>
              <CardTitle>Security Settings</CardTitle>
              <CardDescription>
                Configure security and authentication options
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-6">
              <div className="flex items-center justify-between">
                <div className="space-y-0.5">
                  <Label>Require Two-Factor Authentication</Label>
                  <p className="text-sm text-muted-foreground">
                    Require 2FA for all admin users
                  </p>
                </div>
                <Switch
                  checked={twoFactorRequired}
                  onCheckedChange={setTwoFactorRequired}
                />
              </div>
              <Separator />
              <div className="grid grid-cols-2 gap-6">
                <div className="space-y-2">
                  <Label htmlFor="sessionTimeout">Session Timeout (minutes)</Label>
                  <Input
                    id="sessionTimeout"
                    type="number"
                    value={sessionTimeout}
                    onChange={(e) => setSessionTimeout(e.target.value)}
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="maxLoginAttempts">Max Login Attempts</Label>
                  <Input
                    id="maxLoginAttempts"
                    type="number"
                    value={maxLoginAttempts}
                    onChange={(e) => setMaxLoginAttempts(e.target.value)}
                  />
                </div>
              </div>
              <Separator />
              <div className="space-y-2">
                <Label htmlFor="apiKey">API Key</Label>
                <div className="flex gap-2">
                  <div className="relative flex-1">
                    <Input
                      id="apiKey"
                      type={showApiKey ? "text" : "password"}
                      value={apiKey}
                      readOnly
                      className="pr-10 font-mono"
                    />
                    <Button
                      type="button"
                      variant="ghost"
                      size="icon"
                      className="absolute right-0 top-0 h-full"
                      onClick={() => setShowApiKey(!showApiKey)}
                    >
                      {showApiKey ? (
                        <EyeOff className="w-4 h-4" />
                      ) : (
                        <Eye className="w-4 h-4" />
                      )}
                    </Button>
                  </div>
                  <Button variant="outline" onClick={regenerateApiKey}>
                    <RefreshCw className="w-4 h-4 mr-2" />
                    Regenerate
                  </Button>
                </div>
                <p className="text-xs text-muted-foreground">
                  Use this key to authenticate API requests
                </p>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Notification Settings */}
        <TabsContent value="notifications">
          <Card>
            <CardHeader>
              <CardTitle>Notification Settings</CardTitle>
              <CardDescription>
                Configure admin notification preferences
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-6">
              <div className="flex items-center justify-between">
                <div className="space-y-0.5">
                  <Label>Email Notifications</Label>
                  <p className="text-sm text-muted-foreground">
                    Receive notifications via email
                  </p>
                </div>
                <Switch
                  checked={emailNotifications}
                  onCheckedChange={setEmailNotifications}
                />
              </div>
              <Separator />
              <div className="flex items-center justify-between">
                <div className="space-y-0.5">
                  <Label>Push Notifications</Label>
                  <p className="text-sm text-muted-foreground">
                    Receive browser push notifications
                  </p>
                </div>
                <Switch
                  checked={pushNotifications}
                  onCheckedChange={setPushNotifications}
                />
              </div>
              <Separator />
              <h4 className="font-medium">Alert Types</h4>
              <div className="space-y-4">
                <div className="flex items-center justify-between">
                  <Label>New User Registrations</Label>
                  <Switch
                    checked={newUserAlerts}
                    onCheckedChange={setNewUserAlerts}
                  />
                </div>
                <div className="flex items-center justify-between">
                  <Label>New Reports</Label>
                  <Switch
                    checked={reportAlerts}
                    onCheckedChange={setReportAlerts}
                  />
                </div>
                <div className="flex items-center justify-between">
                  <Label>Payment Events</Label>
                  <Switch
                    checked={paymentAlerts}
                    onCheckedChange={setPaymentAlerts}
                  />
                </div>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Payment Settings */}
        <TabsContent value="payment">
          <Card>
            <CardHeader>
              <CardTitle>Payment Settings</CardTitle>
              <CardDescription>
                Configure Stripe and subscription pricing
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-6">
              <div className="space-y-2">
                <Label htmlFor="stripePublicKey">Stripe Publishable Key</Label>
                <Input
                  id="stripePublicKey"
                  value={stripePublicKey}
                  onChange={(e) => setStripePublicKey(e.target.value)}
                  className="font-mono"
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="stripeSecretKey">Stripe Secret Key</Label>
                <div className="relative">
                  <Input
                    id="stripeSecretKey"
                    type={showStripeKey ? "text" : "password"}
                    value={stripeSecretKey}
                    onChange={(e) => setStripeSecretKey(e.target.value)}
                    className="pr-10 font-mono"
                  />
                  <Button
                    type="button"
                    variant="ghost"
                    size="icon"
                    className="absolute right-0 top-0 h-full"
                    onClick={() => setShowStripeKey(!showStripeKey)}
                  >
                    {showStripeKey ? (
                      <EyeOff className="w-4 h-4" />
                    ) : (
                      <Eye className="w-4 h-4" />
                    )}
                  </Button>
                </div>
              </div>
              <Separator />
              <div className="grid grid-cols-2 gap-6">
                <div className="space-y-2">
                  <Label htmlFor="currency">Currency</Label>
                  <Select value={currency} onValueChange={setCurrency}>
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="USD">USD ($)</SelectItem>
                      <SelectItem value="EUR">EUR (€)</SelectItem>
                      <SelectItem value="GBP">GBP (£)</SelectItem>
                      <SelectItem value="CAD">CAD ($)</SelectItem>
                      <SelectItem value="AUD">AUD ($)</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
                <div className="flex items-center justify-between">
                  <div className="space-y-0.5">
                    <Label>Free Tier</Label>
                    <p className="text-sm text-muted-foreground">
                      Enable free plan
                    </p>
                  </div>
                  <Switch
                    checked={freeTierEnabled}
                    onCheckedChange={setFreeTierEnabled}
                  />
                </div>
              </div>
              <Separator />
              <h4 className="font-medium">Subscription Pricing</h4>
              <div className="grid grid-cols-2 gap-6">
                <div className="space-y-2">
                  <Label htmlFor="proPrice">Pro Plan Price (monthly)</Label>
                  <div className="relative">
                    <span className="absolute left-3 top-2.5 text-muted-foreground">$</span>
                    <Input
                      id="proPrice"
                      type="number"
                      step="0.01"
                      value={proPrice}
                      onChange={(e) => setProPrice(e.target.value)}
                      className="pl-7"
                    />
                  </div>
                </div>
                <div className="space-y-2">
                  <Label htmlFor="premiumPrice">Premium Plan Price (monthly)</Label>
                  <div className="relative">
                    <span className="absolute left-3 top-2.5 text-muted-foreground">$</span>
                    <Input
                      id="premiumPrice"
                      type="number"
                      step="0.01"
                      value={premiumPrice}
                      onChange={(e) => setPremiumPrice(e.target.value)}
                      className="pl-7"
                    />
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Email Settings */}
        <TabsContent value="email">
          <Card>
            <CardHeader>
              <CardTitle>Email Settings</CardTitle>
              <CardDescription>
                Configure SMTP and email delivery
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-6">
              <div className="grid grid-cols-2 gap-6">
                <div className="space-y-2">
                  <Label htmlFor="smtpHost">SMTP Host</Label>
                  <Input
                    id="smtpHost"
                    value={smtpHost}
                    onChange={(e) => setSmtpHost(e.target.value)}
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="smtpPort">SMTP Port</Label>
                  <Input
                    id="smtpPort"
                    value={smtpPort}
                    onChange={(e) => setSmtpPort(e.target.value)}
                  />
                </div>
              </div>
              <div className="grid grid-cols-2 gap-6">
                <div className="space-y-2">
                  <Label htmlFor="smtpUser">SMTP Username</Label>
                  <Input
                    id="smtpUser"
                    value={smtpUser}
                    onChange={(e) => setSmtpUser(e.target.value)}
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="smtpPassword">SMTP Password</Label>
                  <Input
                    id="smtpPassword"
                    type="password"
                    value={smtpPassword}
                    onChange={(e) => setSmtpPassword(e.target.value)}
                  />
                </div>
              </div>
              <Separator />
              <div className="grid grid-cols-2 gap-6">
                <div className="space-y-2">
                  <Label htmlFor="fromEmail">From Email</Label>
                  <Input
                    id="fromEmail"
                    type="email"
                    value={fromEmail}
                    onChange={(e) => setFromEmail(e.target.value)}
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="fromName">From Name</Label>
                  <Input
                    id="fromName"
                    value={fromName}
                    onChange={(e) => setFromName(e.target.value)}
                  />
                </div>
              </div>
              <Button variant="outline">
                Send Test Email
              </Button>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Danger Zone */}
        <TabsContent value="danger">
          <Card className="border-destructive/50">
            <CardHeader>
              <CardTitle className="text-destructive">Danger Zone</CardTitle>
              <CardDescription>
                Irreversible and destructive actions
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-6">
              <div className="flex items-center justify-between p-4 border rounded-lg">
                <div className="space-y-0.5">
                  <p className="font-medium">Clear Application Cache</p>
                  <p className="text-sm text-muted-foreground">
                    Remove all cached data. This may temporarily slow down the application.
                  </p>
                </div>
                <Button
                  variant="outline"
                  onClick={() => {
                    setDangerAction("clearCache");
                    setShowDangerDialog(true);
                  }}
                >
                  <Database className="w-4 h-4 mr-2" />
                  Clear Cache
                </Button>
              </div>
              <div className="flex items-center justify-between p-4 border rounded-lg">
                <div className="space-y-0.5">
                  <p className="font-medium">Reset Analytics Data</p>
                  <p className="text-sm text-muted-foreground">
                    Delete all analytics and tracking data. Cannot be undone.
                  </p>
                </div>
                <Button
                  variant="outline"
                  onClick={() => {
                    setDangerAction("resetAnalytics");
                    setShowDangerDialog(true);
                  }}
                >
                  <RefreshCw className="w-4 h-4 mr-2" />
                  Reset Analytics
                </Button>
              </div>
              <div className="flex items-center justify-between p-4 border border-destructive/50 rounded-lg">
                <div className="space-y-0.5">
                  <p className="font-medium text-destructive">Purge Inactive Users</p>
                  <p className="text-sm text-muted-foreground">
                    Delete all users who have not logged in for 6+ months. Cannot be undone.
                  </p>
                </div>
                <Button
                  variant="destructive"
                  onClick={() => {
                    setDangerAction("purgeInactive");
                    setShowDangerDialog(true);
                  }}
                >
                  <Trash2 className="w-4 h-4 mr-2" />
                  Purge Users
                </Button>
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>

      {/* Danger Confirmation Dialog */}
      <AlertDialog open={showDangerDialog} onOpenChange={setShowDangerDialog}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Are you absolutely sure?</AlertDialogTitle>
            <AlertDialogDescription>
              {dangerAction === "clearCache" && "This will clear all cached data. The application may be slower until the cache is rebuilt."}
              {dangerAction === "resetAnalytics" && "This will permanently delete all analytics data. This action cannot be undone."}
              {dangerAction === "purgeInactive" && "This will permanently delete all users who have not logged in for 6+ months. This action cannot be undone."}
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancel</AlertDialogCancel>
            <AlertDialogAction
              onClick={handleDangerAction}
              className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
            >
              Continue
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  );
}
