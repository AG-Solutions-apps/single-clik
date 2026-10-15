import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:single_clik/constants/show_toast.dart';
import 'package:single_clik/services/api.dart';
import 'package:single_clik/utils/shar_preferences.dart';
import 'home_controller.dart';

class ReferralController extends GetxController {
  final isLoading = false.obs;
  final isClaiming = false.obs;

  final totalPoints = "0".obs;
  final claimPoints = "0".obs;
  final historyPoints = <Map<String, dynamic>>[].obs;
  final claimHistory = <Map<String, dynamic>>[].obs;
  final products = <Map<String, dynamic>>[].obs;
  final imageUrl = "".obs;
  final userReferralCode = "".obs;

  @override
  void onInit() {
    super.onInit();
    _resolveCodeFromCacheOrHome();
    fetchReferralData();
  }

  void _resolveCodeFromCacheOrHome() async {
    if (Get.isRegistered<HomeController>()) {
      final hc = Get.find<HomeController>();
      final code = _extractReferralCode(hc.userData);
      if (code.isNotEmpty && code.toLowerCase() != 'null') {
        userReferralCode.value = code;
        debugPrint('✅ Referral Code pre-resolved from HomeController: "$code"');
        return;
      }
    }
    final cachedUser =
        await SharPreferences.getString(SharPreferences.userData);
    if (cachedUser != null && cachedUser.trim().isNotEmpty) {
      try {
        final decoded = json.decode(cachedUser);
        final code = _extractReferralCode(decoded);
        if (code.isNotEmpty && code.toLowerCase() != 'null') {
          userReferralCode.value = code;
          debugPrint(
              '✅ Referral Code pre-resolved from SharPreferences: "$code"');
        }
      } catch (_) {}
    }
  }

  int get availablePoints {
    final total = int.tryParse(totalPoints.value) ?? 0;
    final claimed = int.tryParse(claimPoints.value) ?? 0;
    return total - claimed < 0 ? 0 : total - claimed;
  }

  /// Extracts referral code from various response structures (user vs business)
  String _extractReferralCode(dynamic data) {
    if (data == null) return '';

    if (data is Map) {
      // 1. Direct referral code keys
      const keys = [
        'referral_code',
        'refferal_code',
        'referralCode',
        'refferalCode',
        'ref_code',
        'refer_code',
        'user_referral_code',
      ];

      for (final key in keys) {
        if (data.containsKey(key)) {
          final val = data[key];
          if (val != null) {
            final str = val.toString().trim();
            if (str.isNotEmpty && str.toLowerCase() != 'null') {
              return str;
            }
          }
        }
      }

      // 2. Common nested containers (business profile / user data)
      const containers = [
        'data',
        'user',
        'profile',
        'business',
        'business_profile',
        'user_profile',
        'business_data',
        'user_data',
      ];

      for (final containerKey in containers) {
        if (data.containsKey(containerKey)) {
          final code = _extractReferralCode(data[containerKey]);
          if (code.isNotEmpty) return code;
        }
      }

      // 3. Check map values (skipping product/history lists)
      for (final entry in data.entries) {
        final keyStr = entry.key.toString().toLowerCase();
        if (keyStr == 'products' ||
            keyStr == 'product_services' ||
            keyStr == 'claim_history') {
          continue;
        }
        if (entry.value is Map || entry.value is List) {
          final code = _extractReferralCode(entry.value);
          if (code.isNotEmpty) return code;
        }
      }
    } else if (data is List) {
      for (final item in data) {
        final code = _extractReferralCode(item);
        if (code.isNotEmpty) return code;
      }
    }

    return '';
  }

