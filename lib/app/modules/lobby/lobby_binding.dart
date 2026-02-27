import 'package:get/get.dart';
import 'lobby_controller.dart';

class LobbyBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LobbyController>(() => LobbyController());
  }
}
