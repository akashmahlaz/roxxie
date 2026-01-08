# 🎯 GigMatch Complete User Flows

## Overview
**GigMatch** is a matching platform connecting **artists/musicians** with **venues** for booking gigs.

---

## 🌐 WEB APP FLOW (Next.js)

### **1. Landing Page** (`/`)
```
User arrives at homepage
├─ See hero section with "Join as Artist" / "Join as Venue" CTAs
├─ Click "Sign Up" button
└─ Navigate to → /signup
```

### **2. Signup** (`/signup`)
```
Step 1: Choose Role
├─ Select "I'm an Artist" or "I'm a Venue"
└─ Click "Continue"

Step 2: Enter Details
├─ Full Name (or Venue Name)
├─ Email
├─ Phone (optional)
├─ Password
│   ├─ Min 8 characters ✓
│   ├─ One uppercase ✓
│   ├─ One lowercase ✓
│   ├─ One number ✓
│   └─ One special character (@$!%*?&) ✓
├─ Real-time validation shows checkmarks as requirements met
└─ Click "Create Account"

Backend Call:
POST /api/v1/auth/register
{
  "email": "user@example.com",
  "password": "SecurePass123!",
  "fullName": "John Doe",
  "role": "artist",
  "phone": "+1234567890"
}

Success Response:
{
  "accessToken": "jwt_token_here",
  "refreshToken": "refresh_token_here",
  "user": {
    "id": "user_id",
    "email": "user@example.com",
    "fullName": "John Doe",
    "role": "artist",
    "hasCompletedSetup": false,
    "isEmailVerified": false
  }
}

After Success:
├─ Tokens saved to localStorage
├─ User state saved to Zustand store
├─ Toast: "Account created! Please check email to verify"
└─ Navigate to → /onboarding
```

### **3. Onboarding** (`/onboarding`)

#### **Artist Onboarding Flow:**
```
Welcome Screen
├─ "Welcome to GigMatch!"
├─ Shows 3 benefits for artists
└─ Click "Get Started"

Step 1: Basic Info
├─ Stage Name (required)
├─ Performer Type: Solo / Duo / Band / DJ / Orchestra
└─ Click "Continue"

Step 2: Genres
├─ Select all genres you perform
├─ Multi-select: Rock, Jazz, Pop, Hip Hop, Electronic, etc.
├─ Must select at least 1
└─ Click "Continue"

Step 3: Bio
├─ Bio (required, text area)
├─ Years of Experience (number)
└─ Click "Continue"

Step 4: Photos (Optional)
├─ Shows "Photo upload coming soon"
├─ Can skip this step
└─ Click "Skip for Now"

Step 5: Complete
├─ "You're all set!" confirmation
└─ Click "Start Discovering"

Backend Call:
POST /api/v1/artists/setup
{
  "displayName": "John Doe Band",
  "bio": "Professional rock band with 10 years experience...",
  "genres": ["Rock", "Blues", "Jazz"],
  "performerType": "Band",
  "yearsExperience": 10
}

Success Actions:
├─ Fetch updated user (hasCompletedSetup: true)
├─ Update local auth state
├─ Toast: "Profile setup complete!"
└─ Navigate to → /dashboard
```

#### **Venue Onboarding Flow:**
```
Welcome Screen → Same as artist

Step 1: Basic Info
├─ Location (City, State)
├─ Capacity (number of people)
└─ Click "Continue"

Step 2: Venue Type
├─ Select: Bar / Club / Restaurant / Concert Hall / Theater / etc.
└─ Click "Continue"

Step 3: Details
├─ Description (required, text area)
└─ Click "Continue"

Step 4: Photos → Same as artist (optional)

Step 5: Complete → Same as artist

Backend Call:
POST /api/v1/venues/setup
{
  "venueName": "The Blue Note",
  "venueType": "Bar",
  "description": "Intimate jazz venue in downtown...",
  "capacity": 150
}
```

### **4. Dashboard** (`/dashboard`)
```
Protected Route (requires authentication)

Check on Load:
if (!user.hasCompletedSetup) {
  redirect → /onboarding
}

Main Dashboard
├─ Navigation: Home / Discovery / Matches / Messages / Profile
├─ Shows personalized content based on role
└─ Artist: See venues to swipe on
    Venue: See artists to swipe on
```

### **5. Profile** (`/dashboard/profile`)
```
Profile Page
├─ Check if setup complete, else redirect to onboarding
├─ Load profile data

GET /api/v1/auth/profile

Display:
├─ Cover photo (editable)
├─ Profile photo (editable)
├─ Basic info display/edit
├─ Tabs: About / Photos / Settings
└─ Edit mode toggle

Update Profile:
PATCH /api/v1/artists/{id} or /api/v1/venues/{id}
{
  "bio": "Updated bio...",
  "genres": ["Rock", "Pop"]
}
```

