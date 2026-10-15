import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:single_clik/constants/constant_color.dart';
import 'package:single_clik/services/api.dart';
import 'package:single_clik/utils/shar_preferences.dart';

import 'package:single_clik/constants/show_toast.dart';
import 'package:single_clik/widget/app_image_assets.dart';

import '../../constants/constant_string.dart';
import 'home_controller.dart';

class ProfileController extends GetxController {
  final isLoading = false.obs;
  final isButtonLoading = false.obs;
  final profileMap = {}.obs;
  final nameController = TextEditingController().obs;
  final emailController = TextEditingController().obs;
  final areaController = TextEditingController().obs;
  final referredCodeController = TextEditingController().obs;
  final filePath = "".obs;
  RxString beforeImgPath = ''.obs;
  RxString aboutUsBGImgFilePath = "".obs;
  Rx<CroppedFile>? croppedProfileFile = CroppedFile("").obs;

  @override
  void onInit() {
    postFetchProfileApi();
    super.onInit();
  }

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

  Future<void> autoUploadProfilePhoto() async {
    isButtonLoading.value = true;
    try {
      HomeController homeController = Get.find<HomeController>();
      Map<String, String> bodyParams = {
        'name': (profileMap['name'] ?? homeController.userData['name'] ?? '')
            .toString()
            .trim(),
        'company_name': (profileMap['company_name'] ??
                homeController.userData['company_name'] ??
                '')
            .toString()
            .trim(),
        'email': (profileMap['email'] ?? homeController.userData['email'] ?? '')
            .toString()
            .trim(),
        'area': (areaController.value.text.isNotEmpty
                ? areaController.value.text
                : (profileMap['area'] ?? homeController.userData['area'] ?? ''))
            .toString()
            .trim(),
        'referred_by_code': (profileMap['referred_by_code'] ??
                homeController.userData['referred_by_code'] ??
                '')
            .toString()
            .trim(),
        'profile_type': (profileMap['profile_type'] ??
                homeController.userData['profile_type'] ??
                '0')
            .toString(),
        'category': (profileMap['category'] ??
                homeController.userData['category'] ??
                '0')
            .toString(),
        'sub_category': (profileMap['sub_category'] ??
                homeController.userData['sub_category'] ??
                '0')
            .toString(),
        'whatsapp': (profileMap['whatsapp'] ??
                homeController.userData['whatsapp'] ??
                '')
            .toString(),
        'website':
            (profileMap['website'] ?? homeController.userData['website'] ?? '')
                .toString(),
        'about_us': (profileMap['about_us'] ??
                homeController.userData['about_us'] ??
                '')
            .toString(),
      };

      final value = await postUpdateProfileApi(
        bodyParams,
        croppedProfileFile!.value.path.trim(),
      );

      if (value != null && value['code'] == 200) {
        await postFetchProfileApi();
        await AppImageCacheManager.clearImageCache();
        homeController.photoVersion.value++;
        await homeController.postFetchProfileApi(forceRefresh: true);
        ShowToast.showToast(
          value['msg'] ?? ConstantString.dataUpdatedSuccessfullyMsg,
          showSuccess: true,
        );
      }
    } catch (e) {
      debugPrint('Error uploading profile photo: $e');
      ShowToast.showToast('Failed to upload profile photo.',
          showSuccess: false);
    } finally {
      isButtonLoading.value = false;
    }
  }

