import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import '../data/providers/auth_provider.dart';
import 'app_routes.dart';

class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final authProvider = Get.find<AuthProvider>();
    if (!authProvider.isAuthenticated) {
      return const RouteSettings(name: AppRoutes.auth);
    }
    return null;
  }
}