### **6. Login Flow** (`/login`)
```
Login Page
├─ Email input
├─ Password input
├─ "Remember me" checkbox
└─ Click "Sign In"

POST /api/v1/auth/login
{
  "email": "user@example.com",
  "password": "SecurePass123!"
}

Success:
├─ Save tokens to localStorage
├─ Save user to Zustand
├─ Check user.hasCompletedSetup
│   ├─ If false → redirect to /onboarding
│   └─ If true → redirect to /dashboard
```

### **7. Error Handling**
```
Token Expired (401):
├─ Interceptor catches 401 response
├─ Try to refresh token
│   ├─ POST /api/v1/auth/refresh
│   │   { "refreshToken": "..." }
│   ├─ If success: update tokens, retry original request
│   └─ If failure: clear tokens, redirect to /login

Network Error:
├─ Show specific error message from backend
├─ "Email already exists" → Show on form
├─ "Validation failed" → Show field-specific errors
└─ Generic error → "Something went wrong, please try again"
```

---

## 📱 MOBILE APP FLOW (Flutter)

### **1. Splash Screen**
```
App Launch
├─ Show GigMatch logo with animation
├─ Check authentication state
│   ├─ If tokens exist & valid
│   │   ├─ Load user from storage
│   │   ├─ Check hasCompletedSetup
│   │   │   ├─ If true → Navigate to /home
│   │   │   └─ If false → Navigate to profile setup
│   │   └─ Navigate to /home
│   └─ If not authenticated
│       └─ Navigate to /onboarding
```

### **2. Onboarding Screens** (`/onboarding`)
```
Swipeable carousel screens:

Screen 1: "Connect with Venues"
├─ Hero image
├─ Title & description
└─ Swipe or tap "Next"

Screen 2: "Book Gigs Easily"
├─ Features showcase
└─ Swipe or tap "Next"

Screen 3: "Build Your Reputation"
├─ Reviews & ratings info
└─ Two buttons:
    ├─ "Get Started" → Navigate to /role-selection
    └─ "Sign In" → Navigate to /login
```

### **3. Role Selection** (`/role-selection`)
```
Choose Your Role
├─ Two large cards:
│   ├─ "I'm an Artist" (with icon)
│   └─ "I'm a Venue" (with icon)
├─ Tap to select
└─ Navigate based on selection:
    ├─ Artist → /artist-signup
    └─ Venue → /venue-signup
```

### **4. Artist Signup** (`/artist-signup`)
```
Artist Registration Form
├─ Band/Artist Name (required)
├─ City (required) with GPS button →
│   ├─ Tap GPS icon
│   ├─ Request location permission
│   └─ Auto-fill city & country from GPS
├─ Country (required)
├─ Email (required)
├─ Password (required)
│   ├─ Min 8 characters ✓
│   ├─ One uppercase ✓
│   ├─ One lowercase ✓
│   ├─ One number ✓
│   └─ One special character ✓
├─ Show/hide password toggle
└─ "Sign Up & Start Booking" button

NOTE: Genre selector REMOVED (was confusing, now only in profile setup)

Backend Call:
AuthProvider.register(
  email: email,
  password: password,
  name: name,
  role: UserRole.artist,
  city: city,
  country: country,
  latitude: lat,
  longitude: lng
)

Internal:
POST /api/v1/auth/register
{
  "email": "artist@example.com",
  "password": "SecurePass123!",
  "fullName": "John Doe Band",
  "role": "artist",
  "city": "Los Angeles",
  "country": "USA",
  "location": {
    "type": "Point",
    "coordinates": [-118.2437, 34.0522]
  }
}

Success:
├─ Save tokens locally
├─ Update AuthProvider state
├─ Show success message
└─ Navigate to → /artist-setup (profile setup wizard)
```

