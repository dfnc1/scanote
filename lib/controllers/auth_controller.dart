// GetX 4.7 masih memakai warna/snackbar dari flutter/material.dart.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../models/user_model.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import 'note_controller.dart';
import 'scan_controller.dart';

/// Abstraksi penyimpanan sesi lokal agar mudah diuji dan tetap memakai GetStorage saat produksi.
abstract class AuthStorage {
  String? readToken();
  Future<void> writeToken(String token);
  Map<String, dynamic>? readUser();
  Future<void> writeUser(Map<String, dynamic> userJson);
  Future<void> clear();
}

/// Implementasi AuthStorage menggunakan GetStorage.
class GetStorageAuthStorage implements AuthStorage {
  GetStorageAuthStorage([GetStorage? box]) : _box = box ?? GetStorage();

  final GetStorage _box;

  @override
  String? readToken() => _box.read<String>(AppConstants.tokenStorageKey);

  @override
  Future<void> writeToken(String token) =>
      _box.write(AppConstants.tokenStorageKey, token);

  @override
  Map<String, dynamic>? readUser() {
    final raw = _box.read<dynamic>(AppConstants.userStorageKey);
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return null;
  }

  @override
  Future<void> writeUser(Map<String, dynamic> userJson) =>
      _box.write(AppConstants.userStorageKey, userJson);

  @override
  Future<void> clear() async {
    await _box.remove(AppConstants.tokenStorageKey);
    await _box.remove(AppConstants.userStorageKey);
  }
}

/// Controller autentikasi GetX: mengelola login, daftar, logout, dan sesi tersimpan.
class AuthController extends GetxController {
  AuthController({
    required this.apiService,
    AuthStorage? storage,
  }) : _storage = storage ?? GetStorageAuthStorage();

  final ApiService apiService;
  final AuthStorage _storage;

  final user = Rxn<UserModel>();
  final isLoading = false.obs;
  final errorMessage = RxnString();
  bool _isLoggingOut = false;

  /// Memeriksa apakah token sesi masih tersimpan saat aplikasi dibuka.
  bool checkSession() {
    final token = _storage.readToken();
    if (token == null || token.trim().isEmpty) {
      user.value = null;
      return false;
    }
    final storedUser = _storage.readUser();
    if (storedUser != null) {
      user.value = UserModel.fromJson(storedUser);
    }
    return true;
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final response = await apiService.login(
        email: email.trim(),
        password: password,
      );
      await _persistSession(response);
      Get.offAllNamed(AppRoutes.notes);
      return true;
    } on ApiException catch (e) {
      _handleError(e.message);
      return false;
    } catch (_) {
      _handleError('Gagal masuk ke akun. Silakan coba lagi.');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final response = await apiService.register(
        name: name.trim(),
        email: email.trim(),
        password: password,
      );
      await _persistSession(response);
      Get.offAllNamed(AppRoutes.notes);
      return true;
    } on ApiException catch (e) {
      _handleError(e.message);
      return false;
    } catch (_) {
      _handleError('Gagal membuat akun. Silakan coba lagi.');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout({bool sessionExpired = false}) async {
    // Cegah pemanggilan logout ganda saat beberapa request bersamaan terkena 401.
    if (_isLoggingOut) return;
    _isLoggingOut = true;
    try {
      await _storage.clear();
      user.value = null;
      errorMessage.value = null;

      // Bersihkan state catatan dan scan agar data akun sebelumnya tidak terbawa.
      if (Get.isRegistered<NoteController>()) {
        await Get.delete<NoteController>();
      }
      if (Get.isRegistered<ScanController>()) {
        await Get.delete<ScanController>();
      }

      Get.offAllNamed(AppRoutes.login);

      if (sessionExpired) {
        _showFeedbackSnackbar(
          title: 'Sesi Berakhir',
          message: 'Sesi berakhir, silakan masuk kembali.',
          isError: true,
        );
      }
    } finally {
      _isLoggingOut = false;
    }
  }

  Future<void> _persistSession(AuthResponse response) async {
    await _storage.writeToken(response.token);
    await _storage.writeUser(response.user.toJson());
    user.value = response.user;
  }

  void _handleError(String message) {
    errorMessage.value = message;
    _showFeedbackSnackbar(
      title: 'Gagal',
      message: message,
      isError: true,
    );
  }

  void _showFeedbackSnackbar({
    required String title,
    required String message,
    required bool isError,
  }) {
    // Hindari error saat dipanggil tanpa overlay di unit test murni.
    if (Get.overlayContext == null) return;
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.surfaceInput,
      colorText: isError ? AppColors.error : AppColors.textPrimary,
      borderColor: isError ? AppColors.error : AppColors.border,
      borderWidth: 1,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    );
  }
}