  Future postFetchProfileApi() async {
    HomeController homeController = Get.put(HomeController());

    isLoading.value = true;
    try {
      final token = await SharPreferences.getString(SharPreferences.token);
      if (token == null || token.trim().isEmpty) {
        isLoading.value = false;
        return;
      }
      final request =
          http.MultipartRequest('POST', Uri.parse(API.fetchProfile));
      request.headers.addAll({
        'Authorization': 'Bearer ${token.trim()}',
        'Accept': 'application/json',
      });
      var res = await request.send();
      var responseDone = await http.Response.fromStream(res);

      debugPrint(await SharPreferences.getString(SharPreferences.token));

      if (res.statusCode == 200) {
        final responseData = json.decode(responseDone.body);
        log(responseData.toString());

        dynamic dataField = responseData['data'];
        Map<String, dynamic> parsedProfile = {};
        List<dynamic> parsedProducts = [];

        if (dataField is List) {
          if (dataField.isNotEmpty) {
            var firstItem = dataField[0];
            if (firstItem is Map) {
              if (firstItem.containsKey('product_name') ||
                  firstItem.containsKey('product_status')) {
                parsedProducts = dataField;
              } else {
                parsedProfile = Map<String, dynamic>.from(firstItem);
                if (firstItem.containsKey('products')) {
                  parsedProducts = List.from(firstItem['products'] ?? []);
                } else if (firstItem.containsKey('product_services')) {
                  parsedProducts =
                      List.from(firstItem['product_services'] ?? []);
                }
              }
            }
          }
        } else if (dataField is Map) {
          parsedProfile = Map<String, dynamic>.from(dataField);
          if (dataField.containsKey('products')) {
            parsedProducts = List.from(dataField['products'] ?? []);
          } else if (dataField.containsKey('product_services')) {
            parsedProducts = List.from(dataField['product_services'] ?? []);
          }
        }

        if (responseData['products'] is List) {
          parsedProducts = List.from(responseData['products']);
        } else if (responseData['product_services'] is List) {
          parsedProducts = List.from(responseData['product_services']);
        }

        // Fetch products/services from the dedicated endpoint as the primary source
        final productsList = await postFetchProductServicesApi();
        if (productsList.isNotEmpty) {
          parsedProducts = productsList;
        }

        if (responseData.containsKey('total_points'))
          parsedProfile['total_points'] = responseData['total_points'];
        if (responseData.containsKey('claim_points'))
          parsedProfile['claim_points'] = responseData['claim_points'];
        if (responseData.containsKey('history_points'))
          parsedProfile['history_points'] = responseData['history_points'];
        if (responseData.containsKey('claim_history'))
          parsedProfile['claim_history'] = responseData['claim_history'];
        if (responseData.containsKey('image_url'))
          parsedProfile['image_url'] = responseData['image_url'];

        profileMap.value = parsedProfile;
        filePath.value =
            '${ConstantString.userImgUrlPath}${profileMap['photo'] ?? ""}';
        beforeImgPath.value = filePath.value;

        final isNotBusiness = homeController.userData['user_type'] != 2;
        if (isNotBusiness) {
          areaController.value.text = (profileMap['area'] ?? '').toString();
          nameController.value.text = (profileMap['name'] ?? '').toString();
        }

        homeController.userData.value = parsedProfile;
        debugPrint('parsedProfile $parsedProfile');
        isLoading.value = false;
      } else {
        isLoading.value = false;
      }
    } catch (e) {
      isLoading.value = false;
      // ShowToast.showToast('Something went wrong.',showSuccess: false,);
      debugPrint(e.toString());
    }
  }

  Future<List<dynamic>> postFetchProductServicesApi({String? userId}) async {
    try {
      final token =
          await SharPreferences.getString(SharPreferences.token) ?? '';
      if (token.trim().isEmpty) {
        return [];
      }
      final request =
          http.MultipartRequest('POST', Uri.parse(API.fetchProductServices));
      request.headers.addAll({
        'Authorization': 'Bearer ${token.trim()}',
        'Accept': 'application/json',
      });
      if (userId == null || userId.isEmpty) {
        userId = await SharPreferences.getString(SharPreferences.userId) ?? '';
      }
      if (userId.isNotEmpty) {
        request.fields.addAll({'user_id': userId});
      }
      var res = await request.send();
      var responseDone = await http.Response.fromStream(res);
      debugPrint('Fetch Product Services Response Code: ${res.statusCode}');
      debugPrint('Fetch Product Services Response: ${responseDone.body}');
      if (res.statusCode == 200) {
        final responseData = json.decode(responseDone.body);
        if (responseData['data'] is List) {
          return responseData['data'];
        }
      }
    } catch (e) {
      debugPrint('Error in fetch product services: $e');
    }
    return [];
  }

