import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A real local account — created by anyone who signs up on-device while the
/// app runs in demo mode, no backend required. Passwords are salted+hashed,
/// never stored in plaintext.
class LocalAccount {
  const LocalAccount({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.passwordHash,
    required this.role,
    this.phone,
  });

  final int userId;
  final String fullName;
  final String email;
  final String passwordHash;
  final String role;
  final String? phone;

  factory LocalAccount.fromJson(Map<String, dynamic> j) => LocalAccount(
        userId: (j['userId'] as num).toInt(),
        fullName: j['fullName'] as String,
        email: j['email'] as String,
        passwordHash: j['passwordHash'] as String,
        role: j['role'] as String,
        phone: j['phone'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'fullName': fullName,
        'email': email,
        'passwordHash': passwordHash,
        'role': role,
        'phone': phone,
      };
}

/// On-device account book for demo mode. Backed by SharedPreferences so any
/// real person can sign up live with a real email + password and it survives
/// app restarts — no backend, no cloud.
class LocalAccountStore {
  static const _key = 'demo_local_accounts';
  static const _nextIdKey = 'demo_local_accounts_next_id';

  static String hashPassword(String email, String password) {
    final bytes = utf8.encode('${email.trim().toLowerCase()}::$password::clinicnow');
    return sha256.convert(bytes).toString();
  }

  Future<List<LocalAccount>> _loadAll(SharedPreferences prefs) {
    final raw = prefs.getStringList(_key) ?? [];
    return Future.value(raw
        .map((s) => LocalAccount.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList());
  }

  Future<void> _saveAll(SharedPreferences prefs, List<LocalAccount> accounts) async {
    await prefs.setStringList(
      _key,
      accounts.map((a) => jsonEncode(a.toJson())).toList(),
    );
  }

  /// Seeds the three demo accounts on first run only — idempotent.
  Future<void> ensureSeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await _loadAll(prefs);
    if (existing.isNotEmpty) return;

    final seeded = [
      LocalAccount(
        userId: 1,
        fullName: 'Clinic Admin',
        email: 'manniboh@gmail.com',
        passwordHash: hashPassword('manniboh@gmail.com', 'dylan/px4tm'),
        role: 'ADMIN',
      ),
      LocalAccount(
        userId: 2,
        fullName: 'Nurse Grace Adebayo',
        email: 'staff@clinicnow.demo',
        passwordHash: hashPassword('staff@clinicnow.demo', 'Password123'),
        role: 'STAFF',
      ),
      LocalAccount(
        userId: 3,
        fullName: 'Adaeze Okafor',
        email: 'patient@clinicnow.demo',
        passwordHash: hashPassword('patient@clinicnow.demo', 'Password123'),
        role: 'PATIENT',
      ),
    ];
    await _saveAll(prefs, seeded);
    await prefs.setInt(_nextIdKey, 100);
  }

  Future<LocalAccount?> findByEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final all = await _loadAll(prefs);
    final needle = email.trim().toLowerCase();
    for (final a in all) {
      if (a.email.trim().toLowerCase() == needle) return a;
    }
    return null;
  }

  /// Throws [StateError] if the email is already registered.
  Future<LocalAccount> create({
    required String fullName,
    required String email,
    required String password,
    required String role,
    String? phone,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final all = await _loadAll(prefs);
    final needle = email.trim().toLowerCase();
    if (all.any((a) => a.email.trim().toLowerCase() == needle)) {
      throw StateError('An account already exists for this email.');
    }
    final nextId = (prefs.getInt(_nextIdKey) ?? 100) + 1;
    final account = LocalAccount(
      userId: nextId,
      fullName: fullName,
      email: email.trim(),
      passwordHash: hashPassword(email, password),
      role: role,
      phone: phone,
    );
    await _saveAll(prefs, [...all, account]);
    await prefs.setInt(_nextIdKey, nextId);
    return account;
  }

  Future<void> delete(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final all = await _loadAll(prefs);
    final needle = email.trim().toLowerCase();
    all.removeWhere((a) => a.email.trim().toLowerCase() == needle);
    await _saveAll(prefs, all);
  }

  Future<LocalAccount?> verify(String email, String password) async {
    final account = await findByEmail(email);
    if (account == null) return null;
    final hash = hashPassword(email, password);
    return hash == account.passwordHash ? account : null;
  }
}