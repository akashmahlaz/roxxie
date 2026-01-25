# Roxxie Project - AI Assistant Instructions

## Project Overview
**Roxxie** is a musician-venue matching platform (Tinder-style) built with:
- **Frontend**: Flutter/Dart mobile app
- **Backend**: NestJS REST API
- **Architecture**: MVVM (Model-View-ViewModel) with Provider state management
- **Purpose**: Help singers/freelance musicians match with local venues for gigs

### Core Features
- Artist/Band Profiles (bio, photos, videos, availability)
- Venue/Event Organizer Profiles (gig posting, budget, preferences)
- Swipe-based Discovery (Tinder-style matching)
- Direct Messaging & Chat
- Booking System
- Reviews & Reputation (verified bookings only)
- Subscription & Premium Features (analytics, boosted visibility)

---

## Dart/Flutter Code Standards

### 1. Control Flow Structures - MANDATORY
**Always use curly braces** for all if/else/for/while/switch statements, even single-line bodies:

```dart
// ❌ WRONG
if (condition) doSomething();
for (var item in items) print(item);
while (active) process();

// ✅ CORRECT
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

### 2. Model Property Names - CRITICAL
- **Always verify property names** against model definitions before using
- Check model files in `lib/core/models/` for exact field names
- Use "Find All References" to confirm correct usage patterns
- Do NOT assume property names; they must match backend schema exactly

**Common Models & Their Properties:**
```dart
Artist {
  String id, stageName, displayName (nullable), bio (nullable),
  int yearsOfExperience (nullable), bandSize (nullable), maxTravelDistance,
  List<String> genres, socialLinks, profilePhoto, mediaFiles...
}

Venue {
  String id, venueName, city, state, country,
  int profileCompleteness, capacity, averageRating...
}

Gig {
  String id, gigTitle, gigDescription, venueName, coverPhoto,
  DateTime date, GigPerks perks (provides: Food, Drinks, Transport, Accommodation),
  GigVenueSummary (venueName, coverPhoto)...
}

Review {
  String reviewerName, reviewerPhoto, content, overallRating...
}
```

### 3. Null Safety - STRICT
- Handle nullable types explicitly with proper operators
- Use `??` operator for default values on nullable fields
- Use `!` only when 100% certain value is non-null
- Always initialize fields or mark as nullable

```dart
// ❌ WRONG
String name = artist.displayName; // May be null!

// ✅ CORRECT
String name = artist.displayName ?? artist.stageName ?? 'Unknown';
int years = artist.yearsOfExperience ?? 1;
```

### 4. Deprecated APIs - Use Current Flutter Version
Replace these outdated patterns:

| Deprecated | Use Instead | Location |
|-----------|-------------|----------|
| `withOpacity(0.5)` | `withValues(alpha: 0.5)` | Color methods |
| `WillPopScope` | `PopScope` | Navigation |
| `translate(x, y)` | `translateByDouble(x, y, 0, 0)` | Transform |
| `FlatButton` | `TextButton` | Buttons |
| `RaisedButton` | `ElevatedButton` | Buttons |

### 5. Import Management
- Remove unused imports immediately after changes
- Run "Organize Imports" (Alt+Shift+O in VS Code)
- Don't leave commented-out imports
- Use barrel exports (models.dart) for organized imports

### 6. Underscore Usage
- Use **single `_`** for unused parameters: `(_, __, ___) =>` becomes `(_, _, _) =>`
- Avoid `__`, `___`, etc. (Dart 3.0+ supports `_` for all unused params)
- Use meaningful names for parameters that ARE used

### 7. Context Usage
- **Never use `.of(context)` across async gaps** (after await calls)
- Cache providers/themes before async operations:

```dart
// ❌ WRONG
await someFuture();
Theme.of(context).textTheme.bodyMedium; // Context may be invalid!

// ✅ CORRECT
final theme = Theme.of(context);
await someFuture();
final textStyle = theme.textTheme.bodyMedium;
```

### 8. Enum & Type Comparisons
- Use proper enum values, never string comparisons:

```dart
// ❌ WRONG
if (userRole == 'artist') { }

// ✅ CORRECT
if (userRole == UserRole.artist) { }
```

### 9. AppColors Usage
Two forms exist - use correctly:

```dart
// Static constants (without parameters)
AppColors.crimson          // Direct color usage
AppColors.textSecondary    // Static Color properties

// Methods requiring Brightness (with parameters)
AppColors.text(brightness)        // Primary text color
AppColors.textSec(brightness)     // Secondary text color
AppColors.surface(brightness)     // Surface color

