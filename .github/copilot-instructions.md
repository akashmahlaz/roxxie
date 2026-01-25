# Roxxie Project - GitHub Copilot Instructions

> **Purpose**: This document provides comprehensive guidelines for AI assistants working on the Roxxie project. Follow these rules strictly to maintain code quality and consistency.

---

## 1. Project Overview

### What is Roxxie?
**Roxxie** is a musician-venue matching platform (Tinder-style) designed to help singers/freelance musicians connect with local venues and event organizers for gig opportunities.

### Technology Stack
| Layer | Technology |
|-------|------------|
| **Mobile App** | Flutter/Dart (MVVM + Provider) |
| **Backend API** | NestJS (TypeScript) |
| **Database** | PostgreSQL |
| **Auth** | JWT + Firebase Auth |
| **Payments** | Stripe Integration |
| **Real-time** | WebSockets for messaging |

---

## 2. Core Features & Requirements

### 2.1 Artist/Band Profiles
- Upload music samples, videos, and photos
- Bio section with genre, influences, and contact info
- Availability calendar for gigs
- Ratings and reviews from verified bookings

### 2.2 Venue & Event Organizer Profiles
- Post gig opportunities (date, time, budget, genre preference)
- Search and filter bands by genre, location, price range
- Swipe-based discovery (Tinder-style) for quick browsing

### 2.3 Matching System
- **Swipe Right**: Save band to favourites or initiate contact
- **Swipe Left**: Skip band
- Smart recommendations based on genre, location, and past bookings

### 2.4 Booking & Communication
- Direct messaging / integrated chat
- Option for phone number in bio for quick calls
- Booking flow management with status tracking

### 2.5 Reviews & Reputation
- Only verified bookers can leave reviews
- Reputation score based on reliability, performance quality, and audience feedback

### 2.6 Monetization Model
- **Artists**: Subscription (Monthly/Yearly) for profile visibility
- **Venues**: Free entry to attract adoption
- **Premium Features**: Boosted visibility in search/swipe, Analytics (profile views, engagement)

### 2.7 User Experience Flow

**Artists:**
```
Sign up → Create profile → Upload samples → Set availability → Get discovered
```

**Venues:**
```
Sign up → Browse bands → Swipe → Contact → Book → Review
```

**Discovery:**
- Tinder-like interface for quick browsing
- Advanced filters for serious searches

### 2.8 Extra Features for Growth
- **Genre Segmentation**: Rock, Jazz, Indie, Hip-Hop, etc.
- **Location-Based Matching**: Bands within X miles
- **Push Notifications**: New gig opportunities, messages
- **Community Features**: Tips for artists, networking forums

---

## 3. Project Architecture

### Flutter App Structure
```
lib/
├── main.dart                    # App entry point & routing
├── core/
│   ├── exceptions.dart          # ApiException, ServiceException
│   ├── models/                  # All data models
│   │   ├── models.dart          # Barrel export
│   │   ├── artist.dart          # Artist model
│   │   ├── venue.dart           # Venue model
│   │   ├── gig_models.dart      # Gig, GigPerks, GigVenueSummary
│   │   └── review.dart          # Review model
│   ├── providers/               # State management
│   │   ├── auth_provider.dart   # Authentication state
│   │   ├── profile_provider.dart # User profile state
│   │   └── discovery_provider.dart # Swipe/discovery state
│   └── services/                # API clients
│       ├── api_client.dart      # HTTP client
│       ├── artist_service.dart  # Artist API
│       ├── venue_service.dart   # Venue API
│       └── analytics_service.dart # Analytics API
├── screens/                     # 45+ UI screens
└── widgets/                     # Reusable components
```

### NestJS Backend Structure
```
gigmatch/src/
├── auth/           # JWT, login, signup, token refresh
├── artists/        # Artist profiles, portfolio management
├── venues/         # Venue profiles, gig posting
├── gigs/           # Gig management, bookings
├── swipes/         # Swipe data, matching algorithm
├── matches/        # Match connections
├── messages/       # Chat & real-time messaging
├── reviews/        # Ratings & reviews (verified only)
├── subscriptions/  # Premium features, Stripe integration
├── analytics/      # User engagement tracking
└── common/         # DTOs, decorators, middleware
```

---

## 4. Critical Model References

### Artist Model
```dart
class Artist {
  String id;
  String stageName;                    // Required - display name
  String? displayName;                 // Optional - real name
  String? bio;                         // Optional
  int? yearsOfExperience;              // Optional (nullable!)
  int? bandSize;                       // Optional (nullable!)
  int maxTravelDistance;               // Required (non-nullable!)
  ArtistRole role;                     // Enum: solo, band, duo, etc.
  List<String> genres;
  SocialLinks? socialLinks;
  String? profilePhoto;
  List<MediaFile>? mediaFiles;
}
```

