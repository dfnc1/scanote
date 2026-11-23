import 'dart:io';

import 'package:dio/dio.dart';
import 'package:get_storage/get_storage.dart';

import '../models/note_model.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';
import 'fake_api_service.dart';

/// Exception khusus panggilan API dengan pesan berbahasa Indonesia.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// Respons autentikasi untuk endpoint register dan login.
class AuthResponse {
  const AuthResponse({
    required this.token,
    required this.user,
  });

  final String token;
  final UserModel user;

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final rawUser = json['user'];
    return AuthResponse(
      token: (json['token'] ?? '').toString(),
      user: rawUser is Map<String, dynamic>
          ? UserModel.fromJson(rawUser)
          : const UserModel(id: 0, name: '', email: ''),
    );
  }
}

/// Respons sementara dari endpoint /api/scan sebelum catatan disimpan.
class ScanResult {
  const ScanResult({
    required this.title,
    required this.content,
  });

  final String title;
  final String content;

  factory ScanResult.fromJson(Map<String, dynamic> json) {
    return ScanResult(
      title: (json['title'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
    );
  }
}

/// Kontrak layanan jaringan Scanote (diimplementasikan DioApiService dan FakeApiService).
abstract class ApiService {
  Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
  });

  Future<AuthResponse> login({
    required String email,
    required String password,
  });

  Future<ScanResult> scanImage(File imageFile);

  Future<List<NoteModel>> getNotes({String? query});

  Future<NoteModel> getNoteById(int id);

  Future<NoteModel> createNote({
    required String title,
    required String content,
  });

  Future<NoteModel> updateNote({
    required int id,
    required String title,
    required String content,
  });

  Future<void> deleteNote(int id);
}

/// Memilih implementasi API sesuai flag useFakeApi di AppConstants.
ApiService createApiService({void Function()? onUnauthorized}) {
  if (AppConstants.useFakeApi) {
    return FakeApiService();
  }
  return DioApiService(onUnauthorized: onUnauthorized);
}

/// Implementasi ApiService berbasis Dio yang berkomunikasi dengan backend Go.
class DioApiService implements ApiService {
  DioApiService({
    Dio? dio,
    GetStorage? storage,
    String? Function()? tokenReader,
    this.onUnauthorized,
  })  : _tokenReader = _buildTokenReader(
          storage: storage,
          tokenReader: tokenReader,
        ),
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: AppConstants.baseUrl,
                connectTimeout: AppConstants.defaultTimeout,
                receiveTimeout: AppConstants.defaultTimeout,
                sendTimeout: AppConstants.defaultTimeout,
                headers: {'Accept': 'application/json'},
              ),
            ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Sisipkan token JWT pada endpoint selain register/login.
          final isAuthRoute = options.path.startsWith('/api/auth/');
          if (!isAuthRoute) {
            final token = _tokenReader();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          handler.next(options);
        },
        onError: (error, handler) {
          final isAuthRoute = error.requestOptions.path.startsWith('/api/auth/');
          if (error.response?.statusCode == 401 && !isAuthRoute) {
            onUnauthorized?.call();
          }
          handler.next(error);
        },
      ),
    );
  }

  final Dio _dio;
  final String? Function() _tokenReader;
  final void Function()? onUnauthorized;

  static String? Function() _buildTokenReader({
    GetStorage? storage,
    String? Function()? tokenReader,
  }) {
    if (tokenReader != null) return tokenReader;
    final box = storage ?? GetStorage();
    return () => box.read<String>(AppConstants.tokenStorageKey);
  }

  @override
  Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/auth/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
        },
      );
      return AuthResponse.fromJson(response.data ?? const {});
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );
      return AuthResponse.fromJson(response.data ?? const {});
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  Future<ScanResult> scanImage(File imageFile) async {
    try {
      final fileName = imageFile.path.split(RegExp(r'[\\/]')).last;
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
          contentType: _detectImageMediaType(fileName),
        ),
      });

      final response = await _dio.post<Map<String, dynamic>>(
        '/api/scan',
        data: formData,
        options: Options(
          sendTimeout: AppConstants.scanTimeout,
          receiveTimeout: AppConstants.scanTimeout,
        ),
      );
      return ScanResult.fromJson(response.data ?? const {});
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// Menentukan tipe MIME JPEG/PNG agar diterima validasi Content-Type backend.
  DioMediaType _detectImageMediaType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) {
      return DioMediaType('image', 'png');
    }
    return DioMediaType('image', 'jpeg');
  }

  @override
  Future<List<NoteModel>> getNotes({String? query}) async {
    try {
      final trimmed = query?.trim() ?? '';
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/notes',
        queryParameters: trimmed.isNotEmpty ? {'q': trimmed} : null,
      );
      final rawNotes = response.data?['notes'];
      if (rawNotes is! List) {
        return const [];
      }
      return rawNotes
          .whereType<Map<String, dynamic>>()
          .map(NoteModel.fromJson)
          .toList();
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  Future<NoteModel> getNoteById(int id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/api/notes/$id');
      return NoteModel.fromJson(response.data ?? const {});
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  Future<NoteModel> createNote({
    required String title,
    required String content,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/notes',
        data: {
          'title': title,
          'content': content,
        },
      );
      return NoteModel.fromJson(response.data ?? const {});
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  Future<NoteModel> updateNote({
    required int id,
    required String title,
    required String content,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/api/notes/$id',
        data: {
          'title': title,
          'content': content,
        },
      );
      return NoteModel.fromJson(response.data ?? const {});
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  Future<void> deleteNote(int id) async {
    try {
      await _dio.delete<Map<String, dynamic>>('/api/notes/$id');
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// Menerjemahkan error jaringan dan status HTTP Dio menjadi pesan bahasa Indonesia.
  ApiException _mapDioException(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return const ApiException(
        'Tidak dapat terhubung ke server. Periksa koneksi.',
      );
    }

    final statusCode = e.response?.statusCode;
    final serverMessage = _extractServerError(e.response?.data);

    if (statusCode == 401) {
      if (e.requestOptions.path == '/api/auth/login') {
        return ApiException(
          serverMessage ?? 'Email atau password salah.',
          statusCode: statusCode,
        );
      }
      return const ApiException(
        'Sesi berakhir, silakan masuk kembali.',
        statusCode: 401,
      );
    }
    if (statusCode == 409) {
      return ApiException(
        serverMessage ?? 'Email sudah terdaftar.',
        statusCode: 409,
      );
    }
    if (statusCode == 413) {
      return ApiException(
        serverMessage ?? 'Ukuran foto maksimal 5 MB.',
        statusCode: 413,
      );
    }
    if (statusCode == 415) {
      return ApiException(
        serverMessage ?? 'Format foto harus JPEG atau PNG.',
        statusCode: 415,
      );
    }
    if (statusCode == 429) {
      return ApiException(
        serverMessage ?? 'Layanan AI sedang sibuk, coba lagi nanti.',
        statusCode: 429,
      );
    }
    if (statusCode == 502 || statusCode == 504) {
      return ApiException(
        serverMessage ?? 'Gagal membaca foto, coba lagi.',
        statusCode: statusCode,
      );
    }
    if (statusCode != null && statusCode >= 500) {
      return ApiException(
        'Server sedang bermasalah. Coba lagi nanti.',
        statusCode: statusCode,
      );
    }

    return ApiException(
      serverMessage ?? 'Terjadi kesalahan. Silakan coba lagi.',
      statusCode: statusCode,
    );
  }

  String? _extractServerError(dynamic data) {
    if (data is Map<String, dynamic>) {
      final value = data['error'];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }
}