// In widgets:
Text('Example', style: TextStyle(color: AppColors.text(brightness)))
```

### 10. Code Organization & Comments
- Methods should be under 50 lines when possible
- Use meaningful variable names (not `a`, `b`, `x`)
- Add comments for complex logic or non-obvious decisions
- Group related properties in classes

---

## NestJS Backend Standards

### 1. Module Structure
Roxxie backend has 10+ modules:
```
src/
├── auth/        # JWT, login, signup, token refresh
├── artists/     # Artist profiles, portfolio
├── venues/      # Venue profiles, gig posting
├── gigs/        # Gig management, bookings
├── swipes/      # Swipe data, matching algorithm
├── matches/     # Match connections
├── messages/    # Chat & messaging
├── reviews/     # Ratings & reviews
├── subscriptions/ # Premium features, Stripe
├── analytics/   # User engagement tracking
└── common/      # DTOs, decorators, middleware
```

### 2. API Response Format
All endpoints should follow consistent response structure:
```typescript
{
  success: boolean;
  data: T;
  message?: string;
  timestamp: string;
}
```

### 3. Error Handling
- Use HTTP status codes correctly (400 for validation, 401 for auth, 404 for not found)
- Provide clear error messages in response
- Log all errors with context

### 4. Validation
- Use class-validator decorators on DTOs
- Validate inputs before processing
- Return specific validation error messages

---

## State Management (Provider Pattern)

### Key Providers in Roxxie:
```dart
// Authentication
AuthProvider
  - login(), logout(), signup()
  - currentUser, isAuthenticated, userRole

// Profile Management
ProfileProvider
  - updateProfile(), fetchProfile()
  - artist, venue, profileCompleteness
  
// Discovery
DiscoveryProvider
  - fetchCandidates(), swipeRight(), swipeLeft()
  - candidates, currentIndex

// Messaging
MessagingProvider
  - getConversations(), sendMessage()
  - conversations, currentChat
```

### Provider Usage Rules:
- Always access via `Provider.of<T>(context, listen: false)` or `ref.read(provider)`
- Set `listen: false` for one-time access (builders, buttons)
- Use in build methods only when listening to changes
- Cache provider access outside loops

---

## Validation Checklist

### Before Committing Code:
```bash
# 1. Run analysis
flutter analyze

# 2. Format code
dart format .

# 3. Run tests (if available)
flutter test

# 4. Check for unused code
# Use VS Code "unused variable" warnings
```

### Required Exit Codes:
- ✅ `flutter analyze` = 0 errors
- ✅ `dart format` = no changes needed
- ✅ All imports organized
- ✅ No dead code warnings
- ✅ No null-safety violations

---

## Common Mistakes to Avoid

| ❌ Mistake | ✅ Fix | Impact |
|-----------|--------|--------|
| `if (x) statement;` | `if (x) { statement; }` | Analysis error |
| `artist.displayName` | `artist.displayName ?? 'default'` | Null safety error |
| `withOpacity(0.5)` | `withValues(alpha: 0.5)` | Deprecated API |
| `Theme.of(context)` after await | Cache before await | Runtime crash |
| Unused imports | Remove or use | Analysis warning |
| `__, ___` underscores | Use `_` only | Lint warning |
| `'artist'` string | `UserRole.artist` enum | Logic error |
| Wrong property names | Check model file | Runtime exception |

---

## Project-Specific Tips

### Architecture Understanding:
- This is a **marketplace app** - dual user roles (Artist/Venue)
- **Swipe mechanism** is core feature - decisions are permanent
- **Real-time messaging** critical for booking flow
- **Reputation system** based on verified bookings only

### Key Files to Know:
```
lib/
├── main.dart                    # App entry, routing
├── core/
│   ├── exceptions.dart         # ApiException
│   ├── models/                 # All model definitions
│   └── providers/              # State management
├── screens/                    # 45+ UI screens
└── widgets/                    # Reusable components
```

### Testing New Features:
1. Create model → Create provider → Create screen
2. Connect to backend API
3. Test both Artist and Venue flows
4. Verify subscription-gated features

---

## Quick Reference

### Run Commands:
```bash
# Analysis & formatting
flutter analyze                # Check all issues
dart format lib/              # Format code
dart format . --set-exit-if-changed  # Check only

# Running app
flutter run                    # Debug mode
flutter run -v                # Verbose output
flutter run --release         # Production build

# Backend (NestJS)
npm run start:dev             # Development
npm run build                 # Build
npm test                      # Run tests
```

### Git Workflow:
1. Create feature branch
2. Make changes
3. Run `flutter analyze` - must pass with 0 errors
4. Run `dart format`
5. Commit with clear message
6. Push and create PR

---

## Questions for AI Before Starting

When working on a feature, AI should:
1. ✅ Ask for clarification if requirements are ambiguous
2. ✅ Check model definitions before using properties
3. ✅ Verify which screens/providers are affected
4. ✅ Run analysis after each batch of changes
5. ✅ Format code before committing changes
6. ✅ Test both user roles (Artist & Venue) if applicable

---

## Communication Style with AI

- **Be specific**: "Fix the null error on line 156" is better than "Fix errors"
- **Provide context**: "I'm adding a new field to Artist profile" helps AI understand scope
- **Request validation**: "Run flutter analyze after this" ensures code quality
- **Ask for alternatives**: "Should we use Provider or Stream?" welcomes technical discussion

---

**Last Updated**: January 2026
**Project Status**: Production-Ready (0 analysis errors)
**Maintained By**: Roxxie Development Team