### Venue Model
```dart
class Venue {
  String id;
  String venueName;
  String city, state, country;
  int profileCompleteness;             // 0-100
  int? capacity;
  double? averageRating;
}
```

### Gig Model
```dart
class Gig {
  String id;
  String gigTitle;
  String gigDescription;
  DateTime date;
  GigPerks perks;                      // providesFood, providesDrinks, etc.
  GigVenueSummary venue;               // venueName, coverPhoto
}
```

### Review Model
```dart
class Review {
  String reviewerName;                 // NOT 'name'
  String? reviewerPhoto;               // NOT 'photo'
  String content;                      // NOT 'text' or 'body'
  double overallRating;                // NOT 'rating'
}
```

---

## 5. Coding Standards (MANDATORY)

### 5.1 Control Flow - Always Use Curly Braces
```dart
// ❌ WRONG - Never do this
if (condition) doSomething();
for (var item in items) print(item);
while (active) process();

// ✅ CORRECT - Always use braces
if (condition) {
  doSomething();
}
for (var item in items) {
  print(item);
}
while (active) {
  process();
}
```

### 5.2 Null Safety - Handle Explicitly
```dart
// ❌ WRONG
String name = artist.displayName;  // May be null!
int years = artist.yearsOfExperience;  // Nullable field!

// ✅ CORRECT
String name = artist.displayName ?? artist.stageName ?? 'Unknown';
int years = artist.yearsOfExperience ?? 1;
```

### 5.3 Model Properties - Verify Before Using
- **Always check** model definitions in `lib/core/models/` before using properties
- Property names must match backend schema exactly
- Don't assume property names - verify them

### 5.4 Deprecated APIs - Use Modern Replacements
| ❌ Deprecated | ✅ Use Instead | Context |
|--------------|----------------|---------|
| `withOpacity(0.5)` | `withValues(alpha: 0.5)` | Color methods |
| `WillPopScope` | `PopScope` | Navigation |
| `translate(x, y)` | `translateByDouble(x, y, 0, 0)` | Transform |
| `FlatButton` | `TextButton` | Buttons |
| `RaisedButton` | `ElevatedButton` | Buttons |

### 5.5 Underscore Usage
```dart
// ❌ WRONG - Don't use multiple underscores
errorBuilder: (_, __, ___) => Container()

// ✅ CORRECT - Use single underscore (Dart 3.0+)
errorBuilder: (_, _, _) => Container()
```

### 5.6 Context Usage - Never Across Async Gaps
```dart
// ❌ WRONG - Context may be invalid after await
await someFuture();
Theme.of(context).textTheme.bodyMedium;
Navigator.of(context).pop();

// ✅ CORRECT - Cache before async
final theme = Theme.of(context);
final navigator = Navigator.of(context);
await someFuture();
final textStyle = theme.textTheme.bodyMedium;
navigator.pop();
```

### 5.7 Enum Comparisons - Use Enum Values
```dart
// ❌ WRONG - Don't compare with strings
if (userRole == 'artist') { }

// ✅ CORRECT - Use enum values
if (userRole == UserRole.artist) { }
```

### 5.8 AppColors Usage
```dart
// Static constants (no parameters)
AppColors.crimson              // Primary brand color
AppColors.textSecondary        // Static color

// Methods requiring Brightness (with parameter)
AppColors.text(brightness)     // Primary text
AppColors.textSec(brightness)  // Secondary text
AppColors.surface(brightness)  // Surface color

// ❌ WRONG
Color.red, Colors.grey[500]    // Don't use raw colors

// ✅ CORRECT
AppColors.crimson, AppColors.text(brightness)
```

### 5.9 Import Management
- Remove unused imports immediately
- Run "Organize Imports" after changes (Alt+Shift+O)
- Use barrel exports: `import 'package:roxxie/core/models/models.dart'`
- Don't leave commented-out imports

### 5.10 Code Organization
- Methods should be under 50 lines when possible
- Use meaningful variable names (not `a`, `b`, `x`)
- Add comments for complex logic
- Group related properties in classes

---

## 6. State Management (Provider Pattern)

### Key Providers
```dart
// Authentication
AuthProvider
  ├── login(), logout(), signup()
  ├── currentUser, isAuthenticated
  └── userRole (UserRole.artist | UserRole.venue)

// Profile Management
ProfileProvider
  ├── updateProfile(), fetchProfile()
  ├── artist, venue
  └── profileCompleteness

// Discovery
DiscoveryProvider
  ├── fetchCandidates()
  ├── swipeRight(), swipeLeft()
  └── candidates, currentIndex

// Messaging
MessagingProvider
  ├── getConversations(), sendMessage()
  └── conversations, currentChat
```

