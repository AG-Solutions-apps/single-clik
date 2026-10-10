import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:single_clik/constants/show_toast.dart';
import 'package:single_clik/controller/auth_controller/mobile_number_controller.dart';
import 'package:single_clik/controller/auth_controller/otp_controller.dart';
import 'package:single_clik/screens/auth_screens/mobile_number_screen.dart';
import 'package:single_clik/services/api.dart';

import '../../constants/constant_color.dart';
import '../../constants/constant_string.dart';
import '../../constants/firebase_services.dart';
import '../../screens/auth_screens/otp_screen.dart';
import '../../screens/home_tab_bar_screen.dart';

class SignDetailsController extends GetxController {
  final isLoading = false.obs;
  final isButtonLoading = false.obs;

  final emailController = TextEditingController().obs;
  final areaController = TextEditingController().obs;
  final referredCodeController = TextEditingController().obs;

  final isVerifyingReferral = false.obs;
  final isReferralVerified = false.obs;
  final referralMessage = "".obs;
  final verifiedReferralCode = "".obs;

  Future<bool> checkReferralApi(String code) async {
    final cleanCode = code.trim();
    if (cleanCode.isEmpty) {
      referralMessage.value = "Please enter referral code";
      isReferralVerified.value = false;
      verifiedReferralCode.value = "";
      return false;
    }
    try {
      isVerifyingReferral.value = true;
      referralMessage.value = "";

      Map<String, String> headers = {
        'Accept': 'application/json',
      };

      http.Response? response;

      // Method 1: MultipartRequest POST with all parameter aliases
      try {
        final request = http.MultipartRequest('POST', Uri.parse(API.checkReferral));
        request.headers.addAll(headers);
        request.fields['referred_by_code'] = cleanCode;
        request.fields['referral_code'] = cleanCode;
        request.fields['code'] = cleanCode;

        var streamedRes = await request.send().timeout(const Duration(seconds: 10));
        var resDone = await http.Response.fromStream(streamedRes);
        debugPrint('Method 1 (Multipart POST) status: ${resDone.statusCode}, body: ${resDone.body}');
        if (resDone.statusCode == 200 && _isResponseSuccess(resDone.body)) {
          response = resDone;
        } else if (response == null) {
          response = resDone;
        }
      } catch (e) {
        debugPrint('Method 1 error: $e');
      }

      // Method 2: Standard http.post if Method 1 didn't succeed
      if (response == null || response.statusCode != 200 || !_isResponseSuccess(response.body)) {
        try {
          final postRes = await http.post(
            Uri.parse(API.checkReferral),
            headers: headers,
            body: {
              'referred_by_code': cleanCode,
              'referral_code': cleanCode,
              'code': cleanCode,
            },
          ).timeout(const Duration(seconds: 10));
          debugPrint('Method 2 (Standard POST) status: ${postRes.statusCode}, body: ${postRes.body}');
          if (postRes.statusCode == 200 && _isResponseSuccess(postRes.body)) {
            response = postRes;
          }
        } catch (e) {
          debugPrint('Method 2 error: $e');
        }
      }

      // Method 3: http.get (query parameters) if Method 1 & 2 didn't pass
      if (response == null || response.statusCode != 200 || !_isResponseSuccess(response.body)) {
        try {
          final getUri = Uri.parse(API.checkReferral).replace(queryParameters: {
            'referred_by_code': cleanCode,
            'referral_code': cleanCode,
            'code': cleanCode,
          });
          final getRes = await http.get(getUri, headers: headers).timeout(const Duration(seconds: 10));
          debugPrint('Method 3 (GET) status: ${getRes.statusCode}, body: ${getRes.body}');
          if (getRes.statusCode == 200 && _isResponseSuccess(getRes.body)) {
            response = getRes;
          }
        } catch (e) {
          debugPrint('Method 3 error: $e');
        }
      }

      if (response != null && response.statusCode == 200) {
        final bodyStr = response.body.trim();
        Map<String, dynamic> responseData = {};
        try {
          final decoded = json.decode(bodyStr);
          if (decoded is Map<String, dynamic>) {
            responseData = decoded;
          }
        } catch (_) {}

        if (_isResponseSuccess(bodyStr)) {
          isReferralVerified.value = true;
          verifiedReferralCode.value = cleanCode;

          String msgStr = "Code applied successfully!";
          final rawMsg = responseData['msg']?.toString() ??
              responseData['message']?.toString() ??
              responseData['data']?.toString();
          if (rawMsg != null && rawMsg.trim().isNotEmpty && rawMsg.toLowerCase() != 'yes') {
            msgStr = rawMsg;
          }
          referralMessage.value = msgStr;
          isVerifyingReferral.value = false;
          return true;
        } else {
          isReferralVerified.value = false;
          verifiedReferralCode.value = "";

          String msgStr = "Invalid referral code";
          final rawMsg = responseData['msg']?.toString() ??
              responseData['message']?.toString() ??
              responseData['data']?.toString();
          if (rawMsg != null && rawMsg.trim().isNotEmpty && rawMsg.toLowerCase() != 'no') {
            msgStr = rawMsg;
          }
          referralMessage.value = msgStr;
          isVerifyingReferral.value = false;
          return false;
        }
      } else {
        isReferralVerified.value = false;
        verifiedReferralCode.value = "";
        referralMessage.value = "Invalid referral code";
        isVerifyingReferral.value = false;
        return false;
      }
    } catch (e) {
      isVerifyingReferral.value = false;
      isReferralVerified.value = false;
      verifiedReferralCode.value = "";
      referralMessage.value = "Invalid referral code";
      debugPrint("Check referral error: $e");
      return false;
    }
  }