### **5. Artist Profile Setup Wizard** (`/artist-setup`)
```
Multi-step wizard with progress indicator

Header:
├─ Step X of 5
├─ Back button (if not first step)
└─ Skip button (for optional steps)

Step 1: Basic Info
├─ Stage Name (required)
├─ Display Name (optional)
├─ Bio (text area, required)
├─ Genres (multi-select, required)
├─ Musical Influences (optional)
└─ "Next" button

Step 2: Media Upload
├─ Profile Photo (camera/gallery picker)
├─ Additional Photos (up to 6)
├─ Audio Samples (optional)
├─ Video Links (YouTube/etc, optional)
└─ "Next" button

Step 3: Contact & Location
├─ Phone number (required)
├─ Social Links:
│   ├─ Instagram
│   ├─ Spotify
│   ├─ YouTube
│   └─ Website
├─ Confirm Location (from signup)
├─ Travel Radius (slider, miles)
└─ "Next" button

Step 4: Availability & Pricing
├─ Availability calendar (tap dates)
├─ Price Range:
│   ├─ Min Price (USD)
│   ├─ Max Price (USD)
│   └─ Currency selector
└─ "Next" button

Step 5: Preview & Complete
├─ Show full profile preview
├─ Edit buttons for each section
├─ Terms & conditions checkbox
└─ "Complete Profile" button

Backend Call:
AuthProvider.completeArtistSetup(
  UpdateArtistRequest(
    stageName: stageName,
    bio: bio,
    artistType: ArtistType.solo,
    genres: genres,
    location: Location(...),
    socialLinks: SocialLinks(...),
    priceRange: PriceRange(...)
  )
)

Internal:
POST /api/v1/artists/setup + file uploads
{
  "stageName": "John Doe Band",
  "displayName": "John Doe",
  "bio": "Professional rock band...",
  "genres": ["Rock", "Blues", "Jazz"],
  "artistType": "band",
  "experienceLevel": "professional",
  "location": {
    "type": "Point",
    "coordinates": [-118.2437, 34.0522],
    "city": "Los Angeles",
    "country": "USA"
  },
  "maxTravelDistance": 50,
  "socialLinks": {
    "instagram": "@johndoeband",
    "spotify": "spotify.com/artist/...",
    "youtube": "youtube.com/...",
    "website": "johndoeband.com"
  },
  "priceRange": {
    "min": 500,
    "max": 2000,
    "currency": "USD"
  },
  "isAvailable": true
}

Success Actions:
├─ Fetch updated user from backend
│   GET /api/v1/auth/me
├─ Update AuthProvider._user (hasCompletedSetup: true)
├─ Show success dialog
└─ Navigate to → /home (main app)
```

### **6. Venue Signup & Setup**
```
Similar flow to artist but with venue-specific fields:
├─ Venue Name
├─ Venue Type (Bar, Club, Restaurant, etc.)
├─ Capacity
├─ Address
├─ Typical Event Types
├─ Budget Range for Artists
└─ Preferred Genres
```

### **7. Home Screen** (`/home`)
```
Protected - Requires completed profile

Tab Navigation:
├─ Discovery (swipe cards)
├─ Matches
├─ Messages
├─ Profile

Check on Load:
if (!user.hasCompletedSetup) {
  redirect → profile setup wizard
}

Discovery Tab:
├─ Show cards based on role:
│   ├─ Artists see venue cards
│   └─ Venues see artist cards
├─ Swipe left (pass) or right (like)
├─ Match happens when both swipe right
└─ Notification: "It's a match!"
```

### **8. Profile Screen** (`/profile`)
```
User Profile View
├─ Profile header (photo, name, role badge)
├─ Bio/Description
├─ Stats (matches, bookings, rating)
├─ Photos gallery
├─ Reviews section
├─ Edit Profile button →
    ├─ Navigate to edit screens
    └─ Update via PATCH /api/v1/artists/{id}
├─ Settings button →
    └─ App settings, logout, etc.
```

### **9. Login Flow** (`/login`)
```
Login Screen
├─ Email input
├─ Password input with show/hide toggle
├─ "Forgot Password?" link
├─ "Sign In" button
└─ "Don't have account? Sign up" link

POST /api/v1/auth/login

Success:
├─ Save tokens to secure storage
├─ Load user profile
├─ Check hasCompletedSetup
│   ├─ If false → Navigate to profile setup
│   └─ If true → Navigate to /home
```

---

## 🔐 AUTHENTICATION STATES (Both Platforms)

### **Token Management**
```
Access Token:
├─ Short-lived (15 minutes typical)
├─ Sent in Authorization header for all API requests
└─ Format: "Bearer {token}"

Refresh Token:
├─ Long-lived (7-30 days)
├─ Used to get new access token when expired
└─ Stored securely (localStorage web, FlutterSecureStorage mobile)

Token Refresh Flow:
API Request → 401 Unauthorized
├─ Interceptor catches error
├─ Check if refresh token exists
├─ POST /api/v1/auth/refresh
│   { "refreshToken": "..." }
├─ If success:
│   ├─ Save new tokens
│   ├─ Retry original request
│   └─ Continue
└─ If failure:
    ├─ Clear all tokens
    ├─ Reset auth state
    └─ Redirect to /login
```

