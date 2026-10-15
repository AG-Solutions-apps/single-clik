import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:http/http.dart' as http;
import 'package:single_clik/constants/constant_string.dart';
import 'package:single_clik/constants/show_toast.dart';
import 'package:single_clik/services/api.dart';
import 'package:single_clik/utils/shar_preferences.dart';

class EnquiriesSentController extends GetxController
    with GetSingleTickerProviderStateMixin {
  final isLoading = false.obs;
  final isAutoRefreshing = false.obs;
  late TabController tabController;

  final openSentList = [].obs;
  final closeSentList = [].obs;

  // Cache keys for storing data
  String get _openCacheKey => "sent_enquiries_open";
  String get _closeCacheKey => "sent_enquiries_close";

  // Track last update times to prevent excessive refreshes
  DateTime? _lastOpenUpdate;
  DateTime? _lastCloseUpdate;

  late Timer timer;
  bool _isDisposed = false;

  void getSentTimer() {
    const period = Duration(seconds: 4);
    timer = Timer.periodic(
      period,
      (Timer timer) {
        if (!_isDisposed) {
          postSentApi("1", isAutoRefresh: true);
          postSentApi("2", isAutoRefresh: true);
        }
      },
    );
  }

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 2, vsync: this, initialIndex: 0);

    // Load cached data first for instant display
    _loadCachedData();

    // Then fetch fresh data
    _fetchInitialData();

    // Start background timer
    getSentTimer();
  }

  Future<void> _loadCachedData() async {
    try {
      // Load open enquiries from cache
      final openCached = await SharPreferences.getString(_openCacheKey);
      if (openCached != null && openCached.isNotEmpty) {
        final List<dynamic> cachedOpen = json.decode(openCached);
        if (cachedOpen.isNotEmpty) {
          openSentList.value = cachedOpen;
          debugPrint('Loaded ${cachedOpen.length} open enquiries from cache');
        }
      }

      // Load closed enquiries from cache
      final closeCached = await SharPreferences.getString(_closeCacheKey);
      if (closeCached != null && closeCached.isNotEmpty) {
        final List<dynamic> cachedClose = json.decode(closeCached);
        if (cachedClose.isNotEmpty) {
          closeSentList.value = cachedClose;
          debugPrint(
              'Loaded ${cachedClose.length} closed enquiries from cache');
        }
      }
    } catch (e) {
      debugPrint('Error loading cached data: $e');
    }
  }

  Future<void> _saveToCache(String type, List<dynamic> data) async {
    try {
      if (type == "1") {
        await SharPreferences.setString(_openCacheKey, json.encode(data));
      } else if (type == "2") {
        await SharPreferences.setString(_closeCacheKey, json.encode(data));
      }
    } catch (e) {
      debugPrint('Error saving to cache: $e');
    }
  }

  Future<void> _fetchInitialData() async {
    // Fetch both tabs data
    await Future.wait([
      postSentApi("1", isAutoRefresh: false),
      postSentApi("2", isAutoRefresh: false),
    ]);
  }

  Future<void> postSentApi(String? enquiriesType,
      {bool isAutoRefresh = false}) async {
    if (_isDisposed) return;
    // Skip loading indicator for auto-refresh
    if (!isAutoRefresh) {
      isLoading.value = true;
    } else {
      isAutoRefreshing.value = true;
    }

    try {
      final token = await SharPreferences.getString(SharPreferences.token);
      if (token == null || token.isEmpty) {
        debugPrint('Token is missing');
        if (!isAutoRefresh) {
          isLoading.value = false;
        } else {
          isAutoRefreshing.value = false;
        }
        return;
      }

      final request = http.MultipartRequest('POST', Uri.parse(API.sent));
      request.headers.addAll({
        'Authorization': 'Bearer ${token.trim()}',
        'Accept': 'application/json',
      });
      request.fields.addAll({'enquiries_type': enquiriesType!});

      // Set timeout to prevent hanging
      var res = await request.send().timeout(const Duration(seconds: 10));
      var responseDone = await http.Response.fromStream(res);

      if (res.statusCode == 200) {
        final responseData = json.decode(responseDone.body);

        if (responseData['data'] != null) {
          List<dynamic> newData = responseData['data'];

          // Check if data has changed before updating
          bool hasChanged = false;

          if (enquiriesType == "1") {
            if (openSentList.length != newData.length) {
              hasChanged = true;
            } else {
              // Check if any item has changed (by id or unread count)
              for (int i = 0; i < openSentList.length; i++) {
                if (openSentList[i]['id'] != newData[i]['id'] ||
                    openSentList[i]['unread_reply_count'] !=
                        newData[i]['unread_reply_count']) {
                  hasChanged = true;
                  break;
                }
              }
            }

            if (hasChanged) {
              openSentList.value = newData;
              await _saveToCache("1", newData);
              _lastOpenUpdate = DateTime.now();
              debugPrint('Open enquiries updated: ${newData.length} items');
            }
          } else if (enquiriesType == "2") {
            if (closeSentList.length != newData.length) {
              hasChanged = true;
            } else {
              for (int i = 0; i < closeSentList.length; i++) {
                if (closeSentList[i]['id'] != newData[i]['id']) {
                  hasChanged = true;
                  break;
                }
              }
            }

            if (hasChanged) {
              closeSentList.value = newData;
              await _saveToCache("2", newData);
              _lastCloseUpdate = DateTime.now();
              debugPrint('Closed enquiries updated: ${newData.length} items');
            }
          }
        }
      } else {
        debugPrint('Error status code: ${res.statusCode}');
        if (!isAutoRefresh) {
          ShowToast.showToast(
            'Failed to load enquiries',
            showSuccess: false,
          );
        }
      }
    } on TimeoutException catch (e) {
      debugPrint('Timeout in postSentApi: $e');
      if (!isAutoRefresh) {
        ShowToast.showToast(
          'Connection timeout. Please try again.',
          showSuccess: false,
        );
      }
    } on SocketException catch (e) {
      debugPrint('Network error: $e');
      if (!isAutoRefresh) {
        ShowToast.showToast(
          'No internet connection',
          showSuccess: false,
        );
      }
    } catch (e) {
      debugPrint('Error in postSentApi: $e');
      if (!isAutoRefresh) {
        ShowToast.showToast(
          ConstantString.somethingWantWrongMsg,
          showSuccess: false,
        );
      }
    } finally {
      if (!isAutoRefresh) {
        isLoading.value = false;
      } else {
        isAutoRefreshing.value = false;
      }
    }
  }

  Future<void> postCloseSentApi(String? enquiryId) async {
    if (enquiryId == null || enquiryId.isEmpty) {
      ShowToast.showToast('Invalid enquiry ID', showSuccess: false);
      return;
    }

    try {
      final token = await SharPreferences.getString(SharPreferences.token);
      if (token == null || token.isEmpty) {
        ShowToast.showToast('Authentication error', showSuccess: false);
        return;
      }

      final request = http.MultipartRequest('POST', Uri.parse(API.sentClose));
      request.headers.addAll({
        'Authorization': 'Bearer ${token.trim()}',
        'Accept': 'application/json',
      });
      request.fields.addAll({'enquiry_id': enquiryId});

      var res = await request.send().timeout(const Duration(seconds: 10));
      var responseDone = await http.Response.fromStream(res);

      if (res.statusCode == 200) {
        final responseData = json.decode(responseDone.body);

        // Check if responseData['code'] is int or string
        bool isSuccess = false;
        if (responseData['code'] is int) {
          isSuccess = responseData['code'] == 200;
        } else if (responseData['code'] is String) {
          isSuccess = responseData['code'] == '200';
        } else if (responseData['status'] != null) {
          isSuccess = responseData['status'] == 'success';
        }

        if (isSuccess) {
          // Remove from open list and add to closed list
          final closedEnquiry = openSentList.firstWhere(
            (item) => item['id'].toString() == enquiryId,
            orElse: () => null,
          );

          if (closedEnquiry != null) {
            // Update status
            closedEnquiry['status'] = 'Closed';
            openSentList
                .removeWhere((item) => item['id'].toString() == enquiryId);
            closeSentList.insert(0, closedEnquiry);

            // Save to cache
            await _saveToCache("1", openSentList);
            await _saveToCache("2", closeSentList);
          }

          // Refresh from server in background
          postSentApi("1", isAutoRefresh: true);
          postSentApi("2", isAutoRefresh: true);

          ShowToast.showToast(
            responseData['msg'] ?? ConstantString.enquireCloseSuccessfullyMsg,
            showSuccess: true,
          );
        } else {
          ShowToast.showToast(
            responseData['msg'] ?? ConstantString.somethingWantWrongMsg,
            showSuccess: false,
          );
        }
      } else {
        ShowToast.showToast(
          ConstantString.somethingWantWrongMsg,
          showSuccess: false,
        );
      }
    } on TimeoutException catch (e) {
      ShowToast.showToast(
        'Connection timeout. Please try again.',
        showSuccess: false,
      );
      debugPrint(e.toString());
    } on SocketException catch (e) {
      ShowToast.showToast(
        'No internet connection',
        showSuccess: false,
      );
      debugPrint(e.toString());
    } catch (e) {
      ShowToast.showToast(
        ConstantString.somethingWantWrongMsg,
        showSuccess: false,
      );
      debugPrint(e.toString());
    }
  }

  // Method to manually refresh data
  Future<void> refreshData() async {
    await Future.wait([
      postSentApi("1", isAutoRefresh: false),
      postSentApi("2", isAutoRefresh: false),
    ]);
  }

  // Method to get unread count for open enquiries
  int getUnreadCount() {
    int count = 0;
    for (var enquiry in openSentList) {
      int unreadCount = 0;
      final unreadValue = enquiry['unread_reply_count'];

      if (unreadValue != null) {
        if (unreadValue is int) {
          unreadCount = unreadValue;
        } else if (unreadValue is String) {
          unreadCount = int.tryParse(unreadValue) ?? 0;
        } else if (unreadValue is double) {
          unreadCount = unreadValue.toInt();
        } else if (unreadValue is num) {
          unreadCount = unreadValue.toInt();
        }
      }

      if (unreadCount > 0) {
        count += unreadCount;
      }
    }
    return count;
  }

  // Method to check if there are any unread messages
  bool get hasUnreadMessages => getUnreadCount() > 0;

  @override
  void onClose() {
    _isDisposed = true;
    timer.cancel();
    tabController.dispose();
    super.onClose();
  }
}
