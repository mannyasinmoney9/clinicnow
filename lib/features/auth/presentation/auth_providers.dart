import 'package:dio/dio.dart' show DioException, DioExceptionType;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/emailjs_service.dart';
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

final class AuthRegistered extends AuthState {
  const AuthRegistered({required this.email, required this.otpCode});
  final String email;
  final String? otpCode; // non-null in dev/demo; null in production
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
      // Save credentials for auto-fill on next open
      await _repo.saveCredentials(email, password);
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
      final result = await _repo.register(
        fullName: fullName,
        email: email,
        password: password,
        phone: phone,
        role: role,
      );
      // Send real OTP email via EmailJS (non-blocking — never fails registration)
      if (result.otpCode != null) {
        EmailJsService.sendOtp(
          toEmail: email,
          toName: fullName,
          otpCode: result.otpCode!,
        );
      }
      // Navigate to OTP verification — do NOT authenticate yet
      state = AuthRegistered(email: email, otpCode: result.otpCode);
    } on DioException catch (e) {
      state = AuthError(_dioMsg(e));
    } on Exception catch (e) {
      state = AuthError(e.toString());
    }
  }

  Future<void> verifyOtp(String email, String code) async {
    state = const AuthLoading();
    try {
      final user = await _repo.verifyOtp(email, code);
      state = AuthAuthenticated(user);
    } on DioException catch (e) {
      state = AuthError(_dioMsg(e));
      throw Exception(_dioMsg(e));
    } on Exception catch (e) {
      state = AuthError(e.toString());
      rethrow;
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthUnauthenticated();
  }

  Future<void> deleteAccount() async {
    final current = state;
    if (current is AuthAuthenticated) {
      await _repo.deleteAccount(current.user.email);
    }
    state = const AuthUnauthenticated();
  }

  String _dioMsg(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      return (data['message'] ?? data['error'] ?? 'Server error').toString();
    }
    switch (e.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Server unreachable — make sure the backend is running';
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode ?? '?';
        return 'Server error ($code) — try again';
      case DioExceptionType.cancel:
        return 'Request cancelled — try again';
      default:
        final msg = (e.message ?? '').toLowerCase();
        if (msg.contains('socket') ||
            msg.contains('refused') ||
            msg.contains('failed host') ||
            msg.contains('network')) {
          return 'Server unreachable — make sure the backend is running';
        }
        return 'Network error — check your connection';
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});