  Future<void> fetchReferralData() async {
    try {
      isLoading.value = true;

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
      debugPrint('Fetch Referral Data Status Code: ${res.statusCode}');

      if (res.statusCode == 200) {
        final responseData = json.decode(responseDone.body);
        debugPrint('Fetch Referral Data Response: ${responseDone.body}');

        if (responseData is Map<String, dynamic>) {
          totalPoints.value = (responseData['total_points'] ?? '0').toString();
          claimPoints.value = (responseData['claim_points'] ?? '0').toString();
          imageUrl.value = (responseData['image_url'] ?? '').toString();

          // 1. Direct check on responseData['data'] (for business users 'data' is a Map)
          String code = '';
          if (responseData['data'] != null) {
            if (responseData['data'] is Map) {
              final dataMap = responseData['data'] as Map;
              code =
                  (dataMap['referral_code'] ?? dataMap['refferal_code'] ?? '')
                      .toString()
                      .trim();
            } else if (responseData['data'] is List &&
                (responseData['data'] as List).isNotEmpty) {
              for (var item in (responseData['data'] as List)) {
                if (item is Map) {
                  final c =
                      (item['referral_code'] ?? item['refferal_code'] ?? '')
                          .toString()
                          .trim();
                  if (c.isNotEmpty && c.toLowerCase() != 'null') {
                    code = c;
                    break;
                  }
                }
              }
            }
          }

          // 2. If not found in data, check root or other containers
          if (code.isEmpty || code.toLowerCase() == 'null') {
            code = _extractReferralCode(responseData);
          }

          // 3. Fallback to HomeController.userData
          if ((code.isEmpty || code.toLowerCase() == 'null') &&
              Get.isRegistered<HomeController>()) {
            final hc = Get.find<HomeController>();
            code = _extractReferralCode(hc.userData);
          }

          // 4. Fallback to cached SharedPreferences userData
          if (code.isEmpty || code.toLowerCase() == 'null') {
            final cachedUser =
                await SharPreferences.getString(SharPreferences.userData);
            if (cachedUser != null && cachedUser.trim().isNotEmpty) {
              try {
                final decoded = json.decode(cachedUser);
                code = _extractReferralCode(decoded);
              } catch (_) {}
            }
          }

          if (code.isNotEmpty && code.toLowerCase() != 'null') {
            userReferralCode.value = code;
          }
          debugPrint('✅ Referral Code resolved: "${userReferralCode.value}"');

          // History Points (Referrals)
          if (responseData['history_points'] is List) {
            historyPoints.value = List<Map<String, dynamic>>.from(
              (responseData['history_points'] as List)
                  .map((e) => Map<String, dynamic>.from(e)),
            );
          } else {
            historyPoints.clear();
          }

          // Claim History
          if (responseData['claim_history'] is List) {
            claimHistory.value = List<Map<String, dynamic>>.from(
              (responseData['claim_history'] as List)
                  .map((e) => Map<String, dynamic>.from(e)),
            );
          } else {
            claimHistory.clear();
          }

          // Available Products for Claim
          if (responseData['products'] is List) {
            final rawProducts = List<Map<String, dynamic>>.from(
              (responseData['products'] as List)
                  .map((e) => Map<String, dynamic>.from(e)),
            );
            rawProducts.sort((a, b) {
              final ptsA = int.tryParse(
                      a['refferal_products_points']?.toString() ?? '0') ??
                  0;
              final ptsB = int.tryParse(
                      b['refferal_products_points']?.toString() ?? '0') ??
                  0;
              return ptsA.compareTo(ptsB);
            });
            products.value = rawProducts;
          } else {
            products.clear();
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching referral data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> postCreateReferralClaimApi(dynamic productId) async {
    try {
      isClaiming.value = true;
      final token = await SharPreferences.getString(SharPreferences.token);
      if (token == null || token.trim().isEmpty) {
        isClaiming.value = false;
        ShowToast.showToast("Authentication error. Please login again.",
            showSuccess: false);
        return false;
      }
      final request =
          http.MultipartRequest('POST', Uri.parse(API.createReferralClaim));
      request.headers.addAll({
        'Authorization': 'Bearer ${token.trim()}',
        'Accept': 'application/json',
      });
      request.fields['refferal_product_id'] = productId.toString();

      var res = await request.send();
      var responseDone = await http.Response.fromStream(res);
      debugPrint('Create Referral Claim Response Code: ${res.statusCode}');
      debugPrint('Create Referral Claim Response: ${responseDone.body}');

      if (res.statusCode == 200) {
        final responseData = json.decode(responseDone.body);
        if (responseData['code'] == 200 ||
            responseData['status'] == true ||
            responseData['status'] == 'true') {
          ShowToast.showToast(
            responseData['msg'] ??
                responseData['message'] ??
                "Reward claimed successfully!",
            showSuccess: true,
          );
          await fetchReferralData();
          return true;
        } else {
          ShowToast.showToast(
            responseData['msg'] ??
                responseData['message'] ??
                "Failed to claim reward",
            showSuccess: false,
          );
          return false;
        }
      } else {
        ShowToast.showToast("Failed to claim reward. Please try again.",
            showSuccess: false);
        return false;
      }
    } catch (e) {
      debugPrint('Error claiming reward: $e');
      ShowToast.showToast("An error occurred while claiming reward.",
          showSuccess: false);
      return false;
    } finally {
      isClaiming.value = false;
    }
  }
}
