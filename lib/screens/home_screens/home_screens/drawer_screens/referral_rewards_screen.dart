import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:single_clik/constants/constant_color.dart';
import 'package:single_clik/constants/show_toast.dart';
import 'package:single_clik/controller/home_controller/home_controller.dart';
import 'package:single_clik/controller/home_controller/referral_controller.dart';

class ReferralRewardsScreen extends StatefulWidget {
  const ReferralRewardsScreen({super.key});

  @override
  State<ReferralRewardsScreen> createState() => _ReferralRewardsScreenState();
}

class _ReferralRewardsScreenState extends State<ReferralRewardsScreen>
    with SingleTickerProviderStateMixin {
  late ReferralController referralController;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    if (Get.isRegistered<ReferralController>()) {
      referralController = Get.find<ReferralController>();
      referralController.fetchReferralData();
    } else {
      referralController = Get.put(ReferralController());
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xffF8F9FD),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => await referralController.fetchReferralData(),
          color: ConstantColor.primary,
          child: Column(
            children: [
              _buildTopAppBar(context),
              Expanded(
                child: Obx(() {
                  if (referralController.isLoading.value) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: ConstantColor.primary,
                      ),
                    );
                  }
                  return Column(
                    children: [
                      _buildHeroCard(height, width),
                      const SizedBox(height: 12),
                      _buildTabBar(),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildProductsTab(height, width),
                            _buildReferralHistoryTab(),
                            _buildClaimHistoryTab(),
                          ],
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Top App Bar ─────────────────────────────────────────────────────────────

  Widget _buildTopAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ConstantColor.primary.withOpacity(0.08),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: ConstantColor.primary,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Text(
            "Referral & Rewards",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: ConstantColor.blackColor,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => referralController.fetchReferralData(),
            icon: Icon(
              Icons.refresh_rounded,
              color: ConstantColor.primary,
            ),
            tooltip: "Refresh",
          ),
        ],
      ),
    );
  }

  // ── Referral Code & Share Helpers ──────────────────────────────────────────

  String _getReferralCode() {
    String code = referralController.userReferralCode.value.trim();
    if ((code.isEmpty || code == 'N/A') && Get.isRegistered<HomeController>()) {
      final hcCode = Get.find<HomeController>().userData['referral_code']?.toString().trim() ?? '';
      if (hcCode.isNotEmpty && hcCode.toLowerCase() != 'null') {
        code = hcCode;
      }
    }
    return code;
  }

  void _shareReferralCode({String? productName, int? neededBusinesses, int? neededUsers}) {
    final code = _getReferralCode();
    final String shareMessage;

    if (productName != null && productName.isNotEmpty) {
      shareMessage =
          "🌟 *Single Clik Referral & Rewards* 🌟\n\n"
          "Help me unlock *$productName* on Single Clik!\n\n"
          "${code.isNotEmpty && code != 'N/A' ? 'Use my Referral Code: *$code*\n\n' : ''}"
          "🎁 *Earn reward points for every referral:*\n"
          "💼 Business Referral: *1,000 Points*\n"
          "👤 User Referral: *500 Points*\n\n"
          "📲 Download & Register now:\nhttps://singleclik.com/app\n\n"
          "${code.isNotEmpty && code != 'N/A' ? 'Enter Referral Code: *$code* during signup! 🚀' : 'Start earning rewards today! 🚀'}";
    } else {
      shareMessage =
          "🌟 *Join Single Clik & Earn Rewards!* 🌟\n\n"
          "${code.isNotEmpty && code != 'N/A' ? 'Use my Referral Code: *$code* to get instant rewards!\n\n' : ''}"
          "🎁 *Earn points on every referral:*\n"
          "💼 Business Referral: *1,000 Points*\n"
          "👤 User Referral: *500 Points*\n\n"
          "📲 Download & Register now:\nhttps://singleclik.com/app\n\n"
          "${code.isNotEmpty && code != 'N/A' ? 'Don\'t forget to enter code: *$code*! 🚀' : 'Start earning rewards today! 🚀'}";
    }

    Share.share(shareMessage);
  }

  // ── Points & Referral Code Hero Card ──────────────────────────────────────

  Widget _buildHeroCard(double height, double width) {
    final availablePts = referralController.availablePoints;
    final code = _getReferralCode();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ConstantColor.primary,
            ConstantColor.primaryDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: ConstantColor.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Points Balance Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Available Balance Points",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.stars_rounded,
                        color: Color(0xffFFD700),
                        size: 32,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatNumber(availablePts),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        "Pts",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_rounded, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      "Earned: ${_formatNumber(int.tryParse(referralController.totalPoints.value) ?? 0)}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 16),

          // Referral Code Section
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Your Referral Code",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white30, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            code.isNotEmpty ? code : "N/A",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                          if (code.isNotEmpty) ...[
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: code));
                                ShowToast.showToast("Referral code copied!", showSuccess: true);
                              },
                              child: const Icon(
                                Icons.copy_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _shareReferralCode(),
                icon: const Icon(Icons.share_rounded, size: 18),
                label: const Text("Share Code"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: ConstantColor.primaryDark,
                  elevation: 4,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Custom Tab Bar ──────────────────────────────────────────────────────────

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: ConstantColor.primary,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.label,
        labelColor: ConstantColor.primary,
        unselectedLabelColor: Colors.grey[600],
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.normal),
        tabs: [
          Tab(
            text: "Claim Rewards (${referralController.products.length})",
          ),
          Tab(
            text: "History (${referralController.historyPoints.length})",
          ),
          Tab(
            text: "Claimed (${referralController.claimHistory.length})",
          ),
        ],
      ),
    );
  }

  // ── Tab 1: Products List ────────────────────────────────────────────────────

  Widget _buildProductsTab(double height, double width) {
    final products = referralController.products;
    if (products.isEmpty) {
      return _buildEmptyState("No reward products available at the moment.");
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        final prodName = product['refferal_products']?.toString() ?? 'Reward Product';
        final prodDesc = product['refferal_products_description']?.toString() ?? '';
        final prodPointsStr = product['refferal_products_points']?.toString() ?? '0';
        final prodPoints = int.tryParse(prodPointsStr) ?? 0;
        final prodImage = product['refferal_products_image']?.toString() ?? '';
        final fullImageUrl = "${referralController.imageUrl.value}$prodImage";

        final availablePts = referralController.availablePoints;
        final bool canClaim = availablePts >= prodPoints;
        final int neededPts = prodPoints - availablePts;
        final int neededBusinesses = (neededPts > 0) ? (neededPts / 1000).ceil() : 0;
        final int neededUsers = (neededPts > 0) ? (neededPts / 500).ceil() : 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: canClaim
                  ? ConstantColor.primary.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.15),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Left Side (Name, Points, Description) | Right Side (Complete Image)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Side
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          prodName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: ConstantColor.blackColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: ConstantColor.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.stars_rounded, color: Color(0xffFFB800), size: 16),
                              const SizedBox(width: 4),
                              Text(
                                "${_formatNumber(prodPoints)} Pts",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: ConstantColor.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (prodDesc.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            prodDesc,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                              height: 1.3,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Right Side: Complete Image (Adaptive Rectangle/Square, without fixed cropping)
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 125,
                      maxHeight: 110,
                      minWidth: 70,
                      minHeight: 60,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        color: const Color(0xffF4F6F9),
                        child: Image.network(
                          fullImageUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 80,
                            height: 80,
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.card_giftcard_rounded,
                              size: 36,
                              color: ConstantColor.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Bottom Action: Claim Now or Share to Refer
              if (canClaim)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: referralController.isClaiming.value
                        ? null
                        : () => _showConfirmClaimDialog(product, prodPoints, availablePts),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ConstantColor.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      "Claim Now",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
              else
                InkWell(
                  onTap: () => _shareReferralCode(
                    productName: prodName,
                    neededBusinesses: neededBusinesses,
                    neededUsers: neededUsers,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xffFFF3E0),
                          Color(0xffFFE0B2),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xffFFB74D),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.08),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: const Color(0xffE65100).withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.share_rounded,
                            color: Color(0xffE65100),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: TextSpan(
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xffBF360C),
                                    fontWeight: FontWeight.w600,
                                  ),
                                  children: [
                                    const TextSpan(text: "Refer "),
                                    TextSpan(
                                      text: "$neededBusinesses Business${neededBusinesses > 1 ? 'es' : ''}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xffD84315),
                                      ),
                                    ),
                                    const TextSpan(text: " or "),
                                    TextSpan(
                                      text: "$neededUsers User${neededUsers > 1 ? 's' : ''}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xffD84315),
                                      ),
                                    ),
                                    const TextSpan(text: " to claim this!"),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Text(
                                    "Need ${_formatNumber(neededPts)} more pts",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    "• Tap to share & invite ↗",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xffE65100),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: Color(0xffE65100),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ── Tab 2: Referral History Tab ─────────────────────────────────────────────

  Widget _buildReferralHistoryTab() {
    final history = referralController.historyPoints;
    if (history.isEmpty) {
      return _buildEmptyState("No referral history found.\nShare your referral code to start earning points!");
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final item = history[index];
        final referredUser = item['referred_user'];
        String name = "Referred User";
        if (referredUser is Map && referredUser['name'] != null) {
          name = referredUser['name'].toString();
        }
        final points = item['refferal_point']?.toString() ?? '0';
        final date = item['refferal_point_date']?.toString() ?? '';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ConstantColor.primary.withOpacity(0.1),
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'U',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: ConstantColor.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: ConstantColor.blackColor,
                      ),
                    ),
                    if (date.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        date,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "+${_formatNumber(int.tryParse(points) ?? 0)} Pts",
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Tab 3: Claim History Tab ────────────────────────────────────────────────

  Widget _buildClaimHistoryTab() {
    final claims = referralController.claimHistory;
    if (claims.isEmpty) {
      return _buildEmptyState("No rewards claimed yet.\nClaim your first item from the Rewards tab!");
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: claims.length,
      itemBuilder: (context, index) {
        final item = claims[index];
        final claimProducts = item['claim_products'];
        String prodName = "Claimed Product";
        String prodImg = "";

        if (claimProducts is Map) {
          prodName = claimProducts['refferal_products']?.toString() ?? prodName;
          prodImg = claimProducts['refferal_products_image']?.toString() ?? '';
        }

        final points = item['refferal_claim_point']?.toString() ?? '0';
        final date = item['refferal_claim_created_date']?.toString() ?? '';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  height: 50,
                  width: 50,
                  color: const Color(0xffF4F6F9),
                  child: prodImg.isNotEmpty
                      ? Image.network(
                          "${referralController.imageUrl.value}$prodImg",
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.card_giftcard_rounded,
                            color: ConstantColor.primary,
                          ),
                        )
                      : Icon(
                          Icons.card_giftcard_rounded,
                          color: ConstantColor.primary,
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prodName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: ConstantColor.blackColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (date.isNotEmpty)
                          Text(
                            date,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            "Claimed",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                "-${_formatNumber(int.tryParse(points) ?? 0)} Pts",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xffE65100),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Confirmation Dialog for Claim ──────────────────────────────────────────

  void _showConfirmClaimDialog(Map<String, dynamic> product, int prodPoints, int availablePts) {
    final prodName = product['refferal_products']?.toString() ?? 'Reward Item';
    final prodImg = product['refferal_products_image']?.toString() ?? '';
    final fullImageUrl = "${referralController.imageUrl.value}$prodImg";

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.all(20),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  color: ConstantColor.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    fullImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.card_giftcard_rounded,
                      size: 40,
                      color: ConstantColor.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Confirm Reward Claim",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Are you sure you want to claim \"$prodName\" using ${_formatNumber(prodPoints)} points?",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.4),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xffF4F6F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Remaining Points:", style: TextStyle(fontSize: 13, color: Colors.grey)),
                    Text(
                      "${_formatNumber(availablePts - prodPoints)} Pts",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: ConstantColor.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text("Cancel"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Get.back();
                        final isSuccess = await referralController.postCreateReferralClaimApi(product['id']);
                        if (isSuccess && mounted) {
                          _showSuccessClaimDialog(product, prodPoints);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ConstantColor.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text("Confirm"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Success Dialog after Claiming Reward ───────────────────────────────────

  void _showSuccessClaimDialog(Map<String, dynamic> product, int prodPoints) {
    final prodName = product['refferal_products']?.toString() ?? 'Reward Item';
    final prodImg = product['refferal_products_image']?.toString() ?? '';
    final fullImageUrl = "${referralController.imageUrl.value}$prodImg";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 10,
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Success Icon with Badge Effect
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xff4CAF50).withOpacity(0.15),
                        const Color(0xff81C784).withOpacity(0.08),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xff4CAF50),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Title
                const Text(
                  "Claim Request Placed!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 10),

                // Professional Explanation Text
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                    children: [
                      const TextSpan(
                        text: "Your request for ",
                      ),
                      TextSpan(
                        text: "\"$prodName\"",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const TextSpan(
                        text: " has been successfully submitted. Our team will verify your claim and contact you shortly regarding fulfillment and delivery.",
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Product Preview Card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xffF8F9FD),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xffE8ECF4), width: 1),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          height: 52,
                          width: 52,
                          color: Colors.white,
                          child: prodImg.isNotEmpty
                              ? Image.network(
                                  fullImageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Icon(
                                    Icons.card_giftcard_rounded,
                                    color: ConstantColor.primary,
                                  ),
                                )
                              : Icon(
                                  Icons.card_giftcard_rounded,
                                  color: ConstantColor.primary,
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              prodName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Redeemed with ${_formatNumber(prodPoints)} Pts",
                              style: TextStyle(
                                fontSize: 12,
                                color: ConstantColor.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xffE8F5E9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          "Processing",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff2E7D32),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Get.back(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                        child: Text(
                          "Done",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Get.back();
                          _tabController.animateTo(2); // Switch to "Claimed" tab
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ConstantColor.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          "View Claimed",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Reusable Empty State Widget ─────────────────────────────────────────────

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.card_giftcard_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helper: Format Numbers ──────────────────────────────────────────────────

  String _formatNumber(int number) {
    final str = number.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(str[i]);
    }
    return buffer.toString();
  }
}
