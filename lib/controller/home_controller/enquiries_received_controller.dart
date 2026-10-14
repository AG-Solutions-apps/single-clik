import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:http/http.dart' as http;
import 'package:single_clik/services/api.dart';
import 'package:single_clik/utils/shar_preferences.dart';

class EnquiriesReceivedController extends GetxController
    with GetSingleTickerProviderStateMixin {
  final isLoading = false.obs;
  final isAutoRefreshing = false.obs;
  late TabController tabController;

  final openReceivedList = [].obs;
  final closeReceivedList = [].obs;

  // Real-time tracking: counts how many NEW enquiries arrived since last view
  final newOpenCount = 0.obs;

  // Track last known open count for change detection
  int _lastOpenCount = 0;

  late Timer _pollTimer;
  bool _isDisposed = false;

  // Prevent concurrent calls
  bool _isFetchingOpen = false;
  bool _isFetchingClose = false;

  void getReceivedTimer() {
    // Poll every 2 seconds for real-time feel
    _pollTimer = Timer.periodic(
      const Duration(seconds: 2),
      (Timer timer) {
        if (!_isDisposed) {
          _pollReceivedData();
        }
      },
    );
  }

  /// Polls both open and closed enquiries without blocking loading state
  void _pollReceivedData() {
    if (!_isFetchingOpen) {
      postReceivedApi("1", isAutoRefresh: true);
    }
    if (!_isFetchingClose) {
      postReceivedApi("2", isAutoRefresh: true);
    }
  }

  @override
  void onInit() {
    tabController = TabController(length: 2, vsync: this, initialIndex: 0);
    // Initial load with loading indicator
    postReceivedApi("1");
    postReceivedApi("2");
    // Start real-time polling timer
    getReceivedTimer();
    super.onInit();
  }

  Future postReceivedApi(String enquiriesType, {bool isAutoRefresh = false}) async {
    if (_isDisposed) return;

    // Prevent concurrent fetches for the same type
    if (enquiriesType == "1") {
      if (_isFetchingOpen) return;
      _isFetchingOpen = true;
    } else if (enquiriesType == "2") {
      if (_isFetchingClose) return;
      _isFetchingClose = true;
    }

    try {
      if (!isAutoRefresh) {
        isLoading.value = true;
      } else {
        isAutoRefreshing.value = true;
      }

      final token = await SharPreferences.getString(SharPreferences.token);
      if (token == null || token.isEmpty) return;

      final request = http.MultipartRequest('POST', Uri.parse(API.received));
      request.headers.addAll({
        'Authorization': 'Bearer ${token.trim()}',
        'Accept': 'application/json',
      });
      request.fields.addAll({'enquiries_type': enquiriesType});

      var res = await request.send().timeout(const Duration(seconds: 8));
      var responseDone = await http.Response.fromStream(res);

      if (_isDisposed) return;

      if (res.statusCode == 200) {
        final responseData = json.decode(responseDone.body);
        if (responseData['data'] != null) {
          List<dynamic> newData = responseData['data'];

          if (enquiriesType == "1") {
            final prevCount = openReceivedList.length;
            final fetchedCount = newData.length;

            // Detect new enquiries: if new count > old count, there are new items
            if (isAutoRefresh && fetchedCount > _lastOpenCount && _lastOpenCount > 0) {
              final delta = fetchedCount - _lastOpenCount;
              newOpenCount.value += delta;
            }

            openReceivedList.value = newData;
            _lastOpenCount = fetchedCount;

            debugPrint('✅ Received open enquiries: $fetchedCount (prev: $prevCount)');
          } else if (enquiriesType == "2") {
            closeReceivedList.value = newData;
          }
        } else {
          // API returned null data — keep existing list
          if (enquiriesType == "1" && openReceivedList.isEmpty) {
            openReceivedList.value = [];
          }
        }
      }
    } catch (e) {
      debugPrint('Error in postReceivedApi($enquiriesType): $e');
    } finally {
      if (!_isDisposed) {
        if (!isAutoRefresh) {
          isLoading.value = false;
        } else {
          isAutoRefreshing.value = false;
        }

        if (enquiriesType == "1") {
          _isFetchingOpen = false;
        } else if (enquiriesType == "2") {
          _isFetchingClose = false;
        }
      }
    }
  }

  /// Call this when user opens the Received tab to reset new enquiry badge
  void markOpenEnquiriesAsSeen() {
    newOpenCount.value = 0;
  }

  @override
  void onClose() {
    _isDisposed = true;
    _pollTimer.cancel();
    tabController.dispose();
    super.onClose();
  }
}