### **User States**
```
AuthStatus Enum:
├─ initial → App just loaded
├─ loading → API call in progress  
├─ authenticated → User logged in, profile complete
├─ unauthenticated → No user logged in
├─ profileIncomplete → Logged in but setup not done
└─ error → Auth error occurred

State Transitions:
initial
  ├─ Check stored tokens
  │   ├─ Valid → authenticated or profileIncomplete
  │   └─ Invalid → unauthenticated
  └─ Loading → Check complete
```

---

## 🚨 ERROR SCENARIOS

### **Signup Errors**
```
Email Already Exists:
├─ Backend returns 409 Conflict
├─ Show: "Email already registered. Try logging in?"
└─ Offer "Go to Login" button

Weak Password:
├─ Frontend validates before sending
├─ Show specific requirement not met
└─ Highlight with red color

Network Error:
├─ Show: "Connection failed. Check your internet."
└─ "Retry" button
```

### **Profile Setup Errors**
```
Incomplete Required Fields:
├─ Validate before submission
├─ Show: "Please complete all required fields"
└─ Highlight missing fields in red

Upload Failed:
├─ Photo upload fails
├─ Save profile without photo
└─ Allow retry from profile page

Backend Validation Error:
├─ Show specific field errors
├─ Example: "Bio must be at least 50 characters"
└─ Keep form data, user fixes and retries
```

### **Session Errors**
```
Session Expired:
├─ Token refresh fails
├─ Show: "Session expired. Please log in again."
└─ Redirect to login (preserve current page for return)

Concurrent Sessions:
├─ User logs in on different device
├─ Old session invalidated
└─ Show: "Logged in from another device"
```

---

## ✅ SUCCESS STATES

### **After Successful Signup**
```
Web:
├─ Toast notification: "Account created!"
├─ Email verification reminder
└─ Auto-navigate to onboarding

Mobile:
├─ Success message dialog
├─ Auto-navigate to profile setup wizard
```

### **After Profile Completion**
```
Web:
├─ Toast: "Profile setup complete!"
├─ Confetti animation (optional)
└─ Navigate to dashboard

Mobile:
├─ Success dialog with checkmark
├─ "Go to Dashboard" button
└─ Navigate to home with smooth transition
```

---

## 📊 DATA FLOW SUMMARY

```
┌─────────────────────────────────────────────────────────┐
│                    USER JOURNEY                          │
└─────────────────────────────────────────────────────────┘
                           │
                           ▼
        ┌──────────────────────────────────┐
        │      1. SIGNUP / REGISTER        │
        │  POST /api/v1/auth/register      │
        │  Returns: tokens + user          │
        └──────────────────────────────────┘
                           │
                           ▼
        ┌──────────────────────────────────┐
        │   2. SAVE AUTH STATE             │
        │  - Save tokens to storage        │
        │  - Save user to state/store      │
        │  - hasCompletedSetup: false      │
        └──────────────────────────────────┘
                           │
                           ▼
        ┌──────────────────────────────────┐
        │  3. PROFILE SETUP WIZARD         │
        │  POST /api/v1/artists/setup      │
        │  or /api/v1/venues/setup         │
        └──────────────────────────────────┘
                           │
                           ▼
        ┌──────────────────────────────────┐
        │  4. REFRESH USER STATE           │
        │  GET /api/v1/auth/me             │
        │  hasCompletedSetup: true ✓       │
        └──────────────────────────────────┘
                           │
                           ▼
        ┌──────────────────────────────────┐
        │  5. ACCESS MAIN APP              │
        │  - Discovery / Swipe             │
        │  - Matches                       │
        │  - Messages                      │
        │  - Bookings                      │
        └──────────────────────────────────┘
```

---

## 🎯 KEY DIFFERENCES Web vs Mobile

| Feature | Web (Next.js) | Mobile (Flutter) |
|---------|--------------|------------------|
| **Signup** | Single page, 2-step form | Separate screens per field |
| **Onboarding** | Single-page stepper | Multi-step wizard with native navigation |
| **Profile Setup** | Compact, skip photos | Rich media upload (camera/gallery) |
| **Navigation** | URL-based routing | Push/pop navigation stack |
| **Token Storage** | localStorage | FlutterSecureStorage (encrypted) |
| **State Management** | Zustand (persist) | Provider (ChangeNotifier) |
| **API Client** | Axios with interceptors | Dio with interceptors |
| **Photo Upload** | File API → FormData | ImagePicker → MultipartFile |
| **Error Display** | Toast notifications | SnackBar + Dialogs |
| **Offline Support** | Limited (PWA optional) | Full offline with local DB |

---

This is your complete flow documentation! 🎉
