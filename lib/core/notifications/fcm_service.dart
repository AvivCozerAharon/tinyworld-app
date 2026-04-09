import 'package:firebase_messaging/firebase_messaging.dart';

class FCMService {
  Future<void> init() async {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();

    FirebaseMessaging.onMessage.listen((message) {});
  }

  Future<String?> getToken() async {
    return FirebaseMessaging.instance.getToken();
  }
}

final fcmService = FCMService();
