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
    apiKey: 'AIzaSyAyVl1yxeFrJDiRyp41t3GHsHH_qlhc0kY',
    appId: '1:155124148065:web:5baed826610cfc05eb4720',
    messagingSenderId: '155124148065',
    projectId: 'umoyocard-e3b41',
    authDomain: 'umoyocard-e3b41.firebaseapp.com',
    storageBucket: 'umoyocard-e3b41.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCimshi0Z6ZyCfkGHhJE-kk3FglEtnhNdo',
    appId: '1:155124148065:android:e9c71f08dd7ac395eb4720',
    messagingSenderId: '155124148065',
    projectId: 'umoyocard-e3b41',
    storageBucket: 'umoyocard-e3b41.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCY3AAi_6ER2VezyRapva_ywUjRf1G4-Xo',
    appId: '1:155124148065:ios:eed1f18950ea827feb4720',
    messagingSenderId: '155124148065',
    projectId: 'umoyocard-e3b41',
    storageBucket: 'umoyocard-e3b41.firebasestorage.app',
    iosBundleId: 'com.example.umoyocard',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCY3AAi_6ER2VezyRapva_ywUjRf1G4-Xo',
    appId: '1:155124148065:ios:eed1f18950ea827feb4720',
    messagingSenderId: '155124148065',
    projectId: 'umoyocard-e3b41',
    storageBucket: 'umoyocard-e3b41.firebasestorage.app',
    iosBundleId: 'com.example.umoyocard',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAyVl1yxeFrJDiRyp41t3GHsHH_qlhc0kY',
    appId: '1:155124148065:web:a1d9c35bf94bd056eb4720',
    messagingSenderId: '155124148065',
    projectId: 'umoyocard-e3b41',
    authDomain: 'umoyocard-e3b41.firebaseapp.com',
    storageBucket: 'umoyocard-e3b41.firebasestorage.app',
  );
}
