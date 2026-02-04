# Firebase Configuration Setup

This project uses Firebase for push notifications. You need to configure Firebase locally.

## Required Files (NOT in version control)

1. **`android/app/google-services.json`**
   - Download from: [Firebase Console](https://console.firebase.google.com) > Project Settings > Your apps > Android
   
2. **`ios/Runner/GoogleService-Info.plist`**
   - Download from: [Firebase Console](https://console.firebase.google.com) > Project Settings > Your apps > iOS

3. **`lib/firebase_options.dart`**
   - Copy `lib/firebase_options.dart.template` to `lib/firebase_options.dart`
   - Fill in the values from your Firebase project

## Backend Configuration

For the NestJS backend, create `gigmatch/firebase-service-account.json`:
- Download from: Firebase Console > Project Settings > Service Accounts > Generate new private key
- **NEVER commit this file!**

## Firebase Project Settings

- Project ID: `gig-match-efc1f`
- Android Package: `com.example.gigmatch`
- iOS Bundle ID: `com.example.gigmatch`
