import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scanote/services/api_service.dart';
import 'package:scanote/utils/constants.dart';

typedef _MockFetchHandler = Future<ResponseBody> Function(
  RequestOptions options,
  Stream<Uint8List>? requestStream,
);

/// Adapter HTTP palsu di memori untuk menguji DioApiService tanpa jaringan nyata.
class _MockHttpClientAdapter implements HttpClientAdapter {
  _MockHttpClientAdapter(this.onFetch);

  final _MockFetchHandler onFetch;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return onFetch(options, requestStream);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _jsonResponse(Map<String, dynamic> body, int statusCode) {
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: {
      Headers.contentTypeHeader: ['application/json; charset=utf-8'],
    },
  );
}

void main() {
  group('DioApiService', () {
    test('menyisipkan Bearer token pada /api/notes dan tidak pada /api/auth/login',
        () async {
      final recordedHeaders = <String, Map<String, dynamic>>{};
      final dio = Dio(BaseOptions(baseUrl: AppConstants.baseUrl));
      dio.httpClientAdapter = _MockHttpClientAdapter((options, _) async {
        recordedHeaders[options.path] = Map<String, dynamic>.from(options.headers);
        if (options.path == '/api/auth/login') {
          return _jsonResponse({
            'token': 'jwt-123',
            'user': {'id': 1, 'name': 'Rani', 'email': 'rani@mail.com'},
          }, 200);
        }
        return _jsonResponse({
          'notes': [
            {
              'id': 1,
              'title': 'Catatan Basis Data',
              'content': 'Normalisasi 3NF',
              'created_at': '2026-11-08T10:00:00+07:00',
            },
          ],
        }, 200);
      });

      final service = DioApiService(
        dio: dio,
        tokenReader: () => 'jwt-123',
      );

      final auth = await service.login(
        email: 'rani@mail.com',
        password: 'password123',
      );
      expect(auth.token, 'jwt-123');
      expect(recordedHeaders['/api/auth/login']?['Authorization'], isNull);

      final notes = await service.getNotes(query: 'normalisasi');
      expect(notes.length, 1);
      expect(notes.first.title, 'Catatan Basis Data');
      expect(
        recordedHeaders['/api/notes']?['Authorization'],
        'Bearer jwt-123',
      );
    });

    test('scanImage mengirim multipart field image dengan MIME type JPEG dan timeout 60 detik',
        () async {
      final tempDir = await Directory.systemTemp.createTemp('scanote_test_');
      final imageFile = File('${tempDir.path}${Platform.pathSeparator}catatan.jpg');
      await imageFile.writeAsBytes([0xFF, 0xD8, 0xFF, 0xD9]);

      String? capturedBody;
      Duration? capturedSendTimeout;
      Duration? capturedReceiveTimeout;

      try {
        final dio = Dio(BaseOptions(baseUrl: AppConstants.baseUrl));
        dio.httpClientAdapter = _MockHttpClientAdapter((options, stream) async {
          capturedSendTimeout = options.sendTimeout;
          capturedReceiveTimeout = options.receiveTimeout;
          final chunks = <int>[];
          if (stream != null) {
            await for (final chunk in stream) {
              chunks.addAll(chunk);
            }
          }
          capturedBody = utf8.decode(chunks, allowMalformed: true);
          return _jsonResponse({
            'title': 'Judul Hasil Scan',
            'content': 'Isi hasil scan',
          }, 200);
        });

        final service = DioApiService(
          dio: dio,
          tokenReader: () => 'jwt-123',
        );

        final result = await service.scanImage(imageFile);
        expect(result.title, 'Judul Hasil Scan');
        expect(result.content, 'Isi hasil scan');
        expect(capturedSendTimeout, AppConstants.scanTimeout);
        expect(capturedReceiveTimeout, AppConstants.scanTimeout);
        expect(capturedBody, contains('name="image"'));
        expect(capturedBody, contains('filename="catatan.jpg"'));
        expect(capturedBody, contains('content-type: image/jpeg'));
      } finally {
        await tempDir.delete(recursive: true);
      }
    });

    test('401 pada /api/notes memicu onUnauthorized dan pesan sesi berakhir',
        () async {
      var unauthorizedCalled = false;
      final dio = Dio(BaseOptions(baseUrl: AppConstants.baseUrl));
      dio.httpClientAdapter = _MockHttpClientAdapter((options, _) async {
        return _jsonResponse({'error': 'Token tidak valid'}, 401);
      });

      final service = DioApiService(
        dio: dio,
        tokenReader: () => 'expired-token',
        onUnauthorized: () => unauthorizedCalled = true,
      );

      await expectLater(
        service.getNotes(),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 401)
              .having(
                (e) => e.message,
                'message',
                'Sesi berakhir, silakan masuk kembali.',
              ),
        ),
      );
      expect(unauthorizedCalled, isTrue);
    });

    test('401 pada /api/auth/login tidak memicu onUnauthorized dan memakai pesan login',
        () async {
      var unauthorizedCalled = false;
      final dio = Dio(BaseOptions(baseUrl: AppConstants.baseUrl));
      dio.httpClientAdapter = _MockHttpClientAdapter((options, _) async {
        return _jsonResponse(const {}, 401);
      });

      final service = DioApiService(
        dio: dio,
        tokenReader: () => null,
        onUnauthorized: () => unauthorizedCalled = true,
      );

      await expectLater(
        service.login(email: 'rani@mail.com', password: 'salahpassword'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 401)
              .having((e) => e.message, 'message', 'Email atau password salah.'),
        ),
      );
      expect(unauthorizedCalled, isFalse);
    });

    test('memetakan status 409, 413, 415, 429, 502, 503, dan timeout ke pesan Indonesia',
        () async {
      Future<void> expectStatusError(
        int statusCode,
        String expectedMessage,
      ) async {
        final dio = Dio(BaseOptions(baseUrl: AppConstants.baseUrl));
        dio.httpClientAdapter = _MockHttpClientAdapter((_, _) async {
          return _jsonResponse(const {}, statusCode);
        });
        final service = DioApiService(dio: dio, tokenReader: () => 'jwt');

        await expectLater(
          service.getNotes(),
          throwsA(
            isA<ApiException>()
                .having((e) => e.statusCode, 'statusCode', statusCode)
                .having((e) => e.message, 'message', expectedMessage),
          ),
        );
      }

      await expectStatusError(409, 'Email sudah terdaftar.');
      await expectStatusError(413, 'Ukuran foto maksimal 5 MB.');
      await expectStatusError(415, 'Format foto harus JPEG atau PNG.');
      await expectStatusError(429, 'Layanan AI sedang sibuk, coba lagi nanti.');
      await expectStatusError(502, 'Gagal membaca foto, coba lagi.');
      await expectStatusError(503, 'Server sedang bermasalah. Coba lagi nanti.');

      final timeoutDio = Dio(BaseOptions(baseUrl: AppConstants.baseUrl));
      timeoutDio.httpClientAdapter = _MockHttpClientAdapter((options, _) async {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionTimeout,
        );
      });
      final timeoutService = DioApiService(
        dio: timeoutDio,
        tokenReader: () => 'jwt',
      );
      await expectLater(
        timeoutService.getNotes(),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Tidak dapat terhubung ke server. Periksa koneksi.',
          ),
        ),
      );
    });
  });
}
