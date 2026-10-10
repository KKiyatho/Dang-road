import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';

class FirebaseServices {
  FirebaseServices._();

  static bool isConfigured = false;
  static String? configurationError;

  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      isConfigured = true;
    } on FirebaseException catch (error) {
      configurationError = error.message ?? error.code;
    } catch (error) {
      configurationError = error.toString();
    }
  }
}