  bool _isResponseSuccess(String bodyStr) {
    final cleanBody = bodyStr.trim().toLowerCase();

    if (cleanBody == 'yes' || cleanBody == '"yes"' || cleanBody == 'true' || cleanBody == '"true"') {
      return true;
    }
    if (cleanBody == 'no' || cleanBody == '"no"' || cleanBody == 'false' || cleanBody == '"false"') {
      return false;
    }

    try {
      final decoded = json.decode(bodyStr);
      if (decoded is Map<String, dynamic>) {
        final code = decoded['code']?.toString().toLowerCase();
        final status = decoded['status']?.toString().toLowerCase();
        final success = decoded['success']?.toString().toLowerCase();
        final msg = decoded['msg']?.toString().toLowerCase();
        final message = decoded['message']?.toString().toLowerCase();
        final data = decoded['data']?.toString().toLowerCase();

        // Check for 'yes' in any field
        if (code == 'yes' || status == 'yes' || success == 'yes' || msg == 'yes' || message == 'yes' || data == 'yes') {
          return true;
        }

        // Check for 'no' in any field
        if (code == 'no' || status == 'no' || success == 'no' || msg == 'no' || message == 'no' || data == 'no') {
          return false;
        }

        if (code == '200' || status == 'true' || status == '200' || success == 'true' || decoded['status'] == true || decoded['success'] == true || decoded['code'] == 200) {
          return true;
        }

        if (code == '400' || status == 'false' || status == '400' || success == 'false' || decoded['status'] == false || decoded['success'] == false || decoded['code'] == 400) {
          return false;
        }
      } else if (decoded is String) {
        final str = decoded.trim().toLowerCase();
        if (str == 'yes' || str == 'true') return true;
        if (str == 'no' || str == 'false') return false;
      }
    } catch (_) {
      if (cleanBody.contains('"yes"') || cleanBody.contains(':yes') || cleanBody.contains(':"yes"')) {
        return true;
      }
    }
    return false;
  }

  void resetReferralStatus() {
    isReferralVerified.value = false;
    referralMessage.value = "";
    verifiedReferralCode.value = "";
  }

  final filePath = "".obs;
  Rx<CroppedFile>? croppedProfileFile = CroppedFile("").obs;

