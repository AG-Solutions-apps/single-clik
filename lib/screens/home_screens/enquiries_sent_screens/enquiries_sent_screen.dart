import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:single_clik/constants/constant_color.dart';
import 'package:single_clik/constants/constant_string.dart';
import 'package:single_clik/controller/home_controller/enquiries_sent_controller.dart';
import 'package:single_clik/controller/home_controller/home_controller.dart';
import 'package:single_clik/screens/home_screens/enquiries_sent_screens/enquiries_sent_group_screen.dart';
import '../../../widget/dialogs.dart';
import '../../../widget/app_image_assets.dart';

class EnquiriesSentScreen extends StatefulWidget {
  const EnquiriesSentScreen({super.key});

  @override
  State<EnquiriesSentScreen> createState() => EnquiriesSentScreenState();
}

class EnquiriesSentScreenState extends State<EnquiriesSentScreen> {
  EnquiriesSentController enquiriesSentController =
      Get.put(EnquiriesSentController());
  HomeController homeController = Get.put(HomeController());

  Timer? _autoRefreshTimer;
  String _currentStatus = "1";
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();

    // Start auto-refresh timer
    _startAutoRefresh();

    // Listen to tab changes
    enquiriesSentController.tabController.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    if (!enquiriesSentController.tabController.indexIsChanging) {
      if (enquiriesSentController.tabController.index == 0) {
        _currentStatus = "1";
      } else {
        _currentStatus = "2";
      }
    }
  }

  void _startAutoRefresh() {
    // Auto-refresh every 3 seconds
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted &&
          !_isRefreshing &&
          !enquiriesSentController.isAutoRefreshing.value) {
        _autoRefreshData();
      }
    });
  }

  Future<void> _autoRefreshData() async {
    if (_isRefreshing) return;

    _isRefreshing = true;
    try {
      // Silently refresh both tabs data
      await Future.wait([
        enquiriesSentController.postSentApi("1", isAutoRefresh: true),
        enquiriesSentController.postSentApi("2", isAutoRefresh: true),
      ]);

      // Update home controller unread count
      await homeController.getSentEnquiriesUnreadCount("1");
    } catch (e) {
      debugPrint('Auto-refresh error: $e');
    } finally {
      _isRefreshing = false;
    }
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    enquiriesSentController.tabController.removeListener(_handleTabChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC), // Matches the new UI background
      body: Obx(
        () => (enquiriesSentController.isLoading.value &&
                enquiriesSentController.openSentList.isEmpty &&
                enquiriesSentController.closeSentList.isEmpty)
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : Stack(
                children: [
                  TabBarView(
                    controller: enquiriesSentController.tabController,
                    children: [
                      _buildOpenTab(),
                      _buildClosedTab(),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildOpenTab() {
    return RefreshIndicator(
      onRefresh: () async {
        await enquiriesSentController.postSentApi("1", isAutoRefresh: false);
        await homeController.getSentEnquiriesUnreadCount("1");
      },
      backgroundColor: ConstantColor.whiteColor,
      color: ConstantColor.primary,
      child: enquiriesSentController.openSentList.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 20),
              itemCount: enquiriesSentController.openSentList.length,
              shrinkWrap: true,
              itemBuilder: (context, index) {
                final enquiry = enquiriesSentController.openSentList[index];

                return _buildEnquiryCard(
                  itemData: enquiry,
                  isOpen: true,
                  onClose: () {
                    Dialogs.dialogs.areYouSureAlertDialog(
                      context: context,
                      title: 'Close Enquiry?',
                      description: 'Do you want to close this enquiry?',
                      onPressed: () async {
                        Get.back();
                        await enquiriesSentController
                            .postCloseSentApi(enquiry['id'].toString());
                      },
                    );
                  },
                  onTap: () async {
                    await Get.to(
                      () => EnquiriesSentGroupScreen(
                        userData: enquiry,
                        isChat: true,
                      ),
                      arguments: {
                        'enquiryId': enquiry['id'].toString(),
                        'user_id': enquiry['user_id']?.toString() ?? '',
                      },
                    )?.then((value) async {
                      // Refresh data when coming back
                      await enquiriesSentController.postSentApi("1",
                          isAutoRefresh: false);
                      await homeController.getSentEnquiriesUnreadCount("1");
                    });
                  },
                );
              },
            ),
    );
  }

  Widget _buildClosedTab() {
    return RefreshIndicator(
      onRefresh: () async {
        await enquiriesSentController.postSentApi("2", isAutoRefresh: false);
      },
      backgroundColor: ConstantColor.whiteColor,
      color: ConstantColor.primary,
      child: enquiriesSentController.closeSentList.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 20),
              itemCount: enquiriesSentController.closeSentList.length,
              shrinkWrap: true,
              itemBuilder: (context, index) {
                final enquiry = enquiriesSentController.closeSentList[index];

                return _buildEnquiryCard(
                  itemData: enquiry,
                  isOpen: false,
                  onTap: () async {
                    await Get.to(
                      () => EnquiriesSentGroupScreen(
                        userData: enquiry,
                        isChat: false,
                      ),
                      arguments: {
                        'enquiryId': enquiry['id'].toString(),
                        'user_id': enquiry['user_id']?.toString() ?? '',
                      },
                    )?.then((value) async {
                      await enquiriesSentController.postSentApi("2",
                          isAutoRefresh: false);
                    });
                  },
                );
              },
            ),
    );
  }

  /// Reusable empty state logic
  Widget _buildEmptyState() {
    return ListView(
      children: [
        SizedBox(height: Get.height / 2.8),
        Center(
          child: Text(
            ConstantString.dataNotFoundLabel,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ConstantColor.blackColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  /// ── THE NEW UI CARD DESIGN ──
  Widget _buildEnquiryCard({
    required Map<dynamic, dynamic> itemData,
    required bool isOpen,
    required VoidCallback onTap,
    VoidCallback? onClose, // Optional close button for open enquiries
  }) {
    // Formatting variables
    String category = itemData['category'] == null ||
            itemData['category'].toString().trim().isEmpty
        ? 'Category ${ConstantString.naLabel}'
        : itemData['category'].toString();

    String subCategory = itemData['subcategory'] == null ||
            itemData['subcategory'].toString().trim().isEmpty
        ? 'Sub Category ${ConstantString.naLabel}'
        : itemData['subcategory'].toString();

    String desc = itemData['enq_text'] ?? "No description provided";

    String formattedDate = "";
    try {
      formattedDate = DateFormat('dd MMM yyyy')
          .format(DateTime.parse(itemData['created_at'].toString()));
    } catch (e) {
      formattedDate = DateFormat('dd MMM yyyy').format(DateTime.now());
    }

    int unreadCount =
        int.tryParse(itemData['unread_reply_count'].toString()) ?? 0;
    bool hasUnread = unreadCount > 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: hasUnread
              ? Border.all(
                  color: ConstantColor.primary.withOpacity(0.5), width: 1.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              /// ── Bottom Wave Decoration ──
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 120,
                child: CustomPaint(
                  painter: _BottomWavePainter(),
                ),
              ),

              /// ── Card Content ──
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// Avatar
                        Container(
                          height: 52,
                          width: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(
                              color: const Color(0xffA8C0F0),
                              width: 1.5,
                            ),
                          ),
                          child: ClipOval(
                            child: itemData['photo'] != null &&
                                    itemData['photo'].toString().isNotEmpty
                                ? AppImageAsset(
                                    image:
                                        "${ConstantString.userImgUrlPath}${itemData['photo']}",
                                    isFile: false,
                                    fit: BoxFit.cover,
                                  )
                                : const Center(
                                    child: Icon(
                                      Icons.assignment_outlined,
                                      color: Color(0xffA8C0F0),
                                      size: 24,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        /// Main Texts
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                category,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xff0F172A),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                subCategory,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xff64748B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                desc,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xff94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        /// Status Badge, Close Button & Unread Logic
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                /// Close 'X' Button (Only if open)
                                if (isOpen && onClose != null)
                                  GestureDetector(
                                    onTap: onClose,
                                    child: Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        size: 16,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ),

                                /// Open/Closed Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isOpen
                                        ? const Color(0xffE8F5E9)
                                        : const Color(0xffF1F5F9),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    isOpen ? "Open" : "Closed",
                                    style: TextStyle(
                                      color: isOpen
                                          ? const Color(0xff2E7D32)
                                          : const Color(0xff64748B),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            /// Unread Badge Indicator
                            if (hasUnread) ...[
                              const SizedBox(height: 6),
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
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            ]
                          ],
                        )
                      ],
                    ),
                    const SizedBox(height: 24),

                    /// Bottom Row (Date & Button)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
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

                        /// View Details Button
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0xff4F86FF), // Light Blue
                                Color(0xff0B3C9B), // Primary Blue
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "View Details",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: Colors.white,
                                size: 18,
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom painter for the triple-layered blue waves at the bottom of the card
class _BottomWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    /// BACK WAVE
    final path1 = Path();
    path1.moveTo(0, size.height * 0.55);

    path1.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.15,
      size.width * 0.55,
      size.height * 0.55,
    );

    path1.quadraticBezierTo(
      size.width * 0.80,
      size.height * 0.90,
      size.width,
      size.height * 0.25,
    );

    path1.lineTo(size.width, size.height);
    path1.lineTo(0, size.height);
    path1.close();

    canvas.drawPath(path1, Paint()..color = const Color(0xFFF4F7FD));

    /// MIDDLE WAVE
    final path2 = Path();
    path2.moveTo(0, size.height * 0.80);

    path2.quadraticBezierTo(
      size.width * 0.30,
      size.height * 1.00,
      size.width * 0.60,
      size.height * 0.55,
    );

    path2.quadraticBezierTo(
      size.width * 0.82,
      size.height * 0.18,
      size.width,
      size.height * 0.42,
    );

    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();

    canvas.drawPath(
      path2,
      Paint()..color = const Color(0xFFE7EEF9),
    );

    /// FRONT WAVE (RIGHT SIDE ONLY)
    final path3 = Path();

    path3.moveTo(size.width * 0.40, size.height);

    path3.quadraticBezierTo(
      size.width * 0.68,
      size.height * 0.55,
      size.width * 0.84,
      size.height * 0.32,
    );

    path3.quadraticBezierTo(
      size.width * 0.92,
      size.height * 0.20,
      size.width,
      size.height * 0.32,
    );

    path3.lineTo(size.width, size.height);
    path3.close();

    canvas.drawPath(path3, Paint()..color = const Color(0xFFDCE7F7));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
