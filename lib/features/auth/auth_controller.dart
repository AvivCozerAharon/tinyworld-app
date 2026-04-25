import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:tinyworld_app/core/api/rest_client.dart';
import 'package:tinyworld_app/core/storage/local_storage.dart';
import 'package:tinyworld_app/features/chats/chats_controller.dart';
import 'package:tinyworld_app/features/companion/companion_controller.dart';
import 'package:tinyworld_app/features/profile/profile_controller.dart';

class AuthState {
  final bool isLoading;
  final String? error;
  final User? firebaseUser;

  const AuthState({
    this.isLoading = false,
    this.error,
    this.firebaseUser,
  });

  AuthState copyWith({bool? isLoading, String? error, User? firebaseUser}) =>
      AuthState(
        isLoading: isLoading ?? this.isLoading,
        error: error,
        firebaseUser: firebaseUser ?? this.firebaseUser,
      );
}

class AuthController extends StateNotifier<AuthState> {
  final Ref _ref;

  AuthController(this._ref) : super(const AuthState()) {
    _checkExisting();
  }

  void _invalidateUserProviders() {
    _ref.invalidate(profileControllerProvider);
    _ref.invalidate(chatsControllerProvider);
    _ref.invalidate(companionControllerProvider);
  }

  Future<void> _checkExisting() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _saveToken(user).timeout(const Duration(seconds: 5));
        state = state.copyWith(firebaseUser: user);
      }
    } catch (_) {
      await signOut();
    }
  }

  Future<void> _saveToken(User user) async {
    final token = await user.getIdToken(true);
    if (token != null) {
      await localStorage.saveIdToken(token);
    }
  }

  Future<bool> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        state = state.copyWith(isLoading: false);
        return false;
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCred =
          await FirebaseAuth.instance.signInWithCredential(credential);
      await _saveToken(userCred.user!);
      state = state.copyWith(isLoading: false, firebaseUser: userCred.user);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _friendlyError(e));
      return false;
    }
  }

  Future<bool> signInWithApple() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final rawNonce = _generateNonce();
      final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

      final appleCred = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      final oauthCred = OAuthProvider('apple.com').credential(
        idToken: appleCred.identityToken,
        rawNonce: rawNonce,
      );
      final userCred =
          await FirebaseAuth.instance.signInWithCredential(oauthCred);
      await _saveToken(userCred.user!);
      state = state.copyWith(isLoading: false, firebaseUser: userCred.user);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _friendlyError(e));
      return false;
    }
  }

  Future<bool> signInWithEmail(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final userCred = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      await _saveToken(userCred.user!);
      state = state.copyWith(isLoading: false, firebaseUser: userCred.user);
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return await _signUpWithEmail(email, password);
      }
      state = state.copyWith(isLoading: false, error: _friendlyError(e));
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _friendlyError(e));
      return false;
    }
  }

  Future<bool> _signUpWithEmail(String email, String password) async {
    try {
      final userCred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      await _saveToken(userCred.user!);
      state = state.copyWith(isLoading: false, firebaseUser: userCred.user);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _friendlyError(e));
      return false;
    }
  }

  /// Explicit registration — always creates a new account.
  Future<bool> registerWithEmail(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    return _signUpWithEmail(email, password);
  }

  /// Returns true if the user has completed onboarding (server is source of truth).
  /// Falls back to local value on error.
  Future<bool> checkOnboardingFromServer() async {
    try {
      final resp = await apiClient.get<Map<String, dynamic>>('/profile/me');
      final done = (resp.data?['onboarding_completed'] as bool?) ?? false;
      final userId = resp.data?['user_id'] as String?;
      await localStorage.setOnboardingDone(done);
      if (userId != null) await localStorage.saveUserId(userId);
      _invalidateUserProviders();
      return done;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        await localStorage.setOnboardingDone(false);
        return false;
      }
      return await localStorage.isOnboardingDone();
    } catch (_) {
      return await localStorage.isOnboardingDone();
    }
  }

  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();
    await localStorage.clearAll();
    _invalidateUserProviders();
    state = const AuthState();
  }

  String _friendlyError(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-email':
          return 'Email inválido';
        case 'wrong-password':
          return 'Senha incorreta';
        case 'email-already-in-use':
          return 'Este email já está em uso';
        case 'weak-password':
          return 'Senha muito fraca (mínimo 6 caracteres)';
        case 'user-disabled':
          return 'Conta desativada';
        case 'network-request-failed':
          return 'Sem conexão com a internet';
        default:
          return 'Erro ao fazer login. Tente novamente.';
      }
    }
    if (e is SocketException) return 'Sem conexão com a internet';
    return 'Algo deu errado. Tente novamente.';
  }

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) => AuthController(ref),
);