  Future postUpdateProfileApi(Map<String, String> body, String photo) async {
    isButtonLoading.value = true;
    try {
      final token = await SharPreferences.getString(SharPreferences.token);
      if (token == null || token.trim().isEmpty) {
        isButtonLoading.value = false;
        throw 'Authentication error. Please login again.';
      }
      HomeController homeController = Get.find<HomeController>();
      final isBusiness =
          (homeController.userData['user_type'].toString() == '2');
      final apiUrl = isBusiness ? API.updateProfile : API.updateUserProfile;

      final request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      request.headers.addAll({
        'Authorization': 'Bearer ${token.trim()}',
        'Accept': 'application/json',
      });
      request.fields.addAll(body);
      (photo.isEmpty || photo.startsWith("http"))
          ? null
          : request.files.add(
              await http.MultipartFile.fromPath(
                'photo',
                photo,
              ),
            );
      var res = await request.send();
      var responseDone = await http.Response.fromStream(res);
      debugPrint('ResponseDone:,$body $responseDone');
      if (res.statusCode == 200) {
        final responseData = json.decode(responseDone.body);
        debugPrint(responseData.runtimeType.toString());
        debugPrint('Response Data: $responseData');
        if (responseData['code'] == 200) {
          debugPrint('Response: $responseData');
          return responseData;
        } else {
          throw '${responseData['msg'] ?? ConstantString.somethingWantWrongMsg}';
        }
      } else {
        debugPrint('Status: ${responseDone.statusCode} ${responseDone.body}');
        isButtonLoading.value = false;
        // ShowToast.showToast(responseData['msg'] ?? 'Something went wrong.',showSuccess: true,);
        throw ConstantString.somethingWantWrongMsg;
      }
    } on TimeoutException catch (e) {
      isButtonLoading.value = false;
      // ShowToast.showToast(e.message.toString(),showSuccess: false,);
      throw e.message.toString();
    } on SocketException catch (e) {
      isButtonLoading.value = false;
      // ShowToast.showToast(e.message.toString(),showSuccess: false,);
      throw e.message.toString();
    } on Error catch (e) {
      debugPrint('Error: $e');
      isButtonLoading.value = false;
      // ShowToast.showToast('Something went wrong.',showSuccess: false,);
      // debugPrint(e.toString());
      throw e.toString();
    }
  }

  Future postDeveloperApi() async {
    isButtonLoading.value = true;
    try {
      final token = await SharPreferences.getString(SharPreferences.token);
      if (token == null || token.trim().isEmpty) {
        isButtonLoading.value = false;
        return;
      }
      final request = http.MultipartRequest('POST', Uri.parse(API.developer));
      request.headers.addAll({
        'Authorization': 'Bearer ${token.trim()}',
        'Accept': 'application/json',
      });
      var res = await request.send();
      var responseDone = await http.Response.fromStream(res);
      if (res.statusCode == 200) {
        final responseData = json.decode(responseDone.body);
        debugPrint(responseData.runtimeType.toString());
        debugPrint('Response Data: $responseData');
        if (responseData['code'] == 200) {
          debugPrint('Success: $responseData');
          return responseData;
        } else {
          throw '${responseData['msg'] ?? ConstantString.somethingWantWrongMsg}';
        }
      } else {
        debugPrint('Response: ${responseDone.statusCode} ${responseDone.body}');
        isButtonLoading.value = false;
        // ShowToast.showToast(responseData['msg'] ?? 'Something went wrong.',showSuccess: true,);
        throw ConstantString.somethingWantWrongMsg;
      }
    } on TimeoutException catch (e) {
      isButtonLoading.value = false;
      // ShowToast.showToast(e.message.toString(),showSuccess: false,);
      throw e.message.toString();
    } on SocketException catch (e) {
      isButtonLoading.value = false;
      // ShowToast.showToast(e.message.toString(),showSuccess: false,);
      throw e.message.toString();
    } on Error catch (e) {
      debugPrint('Error: $e');
      isButtonLoading.value = false;
      // ShowToast.showToast('Something went wrong.',showSuccess: false,);
      // debugPrint(e.toString());
      throw e.toString();
    }
  }

