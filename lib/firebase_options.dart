import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
        throw UnsupportedError('DefaultFirebaseOptions are not supported for this platform.');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBohmvMlgPEXiuUXwzUnhSWVQsl_E6b_rQ',
    appId: '1:618616841555:web:d16633cf69a1cc35ddada6',
    messagingSenderId: '618616841555',
    projectId: 'edu-app-1ed3b',
    authDomain: 'edu-app-1ed3b.firebaseapp.com',
    databaseURL: 'https://edu-app-1ed3b-default-rtdb.firebaseio.com',
    storageBucket: 'edu-app-1ed3b.firebasestorage.app',
    measurementId: 'G-8F24ZQYH6Q',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC--UZ0iOc296fgQ5kRgxjPdg3n_yUx8Fo',
    appId: '1:618616841555:android:073ebf4efd0ba5e4ddada6',
    messagingSenderId: '618616841555',
    projectId: 'edu-app-1ed3b',
    databaseURL: 'https://edu-app-1ed3b-default-rtdb.firebaseio.com',
    storageBucket: 'edu-app-1ed3b.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBohmvMlgPEXiuUXwzUnhSWVQsl_E6b_rQ',
    appId: '1:618616841555:web:d16633cf69a1cc35ddada6',
    messagingSenderId: '618616841555',
    projectId: 'edu-app-1ed3b',
    authDomain: 'edu-app-1ed3b.firebaseapp.com',
    databaseURL: 'https://edu-app-1ed3b-default-rtdb.firebaseio.com',
    storageBucket: 'edu-app-1ed3b.firebasestorage.app',
    iosBundleId: 'com.example.eduApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBohmvMlgPEXiuUXwzUnhSWVQsl_E6b_rQ',
    appId: '1:618616841555:web:d16633cf69a1cc35ddada6',
    messagingSenderId: '618616841555',
    projectId: 'edu-app-1ed3b',
    authDomain: 'edu-app-1ed3b.firebaseapp.com',
    databaseURL: 'https://edu-app-1ed3b-default-rtdb.firebaseio.com',
    storageBucket: 'edu-app-1ed3b.firebasestorage.app',
    iosBundleId: 'com.example.eduApp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBohmvMlgPEXiuUXwzUnhSWVQsl_E6b_rQ',
    appId: '1:618616841555:web:d16633cf69a1cc35ddada6',
    messagingSenderId: '618616841555',
    projectId: 'edu-app-1ed3b',
    authDomain: 'edu-app-1ed3b.firebaseapp.com',
    databaseURL: 'https://edu-app-1ed3b-default-rtdb.firebaseio.com',
    storageBucket: 'edu-app-1ed3b.firebasestorage.app',
    measurementId: 'G-8F24ZQYH6Q',
  );
}
