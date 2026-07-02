import 'package:dio/dio.dart';

// EmailJS credentials — injected at build time via --dart-define
// Never hard-code these in source; see run_dev.ps1 for the flags.
const _serviceId  = String.fromEnvironment('EMAILJS_SERVICE_ID',  defaultValue: '');
const _templateId = String.fromEnvironment('EMAILJS_TEMPLATE_ID', defaultValue: '');
const _publicKey  = String.fromEnvironment('EMAILJS_PUBLIC_KEY',  defaultValue: '');

class EmailJsService {
  static final _dio = Dio(BaseOptions(
    baseUrl: 'https://api.emailjs.com',
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 8),
  ));

  /// Send an OTP email. Returns silently if EmailJS is not configured —
  /// the OTP is still visible on-screen as a demo code in that case.
  static Future<void> sendOtp({
    required String toEmail,
    required String toName,
    required String otpCode,
  }) async {
    if (_serviceId.isEmpty || _templateId.isEmpty || _publicKey.isEmpty) return;
    try {
      await _dio.post<dynamic>(
        '/api/v1.0/email/send',
        data: {
          'service_id':  _serviceId,
          'template_id': _templateId,
          'user_id':     _publicKey,
          'template_params': {
            'to_email':  toEmail,
            'to_name':   toName,
            'otp_code':  otpCode,
            'app_name':  "Mann's ClinicNow",
          },
        },
      );
    } catch (_) {
      // Never block registration if email fails — OTP still works in-app.
    }
  }
}