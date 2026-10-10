import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:single_clik/controller/app_update_controller.dart';

class UpdateService {
  static Future<void> checkForUpdate([BuildContext? context]) async {
    if (Get.isRegistered<AppUpdateController>()) {
      await Get.find<AppUpdateController>().checkForUpdate();
    } else {
      final controller = Get.put(AppUpdateController(), permanent: true);
      await controller.checkForUpdate();
    }
  }
}