  Future<dynamic> postCreateProductApi(
      String productName, String imagePath) async {
    isButtonLoading.value = true;
    try {
      final token = await SharPreferences.getString(SharPreferences.token);
      if (token == null || token.trim().isEmpty) {
        isButtonLoading.value = false;
        throw 'Authentication error. Please login again.';
      }
      final request =
          http.MultipartRequest('POST', Uri.parse(API.createProductServices));
      request.headers.addAll({
        'Authorization': 'Bearer ${token.trim()}',
        'Accept': 'application/json',
      });
      request.fields.addAll({
        'product_name': productName,
      });
      if (imagePath.isNotEmpty) {
        final file = File(imagePath);
        if (file.existsSync()) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'product_images',
              imagePath,
            ),
          );
        } else {
          throw 'Selected image file does not exist at $imagePath';
        }
      }
      var res = await request.send();
      var responseDone = await http.Response.fromStream(res);
      debugPrint('Create Product Response Code: ${res.statusCode}');
      debugPrint('Create Product Response: ${responseDone.body}');

      if (res.statusCode == 200 || res.statusCode == 201) {
        if (responseDone.body.trim().isEmpty) {
          return {'code': 200, 'msg': 'Product created successfully'};
        }
        try {
          final responseData = json.decode(responseDone.body);
          if (responseData is Map && responseData.containsKey('code')) {
            final code = responseData['code'];
            if (code == 200 || code == 201 || code == "200" || code == "201") {
              return responseData;
            } else {
              String errorMsg = responseData['msg'] ??
                  responseData['message'] ??
                  'Failed with code $code';
              if (errorMsg.length > 150) {
                errorMsg = '${errorMsg.substring(0, 150)}...';
              }
              throw errorMsg;
            }
          }
          return responseData;
        } catch (e) {
          if (e is String) rethrow;
          return {'code': 200, 'msg': 'Product created successfully'};
        }
      } else {
        String errorMsg = '';
        try {
          final responseData = json.decode(responseDone.body);
          errorMsg = responseData['msg'] ??
              responseData['message'] ??
              'Status ${res.statusCode}';
        } catch (_) {
          errorMsg =
              'Server error (${res.statusCode}): ${responseDone.body.isNotEmpty ? responseDone.body : "Empty Response"}';
        }
        if (errorMsg.length > 150) {
          errorMsg = '${errorMsg.substring(0, 150)}...';
        }
        throw errorMsg;
      }
    } catch (e) {
      debugPrint('Error in create product: $e');
      throw e.toString();
    } finally {
      isButtonLoading.value = false;
    }
  }

  Future<dynamic> postDeleteProductApi(String productId) async {
    isButtonLoading.value = true;
    try {
      final token = await SharPreferences.getString(SharPreferences.token);
      if (token == null || token.trim().isEmpty) {
        isButtonLoading.value = false;
        throw 'Authentication error. Please login again.';
      }
      final request =
          http.MultipartRequest('POST', Uri.parse(API.deleteProductServices));
      request.headers.addAll({
        'Authorization': 'Bearer ${token.trim()}',
        'Accept': 'application/json',
      });
      request.fields.addAll({
        'product_id': productId,
      });
      var res = await request.send();
      var responseDone = await http.Response.fromStream(res);
      debugPrint('Delete Product Response Code: ${res.statusCode}');
      debugPrint('Delete Product Response: ${responseDone.body}');

      if (res.statusCode == 200 || res.statusCode == 201) {
        if (responseDone.body.trim().isEmpty) {
          return {'code': 200, 'msg': 'Product deleted successfully'};
        }
        try {
          final responseData = json.decode(responseDone.body);
          if (responseData is Map && responseData.containsKey('code')) {
            final code = responseData['code'];
            if (code == 200 || code == 201 || code == "200" || code == "201") {
              return responseData;
            } else {
              String errorMsg = responseData['msg'] ??
                  responseData['message'] ??
                  'Failed with code $code';
              if (errorMsg.length > 150) {
                errorMsg = '${errorMsg.substring(0, 150)}...';
              }
              throw errorMsg;
            }
          }
          return responseData;
        } catch (e) {
          if (e is String) rethrow;
          return {'code': 200, 'msg': 'Product deleted successfully'};
        }
      } else {
        String errorMsg = '';
        try {
          final responseData = json.decode(responseDone.body);
          errorMsg = responseData['msg'] ??
              responseData['message'] ??
              'Status ${res.statusCode}';
        } catch (_) {
          errorMsg =
              'Server error (${res.statusCode}): ${responseDone.body.isNotEmpty ? responseDone.body : "Empty Response"}';
        }
        if (errorMsg.length > 150) {
          errorMsg = '${errorMsg.substring(0, 150)}...';
        }
        throw errorMsg;
      }
    } catch (e) {
      debugPrint('Error in delete product: $e');
      throw e.toString();
    } finally {
      isButtonLoading.value = false;
    }
  }
}
