import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:single_clik/constants/constant_color.dart';
import 'package:single_clik/constants/constant_string.dart';
import 'package:single_clik/controller/home_controller/enquiries_received_group_controller.dart';
import 'package:single_clik/controller/home_controller/home_controller.dart';
import 'package:single_clik/screens/home_screens/enquiries_sent_screens/chat_sent_screen.dart';
import 'package:single_clik/widget/app_image_assets.dart';

import '../../../controller/home_controller/enquiries_sent_controller.dart';

class EnquiriesSentGroupScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final bool isChat;

  const EnquiriesSentGroupScreen({
    super.key,
    required this.userData,
    required this.isChat,
  });

  @override
  State<EnquiriesSentGroupScreen> createState() =>
      EnquiriesSentGroupScreenState();
}

class EnquiriesSentGroupScreenState extends State<EnquiriesSentGroupScreen> {
  HomeController homeController = Get.put(HomeController());
  EnquiriesSentController enquiriesSentController =
      Get.put(EnquiriesSentController());
  EnquiriesSentGroupController enquiriesSentGroupController =
      Get.put(EnquiriesSentGroupController());

  @override
  void initState() {
    super.initState();
    enquiriesSentGroupController
        .postGroupSentApi(widget.userData['id'].toString());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC), // Matches the new light theme
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
          "My Enquiries Group",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w500,
            color: ConstantColor.whiteColor,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: Obx(
        () => enquiriesSentGroupController.isLoading.value
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : Column(
                children: [
                  /// ── HERO CARD: PARENT ENQUIRY DETAILS ──
                  _buildParentEnquiryCard(),

                  /// ── LIST OF BUSINESSES / GROUPS ──
                  Expanded(
                    child: enquiriesSentGroupController.sentGroupList.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.only(
                                top: 8, bottom: 24, left: 16, right: 16),
                            itemCount: enquiriesSentGroupController
                                .sentGroupList.length,
                            itemBuilder: (context, index) {
                              // Safely cast the dynamic map to Map<String, dynamic> here
                              final Map<String, dynamic> groupData =
                                  Map<String, dynamic>.from(
                                      enquiriesSentGroupController
                                          .sentGroupList[index] as Map);

                              return _buildGroupListItem(groupData);
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  /// Builds the top hero card containing the details of the main enquiry
  Widget _buildParentEnquiryCard() {
    String category = widget.userData['category'] == null ||
            widget.userData['category'].toString().trim().isEmpty
        ? 'Category ${ConstantString.naLabel}'
        : widget.userData['category'].toString();

    String subCategory = widget.userData['subcategory'] == null ||
            widget.userData['subcategory'].toString().trim().isEmpty
        ? 'Sub Category ${ConstantString.naLabel}'
        : widget.userData['subcategory'].toString();

    String enqText = widget.userData['enq_text']?.toString().trim() ?? "";
    String status = widget.userData['status'] ?? "Unknown";
    bool isOpen = status.toLowerCase() == 'open';

    String formattedDate = "";
    try {
      formattedDate = DateFormat('dd MMM yyyy')
          .format(DateTime.parse(widget.userData['created_at'].toString()));
    } catch (e) {
      formattedDate = DateFormat('dd MMM yyyy').format(DateTime.now());
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            /// ── Top Wave Decoration ──
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 80,
              child: CustomPaint(
                painter: _HeaderWavePainter(),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xff0B3C9B), // Primary Blue
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subCategory,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xff64748B),
                    ),
                  ),
                  if (enqText.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      enqText,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0xff475569),
                        height: 1.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xffE2E8F0), height: 1),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      /// Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isOpen
                              ? const Color(0xffE8F5E9)
                              : const Color(0xffF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: isOpen
                                ? const Color(0xff2E7D32)
                                : const Color(0xff64748B),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),

                      /// Date
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 15,
                            color: Color(0xff64748B),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            formattedDate,
                            style: const TextStyle(
                              color: Color(0xff64748B),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds individual list items (Businesses/Groups)
  /// Now strictly accepts Map<String, dynamic>
  Widget _buildGroupListItem(Map<String, dynamic> groupData) {
    int unreadCount =
        int.tryParse(groupData['unread_reply_count']?.toString() ?? "0") ?? 0;
    bool hasUnread = unreadCount > 0;

    return GestureDetector(
      onTap: () async {
        await Get.to(
          () => ChatSentScreen(userData: groupData, isChat: widget.isChat),
          arguments: groupData,
        )?.then((value) {
          enquiriesSentGroupController
              .postGroupSentApi(widget.userData['id'].toString());
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: hasUnread
              ? Border.all(
                  color:
                      const Color.fromARGB(255, 56, 245, 141).withOpacity(0.5),
                  width: 1)
              : Border.all(color: Colors.transparent, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            /// Avatar
            Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xffDDE8FF),
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: groupData['photo'] != null &&
                        groupData['photo'].toString().isNotEmpty
                    ? AppImageAsset(
                        image:
                            "${ConstantString.userImgUrlPath}${groupData['photo']}",
                        isFile: false,
                        fit: BoxFit.cover,
                      )
                    : const Center(
                        child: Icon(
                          Icons.business,
                          color: Color(0xffA8C0F0),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 14),

            /// Business Name
            Expanded(
              child: Text(
                groupData['name']?.toString() ?? "Unknown",
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff0F172A),
                ),
              ),
            ),
            const SizedBox(width: 12),

            /// Unread Badge & Chevron Button
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasUnread) ...[
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xffE53945),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],

                /// Sleek Circular Chevron Button (Matching original design)
                Container(
                  height: 36,
                  width: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xff0B3C9B),
                    size: 22,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Empty state logic
  Widget _buildEmptyState() {
    return Center(
      child: Text(
        ConstantString.dataNotFoundLabel,
        style: const TextStyle(
          color: Color(0xff64748B),
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// Custom painter for a subtle, aesthetic wave at the top of the hero card
class _HeaderWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(0, size.height * 0.8);

    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 1.1,
      size.width * 0.5,
      size.height * 0.7,
    );

    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.3,
      size.width,
      size.height * 0.6,
    );

    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(
      path,
      Paint()..color = const Color(0xffF0F4FF),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
