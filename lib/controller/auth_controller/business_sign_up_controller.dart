import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:single_clik/constants/constant_string.dart';
import 'package:single_clik/services/api.dart';

import '../../constants/constant_color.dart';
import '../../utils/shar_preferences.dart';

class BusinessSignUpController extends GetxController {
  Rx<TextEditingController> txtFullName = TextEditingController().obs;
  Rx<TextEditingController> txtCompanyName = TextEditingController().obs;
  Rx<TextEditingController> txtMobileNo = TextEditingController().obs;
  Rx<TextEditingController> txtEmailId = TextEditingController().obs;
  Rx<TextEditingController> txtWhatsappNo = TextEditingController().obs;
  Rx<TextEditingController> txtWebsite = TextEditingController().obs;
  Rx<TextEditingController> txtAbout = TextEditingController().obs;
  Rx<TextEditingController> txtArea = TextEditingController().obs;
  Rx<TextEditingController> txtReferredCode = TextEditingController().obs;
  Rx<TextEditingController> txtOtherCategory = TextEditingController().obs;
  Rx<TextEditingController> txtOtherSubCategory = TextEditingController().obs;
  
  RxList<String> profileTypeList = <String>[
    'Business',
    'Service',
    'Business/Service',
  ].obs;
  RxString selectedProfileType = "".obs;
  RxList<Map<String, dynamic>> categoryDataList = <Map<String, dynamic>>[].obs;
  RxMap<String, dynamic> selectedCategory = <String, dynamic>{}.obs;
  RxList<Map<String, dynamic>> subCategoryDataList = <Map<String, dynamic>>[].obs;
  RxMap<String, dynamic> selectedSubCategory = <String, dynamic>{}.obs;
  RxString filePath = "".obs;

  RxBool isButtonLoading = false.obs;
  Rx<CroppedFile?> croppedProfileFile = Rx<CroppedFile?>(null);
  RxBool isLoadingCategories = false.obs;
  RxBool isAccountCreated = false.obs;
  RxString createdPassword = "".obs;
  RxInt createdUserId = 0.obs;

  RxBool isVerifyingReferral = false.obs;
  RxBool isReferralVerified = false.obs;
  RxString referralMessage = "".obs;
  RxString verifiedReferralCode = "".obs;

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
      String? token = await SharPreferences.getString(SharPreferences.token);
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

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

  @override
  void onClose() {
    txtFullName.value?.dispose();
    txtCompanyName.value?.dispose();
    txtMobileNo.value?.dispose();
    txtEmailId.value?.dispose();
    txtWhatsappNo.value?.dispose();
    txtWebsite.value?.dispose();
    txtAbout.value?.dispose();
    txtArea.value?.dispose();
    txtReferredCode.value?.dispose();
    txtOtherCategory.value?.dispose();
    txtOtherSubCategory.value?.dispose();
    super.onClose();
  }