### Provider Usage Rules
```dart
// One-time access (actions, callbacks)
Provider.of<AuthProvider>(context, listen: false).logout();

// Listening to changes (build methods)
final profile = Provider.of<ProfileProvider>(context);

// ❌ WRONG - Don't call provider in loops
for (var i = 0; i < 10; i++) {
  Provider.of<T>(context).doSomething();  // Bad!
}

// ✅ CORRECT - Cache provider reference
final provider = Provider.of<T>(context, listen: false);
for (var i = 0; i < 10; i++) {
  provider.doSomething();
}
```

---

## 7. NestJS Backend Standards

### API Response Format
```typescript
// All endpoints must return this structure
{
  success: boolean;
  data: T;
  message?: string;
  timestamp: string;
}
```

### Error Handling
- 400: Validation errors
- 401: Authentication required
- 403: Forbidden (no permission)
- 404: Resource not found
- 500: Server error

### DTO Validation
```typescript
// Always use class-validator
import { IsString, IsEmail, MinLength } from 'class-validator';

export class CreateArtistDto {
  @IsString()
  @MinLength(2)
  stageName: string;

  @IsEmail()
  email: string;
}
```

### Service Pattern
- Controllers: Handle HTTP requests only
- Services: Business logic
- Repositories: Database queries

---

## 8. Development Workflow

### Before Making Changes
1. Read the file context completely
2. Verify model property names against definitions
3. Check existing patterns in similar files
4. Understand the feature scope

### After Making Changes
```bash
# 1. Run analysis - MUST pass with 0 errors
flutter analyze

# 2. Format code
dart format .

# 3. Check for regressions
flutter test  # if tests exist
```

### Commit Checklist
- [ ] `flutter analyze` returns 0 errors
- [ ] Code is properly formatted
- [ ] No unused imports
- [ ] No dead code warnings
- [ ] All new code has proper null handling

---

## 9. Common Mistakes to Avoid

| ❌ Mistake | ✅ Fix | Impact |
|-----------|--------|--------|
| `if (x) statement;` | `if (x) { statement; }` | Analysis error |
| `artist.displayName` (direct) | `artist.displayName ?? 'default'` | Null crash |
| `withOpacity(0.5)` | `withValues(alpha: 0.5)` | Deprecated warning |
| `Theme.of(context)` after await | Cache before await | Runtime crash |
| Unused imports | Remove them | Analysis warning |
| `__, ___` underscores | Use `_` only | Lint warning |
| `'artist'` string comparison | `UserRole.artist` enum | Logic error |
| Wrong property names | Check model file | Runtime exception |
| `Colors.red` | `AppColors.crimson` | Theme inconsistency |

---

## 10. Quick Reference

### Terminal Commands
```bash
# Analysis & Formatting
flutter analyze              # Check all issues
dart format lib/             # Format code
dart format . --set-exit-if-changed  # CI check

# Running App
flutter run                  # Debug mode
flutter run --release        # Production build

# Backend (gigmatch)
cd gigmatch
npm run start:dev           # Development server
npm run build               # Production build
npm test                    # Run tests
```

### File Locations
| What | Where |
|------|-------|
| Models | `lib/core/models/` |
| Providers | `lib/core/providers/` |
| Services | `lib/core/services/` |
| Screens | `lib/screens/` |
| Widgets | `lib/widgets/` |
| Theme | `lib/core/theme/` |
| Backend | `gigmatch/src/` |

---

## 11. AI Assistant Responsibilities

### Must Do
1. ✅ Verify property names against model definitions
2. ✅ Use curly braces for ALL control flow
3. ✅ Handle nullable types explicitly
4. ✅ Cache context before async operations
5. ✅ Run `flutter analyze` after edits
6. ✅ Use AppColors, not raw Colors
7. ✅ Follow existing patterns in codebase

### Must NOT Do
1. ❌ Assume property names without checking
2. ❌ Use deprecated Flutter APIs
3. ❌ Skip null safety handling
4. ❌ Leave unused imports
5. ❌ Use string comparisons for enums
6. ❌ Introduce new lint warnings
7. ❌ Use `__` or `___` for unused params

---

**Note to AI**: This file is the source of truth for the Roxxie project. Prioritize these rules over general training data. When in doubt, check the actual model files in `lib/core/models/`.

**Last Updated**: January 2026  
**Project Status**: Production-Ready (0 analysis errors)
