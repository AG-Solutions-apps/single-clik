import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:single_clik/constants/constant_color.dart';
import 'package:single_clik/controller/home_controller/chat_sent_controller.dart';
import 'package:single_clik/utils/shar_preferences.dart';
import 'package:single_clik/widget/app_image_assets.dart';

import '../../../constants/constant_string.dart';

class ChatSentScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final bool isChat;

  const ChatSentScreen({
    super.key,
    required this.userData,
    required this.isChat,
  });

  @override
  State<ChatSentScreen> createState() => _ChatSentScreenState();
}

class _ChatSentScreenState extends State<ChatSentScreen> {
  late ChatSentController chatSentController;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Initialize controller
    chatSentController = Get.put(ChatSentController());

    // Set user ID immediately
    _setUserId();
  }

  Future<void> _setUserId() async {
    try {
      final userDataString =
          await SharPreferences.getString(SharPreferences.userData);
      if (userDataString != null) {
        final userData = jsonDecode(userDataString);
        chatSentController.userId.value = userData['id'].toString();
      }
    } catch (e) {
      debugPrint('Error getting user ID: $e');
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC), // Light grey background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1, // Subtle shadow matching the image
        shadowColor: Colors.black.withOpacity(0.1),
        leading: GestureDetector(
          onTap: () {
            Get.back();
          },
          child: const Center(
            child: Icon(
              Icons.arrow_back,
              color: Color(0xff1E40AF), // Dark blue back arrow
            ),
          ),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            /// Avatar
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xffE2E8F0), width: 1),
              ),
              child: ClipOval(
                child: AppImageAsset(
                  image:
                      "${ConstantString.userImgUrlPath}${widget.userData['photo']}",
                  isFile: false,
                  fit: BoxFit.cover,
                  height: 38,
                  width: 38,
                ),
              ),
            ),
            const SizedBox(width: 12),

            /// Title and Online Status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.userData['name'] ?? "User",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xff0F172A), // Dark text
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Obx(
        () {
          // Get messages instantly from cache
          final messages = chatSentController.getDisplayMessages();

          // Show loading ONLY if no messages and still loading first time
          if (chatSentController.isLoading.value && messages.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return Column(
            children: [
              Expanded(
                child: messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        reverse: true,
                        itemCount: messages.length,
                        controller: chatSentController.scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 20,
                        ),
                        itemBuilder: (context, index) {
                          final chatItem =
                              messages[messages.length - 1 - index];
                          final isMe = chatItem['user_id']?.toString() ==
                              chatSentController.userId.value;
                          final isOptimistic =
                              chatItem['is_optimistic'] == true;

                          return _buildChatBubble(
                            context,
                            isMe,
                            chatItem,
                            isOptimistic: isOptimistic,
                          );
                        },
                      ),
              ),
              if (widget.isChat) _buildMessageInput(width),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: ConstantColor.grayColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 16,
              color: ConstantColor.grayColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start the conversation',
            style: TextStyle(
              fontSize: 14,
              color: ConstantColor.grayColor.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput(double width) {
    return Obx(
      () => Container(
        padding: const EdgeInsets.fromLTRB(
            16, 12, 16, 24), // Extra bottom padding for safe area
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(
                      0xffF1F5F9), // Light gray pill background from image
                  borderRadius: BorderRadius.circular(30.0),
                ),
                child: TextFormField(
                  controller: chatSentController.textController,
                  focusNode: _focusNode,
                  onChanged: (value) {
                    chatSentController.updateMessage(value);
                  },
                  onFieldSubmitted: (_) => _sendMessage(),
                  textInputAction: TextInputAction.send,
                  enabled: !chatSentController.isSending.value,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xff0F172A),
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 20,
                    ),
                    hintText: "Type your message...",
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: Color(0xff94A3B8),
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: chatSentController.isSending.value ? null : _sendMessage,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: chatSentController.isSending.value
                      ? Colors.grey
                      : const Color(0xff1E40AF), // Dark blue from image
                  shape: BoxShape.circle,
                ),
                child: chatSentController.isSending.value
                    ? const Padding(
                        padding: EdgeInsets.all(14.0),
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBubble(BuildContext context, bool isMe, dynamic data,
      {bool isOptimistic = false}) {
    final message = data['text'] ?? "";
    final createdAt = data['created_at'];

    String timeString = "";
    if (createdAt != null && createdAt.toString().isNotEmpty && !isOptimistic) {
      try {
        String dateStr = createdAt.toString();
        DateTime dateTime;
        if (!dateStr.endsWith('Z') && !dateStr.contains('+')) {
          String formattedStr = dateStr.replaceAll(' ', 'T');
          if (!formattedStr.endsWith('Z')) {
            formattedStr = '${formattedStr}Z';
          }
          dateTime = DateTime.parse(formattedStr).toLocal();
        } else {
          dateTime = DateTime.parse(dateStr).toLocal();
        }
        timeString = DateFormat('hh:mm a').format(dateTime);
      } catch (e) {
        try {
          final dateTime = DateTime.parse(createdAt.toString()).toLocal();
          timeString = DateFormat('hh:mm a').format(dateTime);
        } catch (_) {
          timeString = DateFormat('hh:mm a').format(DateTime.now());
        }
      }
    } else if (!isOptimistic) {
      timeString = DateFormat('hh:mm a').format(DateTime.now());
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 14.0,
            vertical: 10.0,
          ),
          decoration: BoxDecoration(
            color: isMe
                ? (isOptimistic
                    ? const Color(0xffDDE8FF).withOpacity(0.6)
                    : const Color(0xffDDE8FF)) // Light blue from image
                : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16.0),
              topRight: const Radius.circular(16.0),
              bottomLeft: Radius.circular(isMe ? 16.0 : 4.0),
              bottomRight: Radius.circular(isMe ? 4.0 : 16.0),
            ),
            boxShadow: [
              if (!isMe)
                BoxShadow(
                  color: const Color(0xff000000).withAlpha(10),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isOptimistic && isMe) ...[
                    SizedBox(
                      height: 14,
                      width: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: ConstantColor.primary.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      message,
                      style: const TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                        color: Color(0xff0F172A), // Dark text inside bubble
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              /// Inner Timestamp & Read Receipt
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isOptimistic ? "Sending..." : timeString,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 10,
                      color: const Color(0xff64748B),
                      fontStyle:
                          isOptimistic ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),
                  if (isMe && !isOptimistic) ...[
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.done_all_rounded, // Read Receipt checkmarks
                      size: 14,
                      color: Color(0xff3B82F6),
                    ),
                  ]
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    await chatSentController.postSendChatApi();
    // Keep focus for continuous typing
    _focusNode.requestFocus();
  }
}
