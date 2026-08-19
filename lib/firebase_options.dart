// Firebase configuration generated from google-services.json

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
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

  // Firebase project configuration from google-services.json
  // Project: dryclean-flutter-app
  
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDqMZFODIhjPqAMUk0s7TWR4sS9I0hgSiQ',
    appId: '1:778802274663:web:3fa960410a2219803b8fc2',
    messagingSenderId: '778802274663',
    projectId: 'dryclean-flutter-app',
    authDomain: 'dryclean-flutter-app.firebaseapp.com',
    storageBucket: 'dryclean-flutter-app.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDqMZFODIhjPqAMUk0s7TWR4sS9I0hgSiQ',
    appId: '1:778802274663:android:7f864f6dcd1b0dbb3b8fc2',
    messagingSenderId: '778802274663',
    projectId: 'dryclean-flutter-app',
    storageBucket: 'dryclean-flutter-app.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAS75pBkqaNMgPVXJtJR4WtmbtB-0j4UJI',
    appId: '1:778802274663:ios:724b27993a41624b3b8fc2',
    messagingSenderId: '778802274663',
    projectId: 'dryclean-flutter-app',
    storageBucket: 'dryclean-flutter-app.firebasestorage.app',
    iosBundleId: 'com.drycleanplus.service.uk.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDqMZFODIhjPqAMUk0s7TWR4sS9I0hgSiQ',
    appId: '1:778802274663:ios:3fa960410a2219803b8fc2',
    messagingSenderId: '778802274663',
    projectId: 'dryclean-flutter-app',
    storageBucket: 'dryclean-flutter-app.firebasestorage.app',
    iosBundleId: 'com.example.drycleanplusApp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDqMZFODIhjPqAMUk0s7TWR4sS9I0hgSiQ',
    appId: '1:778802274663:web:3fa960410a2219803b8fc2',
    messagingSenderId: '778802274663',
    projectId: 'dryclean-flutter-app',
    authDomain: 'dryclean-flutter-app.firebaseapp.com',
    storageBucket: 'dryclean-flutter-app.firebasestorage.app',
  );
}
