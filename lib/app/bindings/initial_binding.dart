import 'package:get/get.dart';
import '../data/providers/auth_provider.dart';
import '../data/providers/room_provider.dart';
import '../data/providers/game_provider.dart';
import '../data/providers/realtime_provider.dart';
import '../modules/auth/auth_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Providers (singletons)
    Get.put(AuthProvider(), permanent: true);
    Get.put(RoomProvider(), permanent: true);
    Get.put(GameProvider(), permanent: true);
    Get.put(RealtimeProvider(), permanent: true);

    // Global controllers
    Get.put(AuthController(), permanent: true);
  }
}
