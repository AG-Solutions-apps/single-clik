import 'package:flutter_easyloading/flutter_easyloading.dart';

class ShowToast {
  static void showToast(String message,
      {EasyLoadingToastPosition position = EasyLoadingToastPosition.top,
      bool? showSuccess}) {
    if (showSuccess == null) {
      EasyLoading.showToast(
        message,
        toastPosition: position,
      );
    } else if (showSuccess) {
      EasyLoading.showSuccess(
        message,
      );
    } else {
      EasyLoading.showError(
        message,
      );
    }
  }
}
