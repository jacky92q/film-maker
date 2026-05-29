import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBpY1dO8uZw1z6xekb66t0kEsTdg6OazLM',
    authDomain: 'film-maker-f2466.firebaseapp.com',
    projectId: 'film-maker-f2466',
    storageBucket: 'film-maker-f2466.firebasestorage.app',
    messagingSenderId: '609658608834',
    appId: '1:609658608834:web:db2205eaa7d3b6ad34ef5b',
    measurementId: 'G-HD28W1DZMM',
  );

  // Replace appId with real value from Firebase Console → Project Settings → Android app
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBpY1dO8uZw1z6xekb66t0kEsTdg6OazLM',
    appId: '1:609658608834:android:0000000000000000',
    messagingSenderId: '609658608834',
    projectId: 'film-maker-f2466',
    storageBucket: 'film-maker-f2466.firebasestorage.app',
  );
}
