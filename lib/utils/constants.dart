/// Konstanta global aplikasi Scanote.
class AppConstants {
  AppConstants._();

  static const String appName = 'Scanote';

  /// Alamat backend Go.
  /// Emulator Android gunakan 10.0.2.2; perangkat fisik ganti dengan IP laptop.
  static const String baseUrl = 'http://10.0.2.2:8080';

  /// Gunakan FakeApiService selama backend belum tersambung.
  static const bool useFakeApi = true;

  /// Batas waktu permintaan API standar dan proses scan AI.
  static const Duration defaultTimeout = Duration(seconds: 15);
  static const Duration scanTimeout = Duration(seconds: 60);

  /// Kunci penyimpanan lokal (GetStorage) untuk sesi pengguna.
  static const String tokenStorageKey = 'auth_token';
  static const String userStorageKey = 'auth_user';
}

/// Nama rute navigasi GetX yang dipakai di seluruh aplikasi.
class AppRoutes {
  AppRoutes._();

  static const String login = '/login';
  static const String register = '/register';
  static const String notes = '/notes';
  static const String scan = '/scan';
  static const String preview = '/preview';
  static const String detail = '/detail';
}