  Future<void> cropImage(XFile? pickedFile) async {
    if (pickedFile != null) {
      try {
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
          croppedProfileFile.value = croppedFile;
        }
      } catch (e) {
        debugPrint('Error cropping image: $e');
      }
    }
    update();
  }

  Future<List<Map<String, dynamic>>> getCategoryDataApi() async {
    try {
      isLoadingCategories.value = true;
      final request = http.MultipartRequest('POST', Uri.parse(API.categories));
      request.headers['Accept'] = 'application/json';
      var res = await request.send();
      var responseDone = await http.Response.fromStream(res);
      if (res.statusCode == 200) {
        final responseData = json.decode(responseDone.body);
        debugPrint('Categories response received');
        if (responseData['code'] != 200) {
          return [];
        }
        List<Map<String, dynamic>> categories = [];
        for (var item in responseData['data'] ?? []) {
          categories.add(Map<String, dynamic>.from(item));
        }
        return categories;
      } else {
        return [];
      }
    } catch (error) {
      debugPrint('Error loading categories: $error');
      return [];
    } finally {
      isLoadingCategories.value = false;
    }
  }

  Future<List<Map<String, dynamic>>> getSubCategoryDataCategoryIdWiseApi({
    required Map<String, String> parameters,
  }) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(API.subcategories));
      request.headers['Accept'] = 'application/json';
      request.fields.addAll(parameters);
      var res = await request.send();
      var responseDone = await http.Response.fromStream(res);
      if (res.statusCode == 200) {
        final responseData = json.decode(responseDone.body);
        debugPrint('Subcategories response received');
        if (responseData['code'] != 200) {
          return [];
        }
        List<Map<String, dynamic>> subCategories = [];
        for (var item in responseData['data'] ?? []) {
          subCategories.add(Map<String, dynamic>.from(item));
        }
        return subCategories;
      } else {
        return [];
      }
    } catch (error) {
      debugPrint('Error loading subcategories: $error');
      return [];
    }
  }

  String _extractErrorMessage(dynamic data, {String? defaultMsg}) {
    final fallback = defaultMsg ?? ConstantString.somethingWantWrongMsg;
    if (data is Map) {
      if (data['msg'] != null && data['msg'].toString().trim().isNotEmpty) {
        return data['msg'].toString().trim();
      }
      if (data['message'] != null && data['message'].toString().trim().isNotEmpty) {
        return data['message'].toString().trim();
      }
      if (data['error'] != null && data['error'].toString().trim().isNotEmpty) {
        return data['error'].toString().trim();
      }
      if (data['errors'] != null) {
        if (data['errors'] is Map) {
          final errMap = data['errors'] as Map;
          if (errMap.isNotEmpty) {
            final firstVal = errMap.values.first;
            if (firstVal is List && firstVal.isNotEmpty) {
              return firstVal.first.toString().trim();
            } else if (firstVal != null) {
              return firstVal.toString().trim();
            }
          }
        } else if (data['errors'] is List && (data['errors'] as List).isNotEmpty) {
          return (data['errors'] as List).first.toString().trim();
        } else {
          return data['errors'].toString().trim();
        }
      }
    } else if (data is String && data.trim().isNotEmpty) {
      return data.trim();
    }
    return fallback;
  }

  Future<Map<String, dynamic>> postBusinessSignUpApi(Map<String, String> bodyParams, String photo) async {
    isAccountCreated.value = false;
    try {
      isButtonLoading.value = true;
      final request = http.MultipartRequest('POST', Uri.parse(API.businessSignUp));
      request.headers['Accept'] = 'application/json';
      request.fields.addAll(bodyParams);
      
      if (photo.isNotEmpty && !photo.startsWith("http") && File(photo).existsSync()) {
        request.files.add(
          await http.MultipartFile.fromPath('photo', photo),
        );
      }

      var res = await request.send();
      var responseDone = await http.Response.fromStream(res);

      debugPrint('Business SignUp Status Code: ${res.statusCode}');
      debugPrint('Business SignUp Response: ${responseDone.body}');

      dynamic responseData;
      try {
        responseData = json.decode(responseDone.body);
      } catch (jsonErr) {
        debugPrint('JSON parsing error in business sign up: $jsonErr');
      }

      if (res.statusCode == 200 || res.statusCode == 201) {
        if (responseData is Map<String, dynamic>) {
          final code = responseData['code'];
          final status = responseData['status'];
          final success = responseData['success'];

          // Check if explicit failure from backend (e.g. Email already exists)
          bool isFailed = (code != null && code != 200 && code != '200') ||
              (status == false || status == 'false' || status == 0 || status == '0') ||
              (success == false || success == 'false');

          if (isFailed) {
            isAccountCreated.value = false;
            throw _extractErrorMessage(responseData);
          }

          if (code == 200 || code == '200' || status == true || status == 1 || success == true) {
            if (responseData['data'] != null && responseData['data'] is Map) {
              createdPassword.value = responseData['data']['cpassword']?.toString() ?? '';
              createdUserId.value = responseData['data']['id'] ?? 0;
            }
            isAccountCreated.value = true;
            return Map<String, dynamic>.from(responseData);
          }

          // If response contains data with user info, consider it success
          if (responseData['data'] != null && responseData['data'] is Map) {
            createdPassword.value = responseData['data']['cpassword']?.toString() ?? '';
            createdUserId.value = responseData['data']['id'] ?? 0;
            isAccountCreated.value = true;
            return Map<String, dynamic>.from(responseData);
          }

          isAccountCreated.value = false;
          throw _extractErrorMessage(responseData);
        } else {
          isAccountCreated.value = false;
          throw ConstantString.somethingWantWrongMsg;
        }
      } else {
        isAccountCreated.value = false;
        if (responseData != null) {
          throw _extractErrorMessage(responseData);
        } else {
          throw ConstantString.somethingWantWrongMsg;
        }
      }
    } on TimeoutException catch (e) {
      isAccountCreated.value = false;
      throw e.message.toString();
    } on SocketException {
      isAccountCreated.value = false;
      throw "No internet connection";
    } catch (e) {
      isAccountCreated.value = false;
      rethrow;
    } finally {
      isButtonLoading.value = false;
    }
  }

  Future<Map<String, dynamic>> postUpdateProfileApi(Map<String, String> body, String photo) async {
    try {
      isButtonLoading.value = true;
      final request = http.MultipartRequest('POST', Uri.parse(API.updateProfile));
      String? token = await SharPreferences.getString(SharPreferences.token);
      if (token != null && token.trim().isNotEmpty) {
        request.headers['Authorization'] = 'Bearer ${token.trim()}';
      }
      request.headers['Accept'] = 'application/json';
      request.fields.addAll(body);
      
      if (photo.isNotEmpty && !photo.startsWith("http") && File(photo).existsSync()) {
        request.files.add(
          await http.MultipartFile.fromPath('photo', photo),
        );
      }

      var res = await request.send();
      var responseDone = await http.Response.fromStream(res);
      
      debugPrint('Update Profile Status Code: ${res.statusCode}');
      debugPrint('Update Profile Response: ${responseDone.body}');

      dynamic responseData;
      try {
        responseData = json.decode(responseDone.body);
      } catch (jsonErr) {
        debugPrint('JSON parsing error in update profile: $jsonErr');
      }

      if (res.statusCode == 200 || res.statusCode == 201) {
        if (responseData is Map<String, dynamic>) {
          final code = responseData['code'];
          final status = responseData['status'];
          final success = responseData['success'];

          bool isFailed = (code != null && code != 200 && code != '200') ||
              (status == false || status == 'false' || status == 0 || status == '0') ||
              (success == false || success == 'false');

          if (isFailed) {
            throw _extractErrorMessage(responseData);
          }

          return Map<String, dynamic>.from(responseData);
        } else {
          throw ConstantString.somethingWantWrongMsg;
        }
      } else if (res.statusCode == 401) {
        throw "Session expired. Please login again.";
      } else {
        if (responseData != null) {
          throw _extractErrorMessage(responseData);
        }
        throw ConstantString.somethingWantWrongMsg;
      }
    } on TimeoutException catch (e) {
      throw e.message.toString();
    } on SocketException {
      throw "No internet connection";
    } catch (e) {
      rethrow;
    } finally {
      isButtonLoading.value = false;
    }
  }
  
  void clearFields() {
    txtFullName.value.clear();
    txtCompanyName.value.clear();
    txtMobileNo.value.clear();
    txtEmailId.value.clear();
    txtWhatsappNo.value.clear();
    txtWebsite.value.clear();
    txtAbout.value.clear();
    txtArea.value.clear();
    txtReferredCode.value.clear();
    txtOtherCategory.value.clear();
    txtOtherSubCategory.value.clear();
    selectedProfileType.value = "";
    selectedCategory.clear();
    selectedSubCategory.clear();
    croppedProfileFile.value = null;
    filePath.value = "";
    isAccountCreated.value = false;
    createdPassword.value = "";
    createdUserId.value = 0;
    resetReferralStatus();
  }

  // ── Business Request Tracking ─────────────────────────────────────────────

  /// Save locally that the user has submitted a business conversion request.
  /// Call this immediately after a successful form submission.
  static Future<void> markBusinessRequestSubmitted() async {
    await SharPreferences.setBoolean(
        SharPreferences.businessRequestSubmitted, true);
    debugPrint('✅ Business request marked as submitted locally.');
  }

  /// Clear the local flag — only call on logout / account deletion.
  static Future<void> clearBusinessRequestFlag() async {
    await SharPreferences.setBoolean(
        SharPreferences.businessRequestSubmitted, false);
  }

  /// Returns true if the user already has a pending business request.
  /// Priority: local flag first, then API check.
  Future<Map<String, dynamic>> checkProfileBusinessProfileApi() async {
    // 1️⃣  Local flag check (instant, no network needed)
    final localFlag =
        await SharPreferences.getBoolean(SharPreferences.businessRequestSubmitted);
    if (localFlag == true) {
      debugPrint('Local flag says request already submitted — blocking.');
      return {
        'code': 200,
        'status': true,
        'msg': 'Business account request already submitted.'
      };
    }

    // 2️⃣  API check (server-side confirmation) — route is GET only
    try {
      String? token = await SharPreferences.getString(SharPreferences.token);
      debugPrint('Check Business Profile Token: $token');

      if (token == null || token.isEmpty) {
        debugPrint('No token found — cannot check profile status');
        return {'code': 400, 'status': false, 'msg': 'Not logged in.'};
      }

      // ✅ Backend route is GET — use http.get, NOT MultipartRequest POST
      final response = await http.get(
        Uri.parse(API.checkProfileBusinessProfile),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      debugPrint('Check Business Profile Status Code: ${response.statusCode}');
      debugPrint('Check Business Profile Response: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) {
          // Normalise: 'status' may come as bool true or string "true"
          final rawStatus = decoded['status'];
          final isSubmitted =
              rawStatus == true || rawStatus.toString() == 'true';
          decoded['status'] = isSubmitted;
          debugPrint('API normalised status: $isSubmitted');

          // If API says submitted, also persist locally for future fast checks
          if (isSubmitted) {
            await SharPreferences.setBoolean(
                SharPreferences.businessRequestSubmitted, true);
          }
          return Map<String, dynamic>.from(decoded);
        }
      }
    } catch (e) {
      debugPrint('Error in check business profile: $e');
    }

    // On API failure default to false so user is not wrongly blocked
    return {'code': 400, 'status': false, 'msg': 'Failed to check status.'};
  }
}