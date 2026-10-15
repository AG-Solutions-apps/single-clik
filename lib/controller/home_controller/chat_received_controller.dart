import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:single_clik/constants/show_toast.dart';
import 'package:single_clik/services/api.dart';
import 'package:single_clik/utils/shar_preferences.dart';
import 'package:single_clik/controller/home_controller/home_controller.dart';
import 'package:single_clik/controller/home_controller/enquiries_sent_controller.dart';
import 'package:single_clik/controller/home_controller/enquiries_received_controller.dart';
import '../../constants/constant_string.dart';

class ChatReceivedController extends GetxController {
  final isLoading = false.obs;
  final isSending = false.obs;
  final userId = "".obs;

  final messageText = "".obs;
  final scrollController = ScrollController();
  final chatList = <dynamic>[].obs;

  // Local cache for instant display
  final localMessages = <Map<String, dynamic>>[].obs;
  late Timer timer;
  bool isFirstLoad = true;
  String _lastMessageId = "";

  // Cache key for storing messages
  String get _cacheKey =>
      "chat_received_messages_${Get.arguments['id'] ?? ''}_${Get.arguments['user_id'] ?? ''}";

  // Track if controller is disposed
  bool _isDisposed = false;

  // Track optimistic messages that are being sent
  final Map<String, Timer> _optimisticTimers = {};

  // Reference to TextEditingController for proper management
  TextEditingController? _charController;

  TextEditingController get charController {
    _charController ??= TextEditingController();
    return _charController!;
  }

  void getChatTimer() {
    const oneSec = Duration(seconds: 1);
    timer = Timer.periodic(
      oneSec,
      (Timer timer) {
        if (!_isDisposed) {
          postChatApi(isFromTimer: true);
        }
      },
    );
  }

  @override
  void onInit() {
    super.onInit();
    // Load cached messages FIRST (instant display)
    _loadCachedMessages();
    // Then fetch fresh data in background
    getChatTimer();
    postChatApi();
    _triggerAllRefresh();
  }

