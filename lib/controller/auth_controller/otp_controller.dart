import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:single_clik/constants/constant_string.dart';
import 'package:single_clik/constants/firebase_services.dart';
import 'package:single_clik/services/api.dart';
import 'package:single_clik/utils/shar_preferences.dart';

class OTPController extends GetxController {
  final isLoading = false.obs;
  final isButtonLoading = false.obs;

  final otp = "".obs;
  RxString verify = ''.obs;
  RxInt resendToken = 0.obs;
  late Timer _timer;
  final start = 60.obs;
  FirebaseAuth auth = FirebaseAuth.instance;

  @override
  void onInit() {
    super.onInit();
    debugPrint('=== OTPController Initialized ===');
    debugPrint('FirebaseAuth instance: ${auth.hashCode}');
    debugPrint('Initial timer value: ${start.value} seconds');
    startTimer();
  }

  @override
  void onReady() {
    super.onReady();
    debugPrint('=== OTPController Ready ===');
    debugPrint(
        'Initial verify ID: ${verify.value.isEmpty ? "Empty" : verify.value}');
    debugPrint('Initial resend token: ${resendToken.value}');
    debugPrint('Initial OTP: ${otp.value.isEmpty ? "Empty" : "***"}');
  }

  @override
  void onClose() {
    debugPrint('=== OTPController Closing ===');
    if (_timer.isActive) {
      debugPrint('Cancelling active timer');
      _timer.cancel();
    }
    debugPrint('OTPController disposed successfully');
    super.onClose();
  }

  void startTimer() {
    debugPrint('Starting OTP timer with duration: 60 seconds');
    const oneSec = Duration(seconds: 1);
    _timer = Timer.periodic(oneSec, (Timer timer) {
      if (start.value < 1) {
        debugPrint('Timer completed - stopping');
        timer.cancel();
      } else {
        start.value = start.value - 1;
        if (start.value % 10 == 0) {
          debugPrint('Timer countdown: ${start.value} seconds remaining');
        }
      }
    });
  }

  void resetTimer() {
    debugPrint('Resetting timer from ${start.value} to 60');
    if (_timer.isActive) {
      _timer.cancel();
    }
    start.value = 60;
    startTimer();
    debugPrint('Timer reset complete, new value: ${start.value}');
  }

  void setVerificationData(String verificationId, int token) {
    debugPrint('=== Setting Verification Data ===');
    debugPrint(
        'Old verificationId: ${verify.value.isEmpty ? "Empty" : verify.value}');
    debugPrint('New verificationId: $verificationId');
    debugPrint('Old resendToken: ${resendToken.value}');
    debugPrint('New resendToken: $token');

    verify.value = verificationId;
    resendToken.value = token;

    debugPrint('Verification data updated successfully');
    debugPrint('Current verificationId: ${verify.value}');
    debugPrint('Current resendToken: ${resendToken.value}');
  }

  void clearVerificationData() {
    debugPrint('Clearing verification data');
    verify.value = '';
    resendToken.value = 0;
    debugPrint('Verification data cleared');
  }

