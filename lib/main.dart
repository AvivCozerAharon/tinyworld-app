import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinyworld_app/app.dart';
import 'package:tinyworld_app/core/notifications/fcm_service.dart';
import 'package:tinyworld_app/core/storage/local_storage.dart';
import 'package:tinyworld_app/shared/widgets/api_error_banner.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStorage.init();

  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyAN4Two9sN0XSiwoTxmAKP8zFPYsk36I7c",
        authDomain: "tinyworld-b872e.firebaseapp.com",
        projectId: "tinyworld-b872e",
        storageBucket: "tinyworld-b872e.firebasestorage.app",
        messagingSenderId: "896542803435",
        appId: "1:896542803435:web:0958bc211b86229390c5ae",
        measurementId: "G-3N5HN000L1",
      ),
    );
  } else {
    try {
      await Firebase.initializeApp();
    } catch (_) {}
  }

  try {
    await fcmService.init();
  } catch (_) {}

  runApp(const ProviderScope(child: ApiErrorBanner(child: TinyWorldApp())));
}
