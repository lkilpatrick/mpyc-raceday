import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  const DefaultFirebaseOptions._();

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return ios;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyChUG2sugQP69V8lVt1eFkJlpkaHL0Lr4s',
    appId: '1:856196031997:web:eba232ffdb2cf0aedee594',
    messagingSenderId: '856196031997',
    projectId: 'mpyc-raceday',
    authDomain: 'mpyc-raceday.firebaseapp.com',
    storageBucket: 'mpyc-raceday.firebasestorage.app',
    measurementId: 'G-Z80TDK5XGK',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyChUG2sugQP69V8lVt1eFkJlpkaHL0Lr4s',
    appId: '1:856196031997:web:eba232ffdb2cf0aedee594',
    messagingSenderId: '856196031997',
    projectId: 'mpyc-raceday',
    storageBucket: 'mpyc-raceday.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyChUG2sugQP69V8lVt1eFkJlpkaHL0Lr4s',
    appId: '1:856196031997:web:eba232ffdb2cf0aedee594',
    messagingSenderId: '856196031997',
    projectId: 'mpyc-raceday',
    storageBucket: 'mpyc-raceday.firebasestorage.app',
    iosBundleId: 'org.example.mpycRaceday',
  );
}
