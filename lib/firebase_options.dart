// File: lib/firebase_options.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    throw UnsupportedError(
      'DefaultFirebaseOptions are not supported for this platform.',
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC14I_Iwikmdf7eJxu53gkYARZ3nGgafhY',
    authDomain: 'flutterpbp.firebaseapp.com',
    projectId: 'flutterpbp',
    storageBucket: 'flutterpbp.firebasestorage.app',
    messagingSenderId: '171747062234',
    appId: '1:171747062234:web:3e72fb8bfa4a8023e9d0e3',
    measurementId: 'G-04KP1TE0TH',
  );
}