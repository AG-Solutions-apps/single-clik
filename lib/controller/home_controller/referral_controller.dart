import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:single_clik/constants/show_toast.dart';
import 'package:single_clik/services/api.dart';
import 'package:single_clik/utils/shar_preferences.dart';

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
    fetchReferralData();
    super.onInit();
  }

  int get availablePoints {
    final total = int.tryParse(totalPoints.value) ?? 0;
    final claimed = int.tryParse(claimPoints.value) ?? 0;
    return total - claimed < 0 ? 0 : total - claimed;
  }

  Future<void> fetchReferralData() async {
    try {
      isLoading.value = true;
      final token = await SharPreferences.getString(SharPreferences.token);
      final request = http.MultipartRequest('POST', Uri.parse(API.fetchProfile));
      request.headers.addAll({
        'Authorization': 'Bearer $token',
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

          // User referral code
          if (responseData['data'] is List && (responseData['data'] as List).isNotEmpty) {
            final firstUser = responseData['data'][0];
            if (firstUser is Map) {
              userReferralCode.value = (firstUser['referral_code'] ?? '').toString();
            }
          }

          // History Points (Referrals)
          if (responseData['history_points'] is List) {
            historyPoints.value = List<Map<String, dynamic>>.from(
              (responseData['history_points'] as List).map((e) => Map<String, dynamic>.from(e)),
            );
          } else {
            historyPoints.clear();
          }

          // Claim History
          if (responseData['claim_history'] is List) {
            claimHistory.value = List<Map<String, dynamic>>.from(
              (responseData['claim_history'] as List).map((e) => Map<String, dynamic>.from(e)),
            );
          } else {
            claimHistory.clear();
          }

          // Available Products for Claim
          if (responseData['products'] is List) {
            products.value = List<Map<String, dynamic>>.from(
              (responseData['products'] as List).map((e) => Map<String, dynamic>.from(e)),
            );
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
      final request = http.MultipartRequest('POST', Uri.parse(API.createReferralClaim));
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });
      request.fields['refferal_product_id'] = productId.toString();

      var res = await request.send();
      var responseDone = await http.Response.fromStream(res);
      debugPrint('Create Referral Claim Response Code: ${res.statusCode}');
      debugPrint('Create Referral Claim Response: ${responseDone.body}');

      if (res.statusCode == 200) {
        final responseData = json.decode(responseDone.body);
        if (responseData['code'] == 200 || responseData['status'] == true || responseData['status'] == 'true') {
          ShowToast.showToast(
            responseData['msg'] ?? responseData['message'] ?? "Reward claimed successfully!",
            showSuccess: true,
          );
          await fetchReferralData();
          return true;
        } else {
          ShowToast.showToast(
            responseData['msg'] ?? responseData['message'] ?? "Failed to claim reward",
            showSuccess: false,
          );
          return false;
        }
      } else {
        ShowToast.showToast("Failed to claim reward. Please try again.", showSuccess: false);
        return false;
      }
    } catch (e) {
      debugPrint('Error claiming reward: $e');
      ShowToast.showToast("An error occurred while claiming reward.", showSuccess: false);
      return false;
    } finally {
      isClaiming.value = false;
    }
  }
}
