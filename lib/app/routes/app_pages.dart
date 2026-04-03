import 'package:get/get.dart';
import 'app_routes.dart';
import 'auth_middleware.dart';
import '../modules/splash/splash_view.dart';
import '../modules/splash/splash_binding.dart';
import '../modules/auth/auth_view.dart';
import '../modules/auth/auth_binding.dart';
import '../modules/lobby/lobby_view.dart';
import '../modules/lobby/lobby_binding.dart';
import '../modules/room/room_view.dart';
import '../modules/room/room_binding.dart';
import '../modules/game/game_view.dart';
import '../modules/game/game_binding.dart';

class AppPages {
  static const initial = AppRoutes.splash;

  static final routes = [
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashView(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: AppRoutes.auth,
      page: () => const AuthView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.lobby,
      page: () => const LobbyView(),
      binding: LobbyBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.room,
      page: () => const RoomView(),
      binding: RoomBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.game,
      page: () => const GameView(),
      binding: GameBinding(),
      middlewares: [AuthMiddleware()],
    ),
  ];
}
