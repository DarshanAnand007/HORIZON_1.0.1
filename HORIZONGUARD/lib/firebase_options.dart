// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
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
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDHbkPO34Cj3ySkWai78LVntsq0mKbp8jE',
    appId: '1:375966331566:web:c33918cf852ae44da6733f',
    messagingSenderId: '375966331566',
    projectId: 'final-horizon-db9c2',
    authDomain: 'final-horizon-db9c2.firebaseapp.com',
    storageBucket: 'final-horizon-db9c2.appspot.com',
    measurementId: 'G-1T95B09329',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCZaJwZXRKwJ1QkCvK06W5TRBkIlxMzAPs',
    appId: '1:375966331566:android:45a77680438a8b3aa6733f',
    messagingSenderId: '375966331566',
    projectId: 'final-horizon-db9c2',
    storageBucket: 'final-horizon-db9c2.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDt9_UvGMiVV3U0XkgvrSWQwRUU6dHsqLQ',
    appId: '1:375966331566:ios:1c39c1ba7c063284a6733f',
    messagingSenderId: '375966331566',
    projectId: 'final-horizon-db9c2',
    storageBucket: 'final-horizon-db9c2.appspot.com',
    iosBundleId: 'com.example.tvapp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDt9_UvGMiVV3U0XkgvrSWQwRUU6dHsqLQ',
    appId: '1:375966331566:ios:1c39c1ba7c063284a6733f',
    messagingSenderId: '375966331566',
    projectId: 'final-horizon-db9c2',
    storageBucket: 'final-horizon-db9c2.appspot.com',
    iosBundleId: 'com.example.tvapp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDHbkPO34Cj3ySkWai78LVntsq0mKbp8jE',
    appId: '1:375966331566:web:bcf540afae1de146a6733f',
    messagingSenderId: '375966331566',
    projectId: 'final-horizon-db9c2',
    authDomain: 'final-horizon-db9c2.firebaseapp.com',
    storageBucket: 'final-horizon-db9c2.appspot.com',
    measurementId: 'G-FN133SGHBW',
  );
}
