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
    apiKey: 'AIzaSyCvd-3v4PLEVVA20uVSq1uzK8AsZfe0uIs',
    appId: '1:1019698818755:web:359f97d86137298cf07c76',
    messagingSenderId: '1019698818755',
    projectId: 'tacoprime-bdb43',
    authDomain: 'tacoprime-bdb43.firebaseapp.com',
    storageBucket: 'tacoprime-bdb43.firebasestorage.app',
    measurementId: 'G-KTEHBKXKBP',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB7A6RfFvHBDEIqeDpYHm5aMnLAIImldDQ',
    appId: '1:1019698818755:android:f96582d537943c3af07c76',
    messagingSenderId: '1019698818755',
    projectId: 'tacoprime-bdb43',
    storageBucket: 'tacoprime-bdb43.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCXDTfQES96U0nAPI5z1r5X1_IuExXgrSw',
    appId: '1:1019698818755:ios:977c7e33bfa77a78f07c76',
    messagingSenderId: '1019698818755',
    projectId: 'tacoprime-bdb43',
    storageBucket: 'tacoprime-bdb43.firebasestorage.app',
    iosBundleId: 'com.example.tacoprime',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCXDTfQES96U0nAPI5z1r5X1_IuExXgrSw',
    appId: '1:1019698818755:ios:977c7e33bfa77a78f07c76',
    messagingSenderId: '1019698818755',
    projectId: 'tacoprime-bdb43',
    storageBucket: 'tacoprime-bdb43.firebasestorage.app',
    iosBundleId: 'com.example.tacoprime',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCvd-3v4PLEVVA20uVSq1uzK8AsZfe0uIs',
    appId: '1:1019698818755:web:81f72dade7598dfbf07c76',
    messagingSenderId: '1019698818755',
    projectId: 'tacoprime-bdb43',
    authDomain: 'tacoprime-bdb43.firebaseapp.com',
    storageBucket: 'tacoprime-bdb43.firebasestorage.app',
    measurementId: 'G-JVPFNXF9BT',
  );
}
