import 'package:dio/dio.dart' show DioException;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../data/auth_repository.dart';
import '../domain/user_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(dio: ref.watch(dioProvider));
});

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

sealed class AuthState {
  const AuthState();
}

final class AuthLoading extends AuthState {
  const AuthLoading();
}

final class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);
  final UserModel user;
}

final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

final class AuthError extends AuthState {
  const AuthError(this.message);
  final String message;
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repo) : super(const AuthLoading()) {
    _init();
  }

  final AuthRepository _repo;

  Future<void> _init() async {
    final saved = await _repo.getSavedUser();
    state =
        saved != null ? AuthAuthenticated(saved) : const AuthUnauthenticated();
  }

  Future<void> login(String email, String password) async {
    state = const AuthLoading();
    try {
      final user = await _repo.login(email, password);
      state = AuthAuthenticated(user);
    } on DioException catch (e) {
      state = AuthError(_dioMsg(e));
    } on Exception catch (e) {
      state = AuthError(e.toString());
    }
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
    String? phone,
    String role = 'PATIENT',
  }) async {
    state = const AuthLoading();
    try {
      final user = await _repo.register(
        fullName: fullName,
        email: email,
        password: password,
        phone: phone,
        role: role,
      );
      state = AuthAuthenticated(user);
    } on DioException catch (e) {
      state = AuthError(_dioMsg(e));
    } on Exception catch (e) {
      state = AuthError(e.toString());
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthUnauthenticated();
  }

  String _dioMsg(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      return (data['message'] ?? data['error'] ?? 'Server error').toString();
    }
    return e.message ?? 'Network error — check your connection';
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});
