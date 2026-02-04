/// 🔥 Firebase Options for GigMatch
///
/// Generated configuration for Firebase services
/// Project: gig-match-efc1f
library;

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default Firebase options for the current platform
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running flutterfire configure',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running flutterfire configure',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running flutterfire configure',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running flutterfire configure',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  /// Firebase options for Android
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAO7q8TkZva-bHynmjWqtvI4rTRJ3cXtMc',
    appId: '1:591438057904:android:82ab0588daf162b0388675',
    messagingSenderId: '591438057904',
    projectId: 'gig-match-efc1f',
    storageBucket: 'gig-match-efc1f.firebasestorage.app',
  );

  /// Firebase options for iOS
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAO7q8TkZva-bHynmjWqtvI4rTRJ3cXtMc',
    appId: '1:591438057904:ios:1eb999dd1cff6a1c388675',
    messagingSenderId: '591438057904',
    projectId: 'gig-match-efc1f',
    storageBucket: 'gig-match-efc1f.firebasestorage.app',
    iosBundleId: 'com.example.gigmatch',
    iosClientId: '591438057904-08rfqalp8i9bi0ao8upgss0tajnh1ses.apps.googleusercontent.com',
  );
}
