import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase Console의 dang-dcd02 웹 앱 설정입니다.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return const FirebaseOptions(
        apiKey: 'AIzaSyBHAvL89iJn543q-qlm14LB0jE0vwFrIm0',
        appId: '1:186331927271:web:5a51981be66ff2e6308842',
        messagingSenderId: '186331927271',
        projectId: 'dang-dcd02',
        authDomain: 'dang-dcd02.firebaseapp.com',
        storageBucket: 'dang-dcd02.firebasestorage.app',
        measurementId: 'G-52F4LKM1KV',
      );
    }

    throw UnsupportedError(
      'Firebase mobile options are not configured yet. Run flutterfire configure.',
    );
  }
}
