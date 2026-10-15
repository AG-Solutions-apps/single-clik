import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:single_clik/constants/constant_color.dart';
import 'package:single_clik/constants/constant_string.dart';

class Dialogs {
  Dialogs._();

  static Dialogs dialogs = Dialogs._();

  void areYouSureAlertDialog({
    required BuildContext context,
    required String title,
    String? description,
    required void Function() onPressed,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          // insetPadding: EdgeInsets.symmetric(
          //   horizontal: Get.width / 20,
          // ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: ConstantColor.primaryDark,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              description == null || description.toString().trim().isEmpty
                  ? const SizedBox()
                  : Text(
                      description,
                      style: TextStyle(
                        color: ConstantColor.primary.withAlpha(204),
                        fontSize: 14,
                      ),
                    ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Get.back(),
              style: ElevatedButton.styleFrom(
                  backgroundColor: ConstantColor.whiteColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  )),
              child: Text(
                ConstantString.noLabel,
                style: TextStyle(
                  color: ConstantColor.primary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                  backgroundColor: ConstantColor.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  )),
              child: Text(
                ConstantString.yesLabel,
                style: TextStyle(
                  color: ConstantColor.whiteColor,
                ),
              ),
            ),
            SizedBox(
              width: Get.width / 90,
            ),
          ],
        );
      },
    );
  }
}
