// GetX 4.7 masih memakai widget dan ThemeData dari flutter/material.dart.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'controllers/auth_controller.dart';
import 'services/api_service.dart';
import 'utils/app_theme.dart';
import 'utils/constants.dart';
import 'views/login_page.dart';
import 'views/notes_placeholder_page.dart';
import 'views/register_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();

  // Daftarkan layanan API dan controller autentikasi sebelum memeriksa sesi awal.
  final apiService = createApiService(
    onUnauthorized: () {
      if (Get.isRegistered<AuthController>()) {
        Get.find<AuthController>().logout(sessionExpired: true);
      }
    },
  );
  Get.put<ApiService>(apiService, permanent: true);

  final authController = Get.put<AuthController>(
    AuthController(apiService: apiService),
    permanent: true,
  );
  final hasSession = authController.checkSession();

  runApp(
    ScanoteApp(
      initialRoute: hasSession ? AppRoutes.notes : AppRoutes.login,
    ),
  );
}

/// Root aplikasi Scanote menggunakan GetMaterialApp dan named routes GetX.
class ScanoteApp extends StatelessWidget {
  const ScanoteApp({
    super.key,
    this.initialRoute,
    this.apiService,
    this.authStorage,
  });

  final String? initialRoute;
  final ApiService? apiService;
  final AuthStorage? authStorage;

  @override
  Widget build(BuildContext context) {
    final resolvedApi = apiService ??
        (Get.isRegistered<ApiService>()
            ? Get.find<ApiService>()
            : Get.put<ApiService>(createApiService(), permanent: true));

    final authController = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : Get.put<AuthController>(
            AuthController(
              apiService: resolvedApi,
              storage: authStorage,
            ),
            permanent: true,
          );

    final startRoute = initialRoute ??
        (authController.checkSession() ? AppRoutes.notes : AppRoutes.login);

    return GetMaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: startRoute,
      getPages: [
        GetPage(
          name: AppRoutes.login,
          page: () => const LoginPage(),
        ),
        GetPage(
          name: AppRoutes.register,
          page: () => const RegisterPage(),
        ),
        GetPage(
          name: AppRoutes.notes,
          page: () => const NotesPlaceholderPage(),
        ),
      ],
    );
  }
}
