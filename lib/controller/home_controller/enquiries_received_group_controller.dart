import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:single_clik/services/api.dart';
import 'package:single_clik/utils/shar_preferences.dart';

class EnquiriesSentGroupController extends GetxController {
  final isLoading = false.obs;
  final isAutoRefreshing = false.obs;

  final sentGroupList = [].obs;

  late Timer timer;
  bool _isDisposed = false;
  bool _isTimerStarted = false;

  Future postGroupSentApi(String? enquiryId,
      {bool isAutoRefresh = false}) async {
    if (_isDisposed) return;
    if (enquiryId == null || enquiryId.isEmpty) return;

    // Start background polling timer if it's the first load
    if (!_isTimerStarted && !isAutoRefresh) {
      _isTimerStarted = true;
      timer = Timer.periodic(const Duration(seconds: 8), (t) {
        if (!_isDisposed) {
          postGroupSentApi(enquiryId, isAutoRefresh: true);
        }
      });
    }

    try {
      if (!isAutoRefresh) {
        isLoading.value = true;
      } else {
        isAutoRefreshing.value = true;
      }

      final token = await SharPreferences.getString(SharPreferences.token);
      if (token == null || token.trim().isEmpty) {
        if (!isAutoRefresh)
          isLoading.value = false;
        else
          isAutoRefreshing.value = false;
        return;
      }
      final request = http.MultipartRequest('POST', Uri.parse(API.groupSent));
      request.headers.addAll({
        'Authorization': 'Bearer ${token.trim()}',
        'Accept': 'application/json',
      });
      debugPrint('EnquiryId : $enquiryId');
      request.fields.addAll({'enquiry_id': enquiryId});

      var res = await request.send().timeout(const Duration(seconds: 10));
      var responseDone = await http.Response.fromStream(res);

      if (_isDisposed) return;

      if (res.statusCode == 200) {
        final responseData = json.decode(responseDone.body);
        if (responseData['data'] != null) {
          sentGroupList.value = responseData['data'];
          debugPrint('SenderGroupList updated: ${sentGroupList.length} items');
        }
      }
    } catch (e) {
      debugPrint('Error in postGroupSentApi: $e');
    } finally {
      if (!_isDisposed) {
        if (!isAutoRefresh) {
          isLoading.value = false;
        } else {
          isAutoRefreshing.value = false;
        }
      }
    }
  }

  @override
  void onClose() {
    _isDisposed = true;
    if (_isTimerStarted) {
      timer.cancel();
    }
    super.onClose();
  }
}