  Future<void> cropImage(XFile? pickedFile) async {
    if (pickedFile != null) {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 50,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: ConstantColor.primary,
            toolbarWidgetColor: Colors.white,
            statusBarColor: Colors.black,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Crop Image',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
            aspectRatioPickerButtonHidden: true,
          ),
        ],
      );
      if (croppedFile != null) {
        croppedProfileFile!.value = croppedFile;
      }
    }
    update();
  }

 
  Future postSignUpApi(Map<String, String> bodyParams, String photo) async {
    try {
      isButtonLoading.value = true;
      final request = http.MultipartRequest('POST', Uri.parse(API.signUp));
      request.fields.addAll(bodyParams);
      
      if (photo.isNotEmpty && !photo.startsWith("http")) {
        request.files.add(
          await http.MultipartFile.fromPath('photo', photo),
        );
      }
      
      debugPrint('bodyParams: $bodyParams');
      var res = await request.send();
      var responseDone = await http.Response.fromStream(res);
      
      if (res.statusCode == 200) {
        final responseData = json.decode(responseDone.body);
        debugPrint('SignUp Response: ${responseDone.body}');
        
        if (responseData['code'] == 200) {
          ShowToast.showToast(
            responseData['msg'] ?? ConstantString.dataSubmittedSuccessfullyMsg,
            showSuccess: true,
          );
          
          // Store the password from response
          String userPassword = responseData['data']['cpassword'].toString();
          
          // Navigate to MobileNumberScreen with necessary data
          Get.offAll(() => const MobileNumberScreen());
          
          // Get controllers
          MobileNumberController mobileNumberController = Get.find<MobileNumberController>();
          OTPController otpController = Get.find<OTPController>();
          
          // Set mobile number
          mobileNumberController.mobileNumberController.value = 
              TextEditingController(text: bodyParams['person_mobile'].toString());
          mobileNumberController.password.value = userPassword;
          
          // Auto-trigger OTP after successful signup
          await _triggerOTPVerification(
            mobileNumberController, 
            otpController, 
            bodyParams['person_mobile'].toString()
          );
          
          isButtonLoading.value = false;
        } else {
          isButtonLoading.value = false;
          ShowToast.showToast(
            responseData['msg'] ?? ConstantString.somethingWantWrongMsg,
            showSuccess: false,
          );
        }
      } else {
        isButtonLoading.value = false;
        ShowToast.showToast(ConstantString.somethingWantWrongMsg, showSuccess: false);
      }
    } catch (e) {
      isButtonLoading.value = false;
      ShowToast.showToast(e.toString(), showSuccess: false);
      debugPrint(e.toString());
    }
  }

  Future<void> _triggerOTPVerification(
    MobileNumberController mobileNumberController,
    OTPController otpController,
    String mobileNumber
  ) async {
    try {
      // Bypassing / setting appVerificationDisabledForTesting to true causes verification to fail on real devices.
      // We call verifyPhoneNumber directly to allow standard Play Integrity / reCAPTCHA fallback verification.
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: "+91$mobileNumber",
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            await FirebaseAuth.instance.signInWithCredential(credential);
            // Auto-login successful
            final fcmToken = await FirebaseService.getFcmToken();
            final response = await otpController.postLoginApi({
              "mobile": mobileNumber,
              "password": mobileNumberController.password.value,
              "device_id": fcmToken,
            });
            if (response['code'] == 200) {
              ShowToast.showToast("Login Successful!", showSuccess: true);
              Get.offAll(() => const HomeTabBarScreen());
            } else {
              ShowToast.showToast(response['msg'] ?? "Login failed", showSuccess: false);
            }
          } catch (e) {
            debugPrint('Auto verification error: $e');
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('Verification Failed: ${e.code} - ${e.message}');
          ShowToast.showToast("OTP verification failed. Please try login manually.", showSuccess: false);
        },
        codeSent: (String verificationId, int? resendToken) {
          otpController.resendToken.value = resendToken ?? 0;
          otpController.verify.value = verificationId;
          ShowToast.showToast("OTP Sent Successfully", showSuccess: true);
          Get.to(() => const OtpScreen());
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint('Auto retrieval timeout');
        },
      );
    } catch (e) {
      debugPrint('Error triggering OTP: $e');
      ShowToast.showToast("Failed to send OTP. Please try login manually.", showSuccess: false);
    }
  }
}

