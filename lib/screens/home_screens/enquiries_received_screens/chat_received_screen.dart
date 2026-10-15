import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:single_clik/constants/constant_color.dart';
import 'package:single_clik/constants/show_toast.dart';
import 'package:single_clik/controller/home_controller/chat_received_controller.dart';
import 'package:single_clik/controller/home_controller/home_controller.dart';
import 'package:single_clik/utils/shar_preferences.dart';
import 'package:single_clik/widget/app_image_assets.dart';

import '../../../constants/constant_string.dart';
import '../../../controller/home_controller/enquiries_received_controller.dart';

class ChatReceivedScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final bool isChat;

  const ChatReceivedScreen({
    super.key,
    required this.userData,
    required this.isChat,
  });

  @override
  State<ChatReceivedScreen> createState() => ChatReceivedScreenState();
}

class ChatReceivedScreenState extends State<ChatReceivedScreen> {
  HomeController homeController = Get.put(HomeController());
  EnquiriesReceivedController enquiriesReceivedController =
      Get.put(EnquiriesReceivedController());

  ChatReceivedController chatReceivedController =
      Get.put(ChatReceivedController());
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    getData();
    super.initState();
  }

  Future<void> getData() async {
    final userDataString =
        await SharPreferences.getString(SharPreferences.userData);

    if (userDataString != null) {
      final userData = jsonDecode(userDataString);
      chatReceivedController.userId.value = userData['id'].toString();
      debugPrint('userId : ${chatReceivedController.userId.value}');
    } else {
      debugPrint('No user data found in SharedPreferences');
    }
  }

  /// Pop-up dialog to show the full enquiry message when text is tapped
  void _showFullMessageDialog(String text) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Enquiry Details",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff0F172A),
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  child: Text(
                    text,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xff475569),
                      height: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xff2563EB),
                  ),
                  onPressed: () => Get.back(),
                  child: const Text(
                    "Close",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC), // Light grey background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: ConstantColor.primaryGradient,
          ),
        ),
        leading: GestureDetector(
          onTap: () {
            Get.back();
          },
          child: Center(
            child: Icon(
              Icons.arrow_back_outlined,
              color: ConstantColor.whiteColor,
            ),
          ),
        ),
        title: Text(
          "Enquiries Received",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w400,
            color: ConstantColor.whiteColor,
          ),
        ),
      ),
      body: Obx(
        () {
          final messages = chatReceivedController.getDisplayMessages();
          if (chatReceivedController.isLoading.value && messages.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          String name = widget.userData['name'] == null ||
                  widget.userData['name'].toString().trim().isEmpty
              ? 'Name ${ConstantString.naLabel}'
              : widget.userData['name'].toString();

          String category = widget.userData['category'] == null ||
                  widget.userData['category'].toString().trim().isEmpty
              ? 'Category ${ConstantString.naLabel}'
              : widget.userData['category'].toString();

          String subCategory = widget.userData['subcategory'] == null ||
                  widget.userData['subcategory'].toString().trim().isEmpty
              ? 'Sub Category ${ConstantString.naLabel}'
              : widget.userData['subcategory'].toString();

          String enqText = widget.userData['enq_text'] ?? "No details provided";

          return Column(
            children: [
              /// ── HEADER CARD ──
              GestureDetector(
                onTap: () => _showFullMessageDialog(enqText),
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  decoration: BoxDecoration(
                    color: const Color(0xffEBF1FF),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      )
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      children: [
                        /// Top curved blue background
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: 90,
                          child: CustomPaint(
                            painter: _TopArcPainter(),
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 20.0),
                          child: Column(
                            children: [
                              /// Avatar
                              Container(
                                height: 64,
                                width: 64,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  border: Border.all(
                                      color: const Color(0xffE2EAFB), width: 3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    )
                                  ],
                                ),
                                child: ClipOval(
                                  child: AppImageAsset(
                                    image:
                                        "${ConstantString.userImgUrlPath}${widget.userData['photo']}",
                                    isFile: false,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              /// Name
                              Text(
                                name,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xff0F172A),
                                ),
                              ),
                              const SizedBox(height: 4),

                              /// Category
                              Text(
                                "$category ($subCategory)",
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xff475569),
                                ),
                              ),
                              const SizedBox(height: 8),

                              /// Enquiry Text (Clickable)
                              GestureDetector(
                                onTap: () => _showFullMessageDialog(enqText),
                                child: Text(
                                  enqText,
                                  maxLines: 2,
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xff64748B),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              /// Date
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.calendar_today_outlined,
                                    size: 14,
                                    color: Color(0xff64748B),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    DateFormat('dd MMM yyyy').format(
                                        DateTime.parse(widget
                                                .userData['created_at']
                                                ?.toString() ??
                                            DateTime.now().toString())),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xff64748B),
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),

              /// ── CHAT LIST ──
              Expanded(
                child: ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  controller: chatReceivedController.scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemBuilder: (context, index) {
                    final chatItem = messages[messages.length - 1 - index];
                    final isMe = chatItem['user_id']?.toString() ==
                        chatReceivedController.userId.value;
                    final isOptimistic = chatItem['is_optimistic'] == true;
                    return chatBubbles(context, isMe, chatItem,
                        isOptimistic: isOptimistic);
                  },
                ),
              ),

              /// ── CHAT INPUT AREA ──
              if (widget.isChat)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextFormField(
                            controller: chatReceivedController.charController,
                            focusNode: _focusNode,
                            onChanged: (value) {
                              chatReceivedController.updateMessage(value);
                            },
                            textInputAction: TextInputAction.send,
                            onFieldSubmitted: (_) {
                              if (chatReceivedController
                                  .getMessage()
                                  .isNotEmpty) {
                                chatReceivedController.postSendChatApi(
                                    Map<String, dynamic>.from(widget.userData));
                              }
                            },
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color(0xff0F172A),
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 20),
                              hintText: "Type your message...",
                              hintStyle: const TextStyle(
                                fontSize: 14,
                                color: Color(0xff94A3B8),
                                fontWeight: FontWeight.w400,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30.0),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      /// Circular Send Button
                      GestureDetector(
                        onTap: () {
                          if (chatReceivedController.getMessage().isEmpty) {
                            ShowToast.showToast(
                              'Please Enter Message',
                              showSuccess: false,
                            );
                          } else {
                            chatReceivedController.postSendChatApi(
                                Map<String, dynamic>.from(widget.userData));
                          }
                        },
                        child: Container(
                          height: 48,
                          width: 48,
                          decoration: const BoxDecoration(
                            color: Color(0xff1E40AF), // Dark blue from image
                            shape: BoxShape.circle,
                          ),
                          child: Obx(
                            () => chatReceivedController.isSending.value
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
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget chatBubbles(
      BuildContext context, bool isMe, Map<String, dynamic> chatItem,
      {bool isOptimistic = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints:
                BoxConstraints(maxWidth: Responsive.width(70, context)),
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            decoration: BoxDecoration(
              color: isMe
                  ? const Color(0xffDDE8FF) // Sender blue tint
                  : Colors.white, // Receiver white
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16.0),
                topRight: const Radius.circular(16.0),
                bottomLeft: Radius.circular(isMe ? 16.0 : 4.0),
                bottomRight: Radius.circular(isMe ? 4.0 : 16.0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isOptimistic && isMe) ...[
                  SizedBox(
                    height: 12,
                    width: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: ConstantColor.primary.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    chatItem['text'] ?? "",
                    style: const TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                      color: Color(0xff1E293B),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: isOptimistic
                ? Text(
                    "Sending...",
                    style: TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 10,
                      color: ConstantColor.grayColor.withOpacity(0.7),
                      fontStyle: FontStyle.italic,
                    ),
                  )
                : Text(
                    DateFormat('hh:mm a')
                        .format(_parseLocalTime(chatItem['created_at'])),
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 10,
                      color: Color(0xff94A3B8),
                    ),
                  ),
          )
        ],
      ),
    );
  }

  DateTime _parseLocalTime(dynamic createdAt) {
    if (createdAt == null || createdAt.toString().isEmpty) {
      return DateTime.now();
    }
    try {
      String dateStr = createdAt.toString();
      if (!dateStr.endsWith('Z') && !dateStr.contains('+')) {
        String formattedStr = dateStr.replaceAll(' ', 'T');
        if (!formattedStr.endsWith('Z')) {
          formattedStr = '${formattedStr}Z';
        }
        return DateTime.parse(formattedStr).toLocal();
      }
      return DateTime.parse(dateStr).toLocal();
    } catch (_) {
      try {
        return DateTime.parse(createdAt.toString()).toLocal();
      } catch (_) {
        return DateTime.now();
      }
    }
  }
}

class Responsive {
  static double width(double size, BuildContext context) {
    return MediaQuery.of(context).size.width * (size / 100);
  }

  static double height(double size, BuildContext context) {
    return MediaQuery.of(context).size.height * (size / 100);
  }
}

/// Custom painter for the gentle curved arc at the top of the header card
class _TopArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    path.moveTo(0, size.height * 0.7);
    path.quadraticBezierTo(size.width * 0.5, 0, size.width, size.height * 0.7);
    path.lineTo(size.width, 0);
    path.lineTo(0, 0);
    path.close();

    canvas.drawPath(
        path, Paint()..color = const Color.fromARGB(255, 255, 255, 255));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
