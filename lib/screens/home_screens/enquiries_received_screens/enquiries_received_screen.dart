import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:single_clik/constants/constant_color.dart';
import 'package:single_clik/constants/constant_string.dart';
import 'package:single_clik/controller/home_controller/enquiries_received_controller.dart';
import 'package:single_clik/controller/home_controller/home_controller.dart';
import 'package:single_clik/screens/home_screens/enquiries_received_screens/chat_received_screen.dart';
import 'package:single_clik/widget/app_image_assets.dart';

class EnquiriesReceivedScreen extends StatefulWidget {
  const EnquiriesReceivedScreen({super.key});

  @override
  State<EnquiriesReceivedScreen> createState() =>
      EnquiriesReceivedScreenState();
}

class EnquiriesReceivedScreenState extends State<EnquiriesReceivedScreen> {
  EnquiriesReceivedController enquiriesReceivedController =
      Get.put(EnquiriesReceivedController());
  HomeController homeController = Get.put(HomeController());

  @override
  void initState() {
    super.initState();
    // Mark received enquiries as seen when screen opens
    enquiriesReceivedController.markOpenEnquiriesAsSeen();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (enquiriesReceivedController.tabController.index == 0) {
        getData('1');
      } else {
        getData('2');
      }
    });
  }

  Future<void> getData(String status) async {
    await enquiriesReceivedController.postReceivedApi(status);
    await homeController.getSentEnquiriesUnreadCount("1");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xffF8FAFC), // Lighter background to match UI
      body: Obx(
        () => enquiriesReceivedController.isLoading.value
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : Column(
                children: [
                  // Real-time new enquiry notification banner
                  Obx(() {
                    final newCount =
                        enquiriesReceivedController.newOpenCount.value;
                    if (newCount <= 0) return const SizedBox.shrink();
                    return GestureDetector(
                      onTap: () {
                        enquiriesReceivedController.markOpenEnquiriesAsSeen();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 16),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF00C853), Color(0xFF00897B)],
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.notifications_active,
                                color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              '$newCount new ${newCount == 1 ? 'enquiry' : 'enquiries'} received! Tap to dismiss',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  Expanded(
                    child: TabBarView(
                      controller: enquiriesReceivedController.tabController,
                      children: [
                        /// ── OPEN TAB ──
                        RefreshIndicator(
                          onRefresh: () async {
                            await enquiriesReceivedController
                                .postReceivedApi("1");
                            await homeController
                                .getSentEnquiriesUnreadCount("1");
                          },
                          backgroundColor: ConstantColor.whiteColor,
                          color: ConstantColor.primary,
                          child: enquiriesReceivedController
                                  .openReceivedList.isEmpty
                              ? _buildEmptyState()
                              : ListView.builder(
                                  padding:
                                      const EdgeInsets.only(top: 8, bottom: 20),
                                  itemCount: enquiriesReceivedController
                                      .openReceivedList.length,
                                  itemBuilder: (context, index) {
                                    final itemData = enquiriesReceivedController
                                        .openReceivedList[index];
                                    return _buildEnquiryCard(
                                      itemData: itemData,
                                      isOpen: true,
                                      onTap: () async {
                                        await Get.to(
                                          () => ChatReceivedScreen(
                                              userData: itemData, isChat: true),
                                          arguments: itemData,
                                        )?.then((value) async {
                                          await enquiriesReceivedController
                                              .postReceivedApi("1");
                                          await homeController
                                              .getSentEnquiriesUnreadCount("1");
                                        });
                                      },
                                    );
                                  },
                                ),
                        ),

                        /// ── CLOSED TAB ──
                        RefreshIndicator(
                          onRefresh: () async {
                            await enquiriesReceivedController
                                .postReceivedApi("2");
                            await homeController
                                .getSentEnquiriesUnreadCount("1");
                          },
                          backgroundColor: ConstantColor.whiteColor,
                          color: ConstantColor.primary,
                          child: enquiriesReceivedController
                                  .closeReceivedList.isEmpty
                              ? _buildEmptyState()
                              : ListView.builder(
                                  padding:
                                      const EdgeInsets.only(top: 8, bottom: 20),
                                  itemCount: enquiriesReceivedController
                                      .closeReceivedList.length,
                                  itemBuilder: (context, index) {
                                    final itemData = enquiriesReceivedController
                                        .closeReceivedList[index];
                                    return _buildEnquiryCard(
                                      itemData: itemData,
                                      isOpen: false,
                                      onTap: () async {
                                        await Get.to(
                                          () => ChatReceivedScreen(
                                              userData: itemData,
                                              isChat: false),
                                          arguments: itemData,
                                        )?.then((value) async {
                                          await enquiriesReceivedController
                                              .postReceivedApi("2");
                                          await homeController
                                              .getSentEnquiriesUnreadCount("1");
                                        });
                                      },
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
  }) {
    // Formatting variables
    String name =
        itemData['name'] == null || itemData['name'].toString().trim().isEmpty
            ? 'Name ${ConstantString.naLabel}'
            : itemData['name'].toString();

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

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
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
                            border: Border.all(
                              color: const Color(0xffA8C0F0),
                              width: 1.5,
                            ),
                          ),
                          child: ClipOval(
                            child: AppImageAsset(
                              image:
                                  "${ConstantString.userImgUrlPath}${itemData['photo']}",
                              isFile: false,
                              fit: BoxFit.cover,
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
                                name,
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
                                "$category ($subCategory)",
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

                        /// Status Badge & Unread Logic
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
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
                            if (unreadCount > 0) ...[
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
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                const Color(0xff4F86FF), // Light Blue
                                const Color(0xff0B3C9B), // Primary Blue
                              ],
                            ), //
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

/// Custom painter for the double-layered blue waves at the bottom of the card
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
