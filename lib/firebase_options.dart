import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Default [FirebaseOptions] configured via dotenv environment variables.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static FirebaseOptions get web => FirebaseOptions(
        apiKey: dotenv.env['FIREBASE_WEB_API_KEY'] ?? 'AIzaSyAcMTeDv_jnQO3DG-pTEOpOuRoj2cOjpoQ',
        appId: dotenv.env['FIREBASE_WEB_APP_ID'] ?? '1:29874567137:web:0e3e3dc9daa2f369d984a0',
        messagingSenderId: dotenv.env['FIREBASE_WEB_MESSAGING_SENDER_ID'] ?? '29874567137',
        projectId: dotenv.env['FIREBASE_WEB_PROJECT_ID'] ?? 'team14-cloud',
        authDomain: dotenv.env['FIREBASE_WEB_AUTH_DOMAIN'] ?? 'team14-cloud.firebaseapp.com',
        storageBucket: dotenv.env['FIREBASE_WEB_STORAGE_BUCKET'] ?? 'team14-cloud.firebasestorage.app',
        measurementId: dotenv.env['FIREBASE_WEB_MEASUREMENT_ID'] ?? 'G-QH06DS7695',
      );

  static FirebaseOptions get android => FirebaseOptions(
        apiKey: dotenv.env['FIREBASE_ANDROID_API_KEY'] ?? 'AIzaSyDVVXbfNuA8apJhaT7DyufNbNJC00qPlP0',
        appId: dotenv.env['FIREBASE_ANDROID_APP_ID'] ?? '1:29874567137:android:b52e5525f0774bfcd984a0',
        messagingSenderId: dotenv.env['FIREBASE_ANDROID_MESSAGING_SENDER_ID'] ?? '29874567137',
        projectId: dotenv.env['FIREBASE_ANDROID_PROJECT_ID'] ?? 'team14-cloud',
        storageBucket: dotenv.env['FIREBASE_ANDROID_STORAGE_BUCKET'] ?? 'team14-cloud.firebasestorage.app',
      );
}