  // Load messages from cache instantly
  Future<void> _loadCachedMessages() async {
    try {
      final cachedData = await SharPreferences.getString(_cacheKey);
      if (cachedData != null && cachedData.isNotEmpty) {
        final List<dynamic> cachedMessages = json.decode(cachedData);
        if (cachedMessages.isNotEmpty) {
          // Filter out any stale optimistic messages from cache
          final validMessages = cachedMessages.where((msg) {
            if (msg is Map && msg['is_optimistic'] == true) {
              // Check if optimistic message is older than 30 seconds
              final createdAt = msg['created_at'];
              if (createdAt != null) {
                try {
                  final msgTime = DateTime.parse(createdAt.toString());
                  if (DateTime.now().difference(msgTime).inSeconds > 30) {
                    return false; // Remove stale optimistic messages
                  }
                } catch (e) {
                  return false;
                }
              }
              return true;
            }
            return true;
          }).toList();

          if (validMessages.isNotEmpty) {
            chatList.value = validMessages;
            localMessages.value = List.from(validMessages);

            // Update last message ID
            if (validMessages.isNotEmpty && validMessages.last is Map) {
              _lastMessageId =
                  (validMessages.last as Map)['id']?.toString() ?? "";
            }

            // Scroll to bottom after cache loads
            Future.delayed(const Duration(milliseconds: 50), () {
              scrollToBottom();
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading cached messages: $e');
    }
  }

  // Save messages to cache
  Future<void> _saveMessagesToCache(List<dynamic> messages) async {
    try {
      // Filter out optimistic messages before saving to cache
      final messagesToCache = messages.where((msg) {
        if (msg is Map) {
          return msg['is_optimistic'] != true;
        }
        return true;
      }).toList();

      await SharPreferences.setString(_cacheKey, json.encode(messagesToCache));
    } catch (e) {
      debugPrint('Error saving messages to cache: $e');
    }
  }

  @override
  void onClose() {
    _isDisposed = true;
    timer.cancel();

    // Cancel all optimistic timers
    for (var timer in _optimisticTimers.values) {
      timer.cancel();
    }
    _optimisticTimers.clear();

    if (_charController != null) {
      _charController!.dispose();
      _charController = null;
    }
    scrollController.dispose();

    // Trigger instant refresh of bottom bar and enquiries when user leaves chat screen
    _triggerAllRefresh();
    super.onClose();
  }

  // Helper method to get message from controller
  String getMessage() {
    return _charController?.text.trim() ?? "";
  }

  // Helper method to clear message
  void clearMessage() {
    if (_charController != null) {
      _charController!.clear();
    }
    messageText.value = "";
  }

  // Helper method to update message text
  void updateMessage(String text) {
    messageText.value = text;
  }

  Future<void> postChatApi({bool isFromTimer = false}) async {
    if (_isDisposed) return;

    try {
      final enquiryId = Get.arguments['id']?.toString() ?? '';
      final replyId = Get.arguments['user_id']?.toString() ?? '';

      if (enquiryId.isEmpty || replyId.isEmpty) {
        return;
      }

      var bodyParams = {
        'enquiry_id': enquiryId,
        'reply_id': replyId,
        'last_message_id': _lastMessageId,
      };

      final token = await SharPreferences.getString(SharPreferences.token);
      if (token == null || token.isEmpty) {
        return;
      }

      final uri = Uri.parse(API.replyChat);
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });
      request.fields.addAll(bodyParams);

      final response = await request.send().timeout(const Duration(seconds: 5));
      final responseBody = await response.stream.bytesToString();

      if (responseBody.trim().startsWith('{') ||
          responseBody.trim().startsWith('[')) {
        try {
          final responseData = json.decode(responseBody);

          if (response.statusCode == 200) {
            if (responseData['data'] != null) {
              List<dynamic> newMessages = [];

              if (responseData['data'] is List) {
                newMessages = responseData['data'];
              } else if (responseData['data'] is Map) {
                newMessages = [responseData['data']];
              }

              if (newMessages.isNotEmpty) {
                // Deduplicate optimistic messages if they have been confirmed by the server
                final optimisticMessages = chatList
                    .where((msg) => msg is Map && msg['is_optimistic'] == true)
                    .toList();

                for (var optMsg in optimisticMessages) {
                  final text = optMsg['text']?.toString() ?? '';
                  final isConfirmed = newMessages.any((newMsg) =>
                      newMsg is Map &&
                      newMsg['text']?.toString().trim() == text.trim() &&
                      newMsg['user_id']?.toString() ==
                          optMsg['user_id']?.toString());
                  if (isConfirmed) {
                    final tempId = optMsg['temp_id']?.toString() ?? '';
                    if (tempId.isNotEmpty) {
                      _removeOptimisticMessage(tempId);
                    }
                  }
                }

                // Update last message ID
                if (newMessages.last is Map &&
                    (newMessages.last as Map).containsKey('id')) {
                  _lastMessageId = (newMessages.last as Map)['id'].toString();
                }

                if (isFromTimer) {
                  // Only add new messages that don't exist yet
                  final existingIds = chatList
                      .map((msg) => msg is Map ? msg['id']?.toString() : null)
                      .toSet();

                  final uniqueNewMessages = newMessages
                      .where((msg) =>
                          msg is Map &&
                          !existingIds.contains(msg['id']?.toString()))
                      .toList();

                  if (uniqueNewMessages.isNotEmpty && !_isDisposed) {
                    chatList.addAll(uniqueNewMessages);
                    localMessages.value = List.from(chatList);
                    await _saveMessagesToCache(chatList);
                    _triggerAllRefresh();
                  }
                } else {
                  // For non-timer refresh, replace all messages but preserve optimistic ones
                  final optimisticMessages = chatList
                      .where(
                          (msg) => msg is Map && msg['is_optimistic'] == true)
                      .toList();

                  if (optimisticMessages.isNotEmpty) {
                    // Keep optimistic messages and add new ones
                    final allMessages = [...optimisticMessages, ...newMessages];
                    chatList.value = allMessages;
                    localMessages.value = List.from(allMessages);
                  } else {
                    chatList.value = newMessages;
                    localMessages.value = List.from(newMessages);
                  }
                  await _saveMessagesToCache(chatList);
                  _triggerAllRefresh();
                }

                if (isFirstLoad && !_isDisposed) {
                  isFirstLoad = false;
                  scrollToBottom();
                }
              }
            }
          }
        } catch (e) {
          debugPrint('JSON parsing error: $e');
        }
      }
    } on TimeoutException catch (e) {
      debugPrint('Timeout in postChatApi: $e');
    } catch (e) {
      debugPrint('Error in postChatApi: $e');
    }
  }

  Future<void> postSendChatApi(Map<String, dynamic> userMap) async {
    if (_isDisposed) return;

    final message = getMessage();

    if (message.isEmpty) {
      ShowToast.showToast(
        'Please enter a message',
        showSuccess: false,
      );
      return;
    }

    if (isSending.value) {
      return;
    }

    // Create optimistic message
    final tempId = DateTime.now().millisecondsSinceEpoch.toString();
    final optimisticMessage = {
      'id': tempId,
      'text': message,
      'user_id': userId.value,
      'created_at': DateTime.now().toIso8601String(),
      'is_optimistic': true,
      'temp_id': tempId,
    };

    // Add optimistic message immediately
    final currentList = List<Map<String, dynamic>>.from(localMessages);
    currentList.add(optimisticMessage);
    localMessages.value = currentList;
    chatList.add(optimisticMessage);

    // Clear input and scroll instantly
    clearMessage();
    scrollToBottom();

    // Set sending state
    isSending.value = true;

    // Set a timeout to remove optimistic message if it takes too long
    _optimisticTimers[tempId] = Timer(const Duration(seconds: 30), () {
      if (!_isDisposed) {
        // Remove stale optimistic message after 30 seconds
        _removeOptimisticMessage(tempId);
        ShowToast.showToast(
          'Message sending took too long. Please check if sent.',
          showSuccess: false,
        );
      }
    });

    try {
      final enquiryId = Get.arguments['id']?.toString() ?? '';
      final replyId = userMap['user_id']?.toString() ??
          Get.arguments['user_id']?.toString() ??
          '';

      if (enquiryId.isEmpty || replyId.isEmpty) {
        _removeOptimisticMessage(tempId);
        ShowToast.showToast('Invalid chat session', showSuccess: false);
        isSending.value = false;
        return;
      }

      var bodyParams = {
        'enquiry_id': enquiryId,
        'reply_id': replyId,
        'text': message
      };

      final token = await SharPreferences.getString(SharPreferences.token);
      if (token == null || token.isEmpty) {
        _removeOptimisticMessage(tempId);
        ShowToast.showToast('Authentication error', showSuccess: false);
        isSending.value = false;
        return;
      }

      final uri = Uri.parse(API.createReply);
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });
      request.fields.addAll(bodyParams);

      final response =
          await request.send().timeout(const Duration(seconds: 10));
      final responseBody = await response.stream.bytesToString();

      // Cancel the timeout timer
      _optimisticTimers[tempId]?.cancel();
      _optimisticTimers.remove(tempId);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Success - remove optimistic message
        _removeOptimisticMessage(tempId);

        // Refresh chat to get the real message
        await postChatApi();
        scrollToBottom();

        ShowToast.showToast('Message sent', showSuccess: true);
      } else {
        // Keep optimistic message for a bit longer
        ShowToast.showToast('Message will be delivered', showSuccess: true);

        // Try to refresh after 2 seconds
        Future.delayed(const Duration(seconds: 2), () {
          if (!_isDisposed) {
            postChatApi();
          }
        });
      }
    } catch (e) {
      debugPrint('Error sending: $e');
      _optimisticTimers[tempId]?.cancel();
      _optimisticTimers.remove(tempId);

      // Keep optimistic message - it will be resolved on next poll
      ShowToast.showToast('Sending... Will retry', showSuccess: false);

      // Try to refresh after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (!_isDisposed) {
          postChatApi();
        }
      });
    } finally {
      if (!_isDisposed) {
        isSending.value = false;
      }
    }
  }

  void _removeOptimisticMessage(String tempId) {
    if (!_isDisposed) {
      // Cancel timer if exists
      _optimisticTimers[tempId]?.cancel();
      _optimisticTimers.remove(tempId);

      // Remove from lists
      localMessages.removeWhere((msg) => msg['temp_id'] == tempId);
      chatList.removeWhere((msg) => msg is Map && msg['temp_id'] == tempId);

      // Save to cache without optimistic messages
      _saveMessagesToCache(chatList);
    }
  }

  // Instant scroll to bottom
  void scrollToBottom() {
    if (!_isDisposed && scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scrollController.hasClients) {
          try {
            scrollController.jumpTo(0.0);
          } catch (e) {
            // Ignore scroll errors
          }
        }
      });
    }
  }

  // Method to manually refresh chat
  Future<void> refreshChat() async {
    if (!_isDisposed) {
      await postChatApi();
    }
  }

  // Get messages instantly from cache
  List<dynamic> getDisplayMessages() {
    if (_isDisposed) return [];
    if (localMessages.isNotEmpty) {
      return localMessages;
    }
    return chatList;
  }

  void _triggerAllRefresh() {
    try {
      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>()
            .getSentEnquiriesUnreadCount('1', forceRefresh: true);
      }
    } catch (e) {
      debugPrint('Error refreshing home controller counts: $e');
    }
    try {
      if (Get.isRegistered<EnquiriesSentController>()) {
        Get.find<EnquiriesSentController>()
            .postSentApi("1", isAutoRefresh: true);
        Get.find<EnquiriesSentController>()
            .postSentApi("2", isAutoRefresh: true);
      }
    } catch (e) {
      debugPrint('Error refreshing enquiries sent: $e');
    }
    try {
      if (Get.isRegistered<EnquiriesReceivedController>()) {
        Get.find<EnquiriesReceivedController>()
            .postReceivedApi("1", isAutoRefresh: true);
        Get.find<EnquiriesReceivedController>()
            .postReceivedApi("2", isAutoRefresh: true);
      }
    } catch (e) {
      debugPrint('Error refreshing enquiries received: $e');
    }
  }
}
