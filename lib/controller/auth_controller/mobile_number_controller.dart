import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MobileNumberController extends GetxController {
  final isLoading = false.obs;
  final isButtonLoading = false.obs;

  final mobileNumberController = TextEditingController().obs;
  RxString password = ''.obs;

  FirebaseAuth auth = FirebaseAuth.instance;

  @override
  void onInit() {
    super.onInit();
    debugPrint('=== MobileNumberController Initialized ===');
    debugPrint('FirebaseAuth instance: ${auth.hashCode}');
  }

  @override
  void onReady() {
    super.onReady();
    debugPrint('=== MobileNumberController Ready ===');
    debugPrint('Initial isLoading state: ${isLoading.value}');
    debugPrint('Initial isButtonLoading state: ${isButtonLoading.value}');
    debugPrint(
        'Initial password value: ${password.value.isEmpty ? "Empty" : "Set"}');
  }

  @override
  void onClose() {
    debugPrint('=== MobileNumberController Closing ===');
    debugPrint('Disposing TextEditingController');
    mobileNumberController.value.dispose();
    debugPrint('MobileNumberController disposed successfully');
    super.onClose();
  }

  void updateLoading(bool value) {
    debugPrint('Updating isLoading to: $value');
    isLoading.value = value;
  }

  void updateButtonLoading(bool value) {
    debugPrint('Updating isButtonLoading to: $value');
    isButtonLoading.value = value;
  }

  void setPassword(String newPassword) {
    debugPrint(
        'Setting password - Old value: ${password.value.isEmpty ? "Empty" : "***"}');
    debugPrint('Setting password - New value length: ${newPassword.length}');
    password.value = newPassword;
    debugPrint('Password updated successfully');
  }

  void clearMobileNumber() {
    debugPrint('Clearing mobile number field');
    mobileNumberController.value.clear();
    debugPrint('Mobile number cleared');
  }

  String getMobileNumber() {
    String number = mobileNumberController.value.text.trim();
    debugPrint('Getting mobile number: $number');
    return number;
  }

  bool isMobileNumberValid() {
    String number = getMobileNumber();
    bool isValid = number.isNotEmpty && number.length == 10;
    debugPrint('Mobile number validation: $number -> isValid: $isValid');
    return isValid;
  }

  String getFormattedMobileNumber() {
    String number = getMobileNumber();
    String formatted = number.isNotEmpty ? "+91$number" : "";
    debugPrint('Formatted mobile number: $formatted');
    return formatted;
  }

  void resetController() {
    debugPrint('=== Resetting MobileNumberController ===');
    updateLoading(false);
    updateButtonLoading(false);
    clearMobileNumber();
    setPassword('');
    debugPrint('Controller reset completed');
  }
}
