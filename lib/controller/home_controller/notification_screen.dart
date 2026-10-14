import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../services/api.dart';
import '../../utils/shar_preferences.dart';

class NotificationController extends GetxController {
  final isLoading = false.obs;
  final isAutoRefreshing = false.obs;
  RxList notificationDataList = [].obs;

  late Timer timer;
  bool _isDisposed = false;

  void getNotificationTimer() {
    const period = Duration(seconds: 15);
    timer = Timer.periodic(
      period,
      (Timer timer) {
        if (!_isDisposed) {
          getAllNotifications(isAutoRefresh: true);
        }
      },
    );
  }

  @override
  void onInit() {
    super.onInit();
    getAllNotifications();
    getNotificationTimer();
  }

  Future<void> getAllNotifications({bool isAutoRefresh = false}) async {
    if (_isDisposed) return;
    try {
      if (!isAutoRefresh) {
        isLoading.value = true;
      } else {
        isAutoRefreshing.value = true;
      }
      
      final token = await SharPreferences.getString(SharPreferences.token);
      if (token == null || token.trim().isEmpty) {
        if (!isAutoRefresh) isLoading.value = false;
        else isAutoRefreshing.value = false;
        notificationDataList.value = [];
        return;
      }
      final request =
          http.MultipartRequest('POST', Uri.parse(API.notification));
      request.headers.addAll({
        'Authorization': 'Bearer ${token.trim()}',
        'Accept': 'application/json',
      });

      var res = await request.send().timeout(const Duration(seconds: 10));
      var responseDone = await http.Response.fromStream(res);

      if (_isDisposed) return;

      if (res.statusCode == 200) {
        final responseData = json.decode(responseDone.body);
        if (responseData['code'] == 200) {
          notificationDataList.value = responseData['data'] ?? [];
        } else {
          notificationDataList.value = [];
        }
      } else {
        notificationDataList.value = [];
      }
    }
    catch (e) {
      debugPrint('Error fetching notifications: $e');
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
    timer.cancel();
    super.onClose();
  }
}