  Future<dynamic> postCheckMobileApi(Map<String, String> bodyParams) async {
    debugPrint('=== postCheckMobileApi Called ===');
    debugPrint('Request body: $bodyParams');

    try {
      isButtonLoading.value = true;
      debugPrint('isButtonLoading set to true');

      final request = http.MultipartRequest('POST', Uri.parse(API.checkMobile));
      request.fields.addAll(bodyParams);
      debugPrint('Request URL: ${API.checkMobile}');
      debugPrint('Request fields: ${request.fields}');

      debugPrint('Sending request...');
      var res = await request.send();
      var responseDone = await http.Response.fromStream(res);

      debugPrint('Response status code: ${res.statusCode}');
      debugPrint('Response body: ${responseDone.body}');

      if (res.statusCode == 200) {
        final responseData = json.decode(responseDone.body);
        debugPrint('Parsed response data: $responseData');
        debugPrint('Response code: ${responseData['code']}');
        debugPrint('Response data: ${responseData['data']}');

        isButtonLoading.value = false;
        debugPrint('isButtonLoading set to false');
        return responseData;
      } else {
        debugPrint('Request failed with status code: ${res.statusCode}');
        isButtonLoading.value = false;
        return {};
      }
    } on TimeoutException catch (e) {
      debugPrint('=== TimeoutException in postCheckMobileApi ===');
      debugPrint('Error message: ${e.message}');
      debugPrint('Stack trace: ${StackTrace.current}');
      isButtonLoading.value = false;
      return {
        'code': 182,
        'msg': e.message.toString(),
      };
    } on SocketException catch (e) {
      debugPrint('=== SocketException in postCheckMobileApi ===');
      debugPrint('Error message: ${e.message}');
      debugPrint('Stack trace: ${StackTrace.current}');
      isButtonLoading.value = false;
      return {
        'code': 182,
        'msg': e.message.toString(),
      };
    } on Error catch (e) {
      debugPrint('=== Error in postCheckMobileApi ===');
      debugPrint('Error: ${e.toString()}');
      debugPrint('Stack trace: ${StackTrace.current}');
      isButtonLoading.value = false;
      return {
        'code': 182,
        'msg': e.toString(),
      };
    } catch (e) {
      debugPrint('=== Unexpected error in postCheckMobileApi ===');
      debugPrint('Error: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      isButtonLoading.value = false;
      return {
        'code': 182,
        'msg': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> postLoginApi(
      Map<String, String> bodyParams) async {
    // Ensure valid FCM token is passed in device_id
    String deviceId = bodyParams['device_id']?.trim() ?? '';
    if (deviceId.isEmpty ||
        deviceId == 'Unknown_Device' ||
        deviceId.startsWith('Device_') ||
        deviceId.length < 20) {
      deviceId = await FirebaseService.getFcmToken();
    }
    bodyParams['device_id'] = deviceId;

    debugPrint('=== postLoginApi Called ===');
    debugPrint('Request body:');
    debugPrint('  mobile: ${bodyParams['mobile']}');
    debugPrint('  password: ${bodyParams['password']?.length ?? 0} characters');
    debugPrint('  device_id (FCM Token): ${bodyParams['device_id']}');

    try {
      isButtonLoading.value = true;
      debugPrint('isButtonLoading set to true');

      final request = http.MultipartRequest('POST', Uri.parse(API.login));
      request.headers['Accept'] = 'application/json';
      request.fields.addAll(bodyParams);
      debugPrint('Request URL: ${API.login}');
      debugPrint('Request fields count: ${request.fields.length}');
      debugPrint('Request fields: ${request.fields}');

      debugPrint('Sending login request...');
      var res = await request.send();
      var responseDone = await http.Response.fromStream(res);

      debugPrint('Login response status code: ${res.statusCode}');
      debugPrint('Login response body: ${responseDone.body}');

      final responseData = json.decode(responseDone.body);
      debugPrint('Parsed login response: $responseData');
      debugPrint('Response code: ${responseData['code']}');
      debugPrint('Response message: ${responseData['msg']}');

      isButtonLoading.value = false;
      debugPrint('isButtonLoading set to false');

      if (res.statusCode == 200 &&
          (responseData['code'] == 200 || responseData['code'] == '200')) {
        debugPrint('Login successful! Saving user data...');

        await SharPreferences.setBoolean(SharPreferences.isLogin, true);
        debugPrint('Saved isLogin = true');

        await SharPreferences.setString(
          SharPreferences.userData,
          jsonEncode(responseData['data']['user']),
        );
        debugPrint('Saved user data');

        await SharPreferences.setString(
          SharPreferences.token,
          responseData['data']['token'].toString(),
        );
        debugPrint('Saved auth token');
        await SharPreferences.setString(
          SharPreferences.userId,
          responseData['data']['user']['id'].toString(),
        );
        debugPrint('Saved user id');

        // Save the active FCM token in preferences
        if (bodyParams['device_id'] != null &&
            bodyParams['device_id']!.trim().isNotEmpty) {
          await SharPreferences.setString(
              SharPreferences.fcmToken, bodyParams['device_id']!.trim());
          debugPrint('Saved active FCM token');
        }

        debugPrint('User ID: ${responseData['data']['user']['id']}');
        debugPrint('User name: ${responseData['data']['user']['name']}');
      } else {
        debugPrint(
            'Login failed - Code: ${responseData['code']}, Message: ${responseData['msg']}');
      }

      return responseData;
    } on TimeoutException catch (e) {
      debugPrint('=== TimeoutException in postLoginApi ===');
      debugPrint('Error message: ${e.message}');
      debugPrint('Stack trace: ${StackTrace.current}');
      isButtonLoading.value = false;
      throw {'code': 408, 'msg': e.message.toString()};
    } on SocketException catch (e) {
      debugPrint('=== SocketException in postLoginApi ===');
      debugPrint('Error message: ${e.message}');
      debugPrint('Stack trace: ${StackTrace.current}');
      isButtonLoading.value = false;
      throw {'code': 503, 'msg': e.message.toString()};
    } catch (e) {
      debugPrint('=== Unexpected error in postLoginApi ===');
      debugPrint('Error: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      isButtonLoading.value = false;
      throw {'code': 500, 'msg': ConstantString.somethingWantWrongMsg};
    }
  }

  void updateLoading(bool value) {
    debugPrint('Updating OTPController isLoading to: $value');
    isLoading.value = value;
  }

  void updateButtonLoading(bool value) {
    debugPrint('Updating OTPController isButtonLoading to: $value');
    isButtonLoading.value = value;
  }

  void setOTP(String value) {
    debugPrint('Setting OTP value - Length: ${value.length}');
    otp.value = value;
  }

  void clearOTP() {
    debugPrint('Clearing OTP value');
    otp.value = '';
  }

  bool isOTPComplete() {
    bool complete = otp.value.length == 6;
    debugPrint(
        'OTP complete check: ${otp.value.length}/6 digits - Complete: $complete');
    return complete;
  }
}
