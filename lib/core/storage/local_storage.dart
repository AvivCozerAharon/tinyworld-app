import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static const _keyUserId = 'user_id';
  static const _keyOnboardingDone = 'onboarding_done';
  static const _keyFirebaseToken = 'firebase_id_token';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static bool? get onboardingDone => _prefs?.getBool(_keyOnboardingDone);

  Future<void> saveUserId(String userId) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setString(_keyUserId, userId);
  }

  Future<String?> getUserId() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    return prefs.getString(_keyUserId);
  }

  Future<void> setOnboardingDone(bool done) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingDone, done);
  }

  Future<bool> isOnboardingDone() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboardingDone) ?? false;
  }

  Future<void> saveIdToken(String token) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setString(_keyFirebaseToken, token);
  }

  Future<String?> getIdToken() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    return prefs.getString(_keyFirebaseToken);
  }

  Future<void> clearAll() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.clear();
  }
}

final localStorage = LocalStorage();
