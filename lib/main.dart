import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinyworld_app/app.dart';
import 'package:tinyworld_app/core/notifications/fcm_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    await FirebaseAuth.instance.signInAnonymously();
  } catch (_) {}
  try {
    await fcmService.init();
  } catch (_) {}
  runApp(const ProviderScope(child: TinyWorldApp()));
}
