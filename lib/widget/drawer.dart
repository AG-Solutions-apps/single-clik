import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:single_clik/constants/constant_color.dart';
import 'package:single_clik/constants/show_toast.dart';
import 'package:single_clik/controller/home_controller/home_controller.dart';
import 'package:single_clik/controller/home_controller/profile_controller.dart';
import 'package:single_clik/screens/auth_screens/business_sign_up_page.dart';
import 'package:single_clik/screens/auth_screens/mobile_number_screen.dart';
import 'package:single_clik/screens/home_screens/home_screens/drawer_screens/about_us_screen.dart';
import 'package:single_clik/screens/home_screens/home_screens/drawer_screens/feedback_screen.dart';
import 'package:single_clik/screens/home_screens/home_screens/drawer_screens/notification_screen.dart';
import 'package:single_clik/screens/home_screens/home_screens/drawer_screens/profile_screen.dart';
import 'package:single_clik/screens/home_screens/home_screens/drawer_screens/referral_rewards_screen.dart';
import 'package:single_clik/services/api.dart';
import 'package:single_clik/utils/shar_preferences.dart';
import 'package:single_clik/utils/cache_manager.dart';
import 'package:single_clik/widget/app_image_assets.dart';
import 'package:single_clik/screens/home_tab_bar_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

import '../constants/constant_string.dart';
import '../constants/network_to_file_image.dart';
import '../controller/auth_controller/business_sign_up_controller.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => AppDrawerState();
}

class AppDrawerState extends State<AppDrawer> {
  String versionCode = "";
  HomeController homeController = Get.put(HomeController());
  ProfileController profileController = Get.put(ProfileController());
  BusinessSignUpController businessSignUpController = Get.put(BusinessSignUpController());

  @override
  void initState() {
    userDataGet();
    super.initState();
  }

  Future<void> userDataGet() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    versionCode = packageInfo.version;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    return Drawer(
      child: Stack(
        children: [

          // Background bubbles
          _buildBackgroundBubbles(height, width),
        SingleChildScrollView(
          child: Obx(
            () => Column(
              children: [
                SizedBox(height: height * 0.07),
                Padding(
  padding: const EdgeInsets.symmetric(
    horizontal: 20,
    vertical: 10,
  ),
  child: Row(
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(1000),
        child: AppImageAsset(
          key: ValueKey(
            'drawer_photo_${homeController.photoVersion.value}',
          ),
          image:
              "${ConstantString.userImgUrlPath}${homeController.userData['photo']}",
          isFile: false,
          fit: BoxFit.cover,
          height: 100,
          width: 100,
        ),
      ),

      const SizedBox(width: 15),

      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              homeController.userData['name'] ?? "",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: ConstantColor.blackColor,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              homeController.userData['mobile'] ?? "",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    ],
  ),
),
                SizedBox(height: height * 0.01),
                Divider(color: ConstantColor.blackColor, thickness: 1.2),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      drawerButton(
                        icon: "assets/icons/home_dr_icon.png",
                        title: "Home",
                        padding: 4,
                        onTap: () {
                          homeController.selectTab.value = 0;
                          Get.back();
                        },
                      ),
                      Divider(color: ConstantColor.grayColor, thickness: 1),
                      drawerButton(
                        icon: "assets/icons/profile_dr_icon.png",
                        title: "My Profile",
                        padding: 4,
                        onTap: () {
                          ProfileController profileController = Get.put(ProfileController());
                          profileController.postFetchProfileApi();
                          Get.back();
                          Get.to(() => const ProfileScreen())!
                              .then((value) => null);
                        },
                      ),
                      Divider(color: ConstantColor.grayColor, thickness: 1),
                      drawerButton(
                        icon: "assets/icons/sen.png",
                        iconColor: const Color.fromARGB(255, 0, 47, 86),
                        title: homeController.userData['user_type'] != 2
                            ? "My Enquiries"
                            : "Sent Enquiry",
                        padding: 4,
                        onTap: () {
                          homeController.selectTab.value = 2;
                          Get.back();
                        },
                      ),
                      Divider(color: ConstantColor.grayColor, thickness: 1),
                      drawerButton(
                        icon: homeController.userData['user_type'] != 2
                            ? "assets/icons/logo.svg"
                            : "assets/icons/rec.png",
                        iconColor: const Color.fromARGB(255, 0, 47, 86),
                        title: homeController.userData['user_type'] != 2
                            ? "Join as a Seller"
                            : "Received Enquiries",
                        padding: 4,
                        onTap: () async {
                          Get.back();
        
                          if (homeController.userData['user_type'] != 2) {
                            EasyLoading.show(
                              status: ConstantString.pleaseWaitLabel,
                            );
        
                            // Call new API to check business profile status
                            final checkResult = await businessSignUpController.checkProfileBusinessProfileApi();
                            EasyLoading.dismiss();
        
                            if (checkResult['status'] == true) {
                              if (context.mounted) {
                                _showAlreadySubmittedDialog(context);
                              }
                            } else {
                              if (homeController.userData['category'] != null &&
                                  homeController.userData['category']
                                      .toString()
                                      .trim()
                                      .isNotEmpty) {
                                EasyLoading.showError(
                                  ConstantString.alreadyJoinAsMsg,
                                );
                              } else {
                                EasyLoading.show(
                                  status: ConstantString.pleaseWaitLabel,
                                );
        
                                businessSignUpController.isButtonLoading.value = false;
                                businessSignUpController.txtFullName.value.clear();
                                businessSignUpController.txtCompanyName.value.clear();
                                businessSignUpController.txtMobileNo.value.clear();
                                businessSignUpController.txtEmailId.value.clear();
                                businessSignUpController.txtWhatsappNo.value.clear();
                                businessSignUpController.txtWebsite.value.clear();
                                businessSignUpController.txtAbout.value.clear();
                                businessSignUpController.txtArea.value.clear();
                                businessSignUpController.txtReferredCode.value.clear();
                                businessSignUpController.txtOtherCategory.value.clear();
                                businessSignUpController.txtOtherSubCategory.value.clear();
                                businessSignUpController.selectedProfileType.value = '';
                                businessSignUpController.selectedCategory.value = {};
                                businessSignUpController.selectedSubCategory.value = {};
                                
                                String photoPath = await NetworkToFileImage
                                    .networkToFileImage
                                    .getNetworkToFileImage(
                                    url: '${ConstantString.userImgUrlPath}${homeController.userData['photo']}');
                                businessSignUpController.filePath.value = photoPath;
                                
                                try {
                                  businessSignUpController.categoryDataList.value =
                                  await businessSignUpController.getCategoryDataApi();
                                  businessSignUpController.subCategoryDataList.value = [];
                                  EasyLoading.dismiss();
                                } on TimeoutException catch (error) {
                                  businessSignUpController.categoryDataList.value = [];
                                  businessSignUpController.subCategoryDataList.value = [];
                                  EasyLoading.dismiss();
                                  ShowToast.showToast(
                                    error.message.toString(),
                                    showSuccess: false,
                                  );
                                } on SocketException catch (error) {
                                  businessSignUpController.categoryDataList.value = [];
                                  businessSignUpController.subCategoryDataList.value = [];
                                  EasyLoading.dismiss();
                                  ShowToast.showToast(
                                    error.message.toString(),
                                    showSuccess: false,
                                  );
                                } catch (error) {
                                  businessSignUpController.categoryDataList.value = [];
                                  businessSignUpController.subCategoryDataList.value = [];
                                  debugPrint(error.toString());
                                  EasyLoading.dismiss();
                                  ShowToast.showToast(
                                    'Something went wrong.',
                                    showSuccess: false,
                                  );
                                }
                                EasyLoading.dismiss();
                                await Get.to(() => const BusinessSignUpPage());
                              }
                            }
                          } else {
                            homeController.selectTab.value = 1;
                          }
                        },
                      ),
                      Divider(color: ConstantColor.grayColor, thickness: 1),
                      drawerButton(
                        icon: "assets/icons/reward_dr_icon.png",
                        title: "Referral & Rewards",
                        padding: 4,
                        onTap: () {
                          Get.back();
                          Get.to(() => const ReferralRewardsScreen());
                        },
                      ),
                      Divider(color: ConstantColor.grayColor, thickness: 1),
                      drawerButton(
                        icon: "assets/icons/notification_dr_icon.png",
                        title: "Notification",
                        padding: 4,
                        onTap: () {
                          Get.back();
                          Get.to(() => const NotificationScreen());
                        },
                      ),
                      Divider(color: ConstantColor.grayColor, thickness: 1),
                      drawerButton(
                        icon: "assets/icons/feedback_dr_icon.png",
                        title: "Feedback",
                        padding: 4,
                        onTap: () {
                          Get.back();
                          Get.to(() => const FeedbackScreen());
                        },
                      ),
                      Divider(color: ConstantColor.grayColor, thickness: 1),
                      drawerButton(
                        icon: "assets/icons/about_us_dr_icon.png",
                        title: "About Us",
                        padding: 4,
                        onTap: () async {
                          EasyLoading.show(
                            status: ConstantString.pleaseWaitLabel,
                          );
                          try {
                            String path = await NetworkToFileImage
                                .networkToFileImage
                                .getNetworkToFileImage(
                              url: ConstantString.aboutUsBGPath,
                            );
                            profileController.aboutUsBGImgFilePath.value = path;
                          } catch (error) {
                            debugPrint('Error : $error');
                          }
                          EasyLoading.dismiss();
                          Get.back();
                          Get.to(() => const AboutUsScreen());
                        },
                      ),
                      Divider(color: ConstantColor.grayColor, thickness: 1),
                      Obx(() => InkWell(
                        onTap: homeController.isFullRefreshing.value
                            ? null
                            : () async {
                                Get.offAll(() => const HomeTabBarScreen());
                                await homeController.fullAppRefresh();
                              },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              homeController.isFullRefreshing.value
                                  ? const SizedBox(
                                      height: 25,
                                      width: 25,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Icon(
                                      Icons.refresh_rounded,
                                      size: 25,
                                      color: Color.fromARGB(255, 0, 47, 86),
                                    ),
                              const SizedBox(width: 15),
                              Text(
                                homeController.isFullRefreshing.value
                                    ? 'Refreshing...'
                                    : 'Refresh App',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: ConstantColor.primary,
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )),
                      Divider(color: ConstantColor.grayColor, thickness: 1),
                      drawerButton(
                        icon: "assets/icons/logout_dr_icon.png",
                        title: "Logout",
                        padding: 4,
                        onTap: () async {
                          areYouSureWantAlertDialog(
                            context,
                            title: 'Log out now?',
                            description: 'Are you sure you want to log out?',
                            onPressed: () async {
                              Get.back();
                              await SharPreferences.clearSharPreference();
                              await CacheManager.clearAll();
                              Get.offAll(() => const MobileNumberScreen());
                            },
                          );
                        },
                      ),
                      Divider(color: ConstantColor.grayColor, thickness: 1),
                      drawerButton(
                        iconData: Icons.group_add_rounded,
                        title: "Invite your Friends",
                        padding: 4,
                        onTap: () {
                          Get.back();
                          _showInvitationBottomSheet(context);
                        },
                      ),
                      Divider(color: ConstantColor.grayColor, thickness: 1),
                      SizedBox(height: height * 0.03),
                      Text(
                        "Version : $versionCode",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: ConstantColor.grayColor,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        ],
      ),
    );
  }

  InkWell drawerButton({
    String? icon,
    IconData? iconData,
    String? title,
    Function()? onTap,
    double? padding,
    Color? textColor,
    Color? iconColor,
  }) {
    Widget iconWidget;
    if (iconData != null) {
      iconWidget = Icon(
        iconData,
        size: 25,
        color: iconColor ?? const Color.fromARGB(255, 0, 47, 86),
      );
    } else if (icon != null && icon.contains(".svg")) {
      iconWidget = SvgPicture.asset(
        icon,
        height: 25,
        width: 25,
        colorFilter: ColorFilter.mode(
          iconColor ?? ConstantColor.primary,
          BlendMode.srcIn,
        ),
      );
    } else {
      iconWidget = Image.asset(
        icon ?? "",
        height: 25,
        width: 25,
        color: iconColor,
      );
    }

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: padding ?? 10),
        child: Row(
          children: [
            iconWidget,
            const SizedBox(width: 15),
            Flexible(
              child: Text(
                title ?? "",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: textColor ?? ConstantColor.primary,
                  height: 1.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildWhatsAppMessage(String referrerName) {
    final referLine = referrerName.isNotEmpty
        ? '👤 *Invited by:* ${referrerName.trim()}'
        : '';

    return '''
🌟 *SINGLE CLIK* 🌟
_Digital Network & Directory_

━━━━━━━━━━━━━━━━━━━━━

👋 Hey! Check out *Single Clik* — the ultimate digital network & business directory!

💼 *What is Single Clik?*
A powerful business directory where you can:
✅ Create your profile in minutes
✅ List your services & products
✅ Connect with clients instantly
✅ Get discovered locally & beyond

━━━━━━━━━━━━━━━━━━━━━
${referLine.isNotEmpty ? '$referLine\n━━━━━━━━━━━━━━━━━━━━━\n' : ''}
📲 *Join for FREE — Download Now:*
🔗 https://play.google.com/store/apps/details?id=com.singleclick.agsolution

_One tap. One profile. One click away._ ✨
''';
  }

  void _showInvitationBottomSheet(BuildContext context) {
    String referrerName = (homeController.userData['name'] ?? '').toString().trim();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 55,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'Invite to Single Clik',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: ConstantColor.blackColor,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                'Share this preview with your contacts',
                style: TextStyle(
                  fontSize: 13,
                  color: ConstantColor.grayColor,
                ),
              ),

              const SizedBox(height: 18),

              // ── Preview card ───────────────────
              _DrawerInvitePreviewCard(
                referrerName: referrerName,
              ),

              const SizedBox(height: 20),

              // ── Universal Share Button ────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Share.share(_buildWhatsAppMessage(referrerName));
                  },
                  icon: const Icon(Icons.share_rounded, color: Colors.white, size: 20),
                  label: const Text(
                    'Share Invitation',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ConstantColor.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 3,
                  ),
                ),
              ),

              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _showAlreadySubmittedDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding: EdgeInsets.symmetric(horizontal: Get.width / 15),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: ConstantColor.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.pending_actions_rounded,
                    color: ConstantColor.primary,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Request Already Submitted",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Your business account request is already submitted. Please wait for admin approval, or contact our support team for immediate assistance.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Get.back(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: Colors.grey[300]!),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(
                          "Close",
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Get.back();
                          EasyLoading.show(status: 'Loading support...');
                          try {
                            final value = await profileController.postDeveloperApi();
                            EasyLoading.dismiss();
                            if (value['code'] == 200) {
                              final phone = value['data']['company_mobile'] ?? '';
                              Uri url = Uri.parse('tel:+$phone');
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url);
                              } else {
                                ShowToast.showToast("Could not launch dialer", showSuccess: false);
                              }
                            }
                          } catch (e) {
                            EasyLoading.dismiss();
                            debugPrint(e.toString());
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ConstantColor.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text("Call Support"),
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

  void areYouSureWantAlertDialog(BuildContext context, {
    required String title,
    required String description,
    required void Function() onPressed,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          actionsPadding: EdgeInsets.symmetric(
              horizontal: Get.width * 0.02, vertical: Get.height * 0.01),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: ConstantColor.primary,
                        fontSize: Get.width * 0.05,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: Get.height * 0.015,
              ),
              Text(
                description,
                textAlign: TextAlign.start,
                style: TextStyle(
                  color: ConstantColor.blackColor,
                  fontSize: Get.width * 0.045,
                ),
              ),
            ],
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: ConstantColor.primary,
                        width: 1,
                      ),
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ConstantColor.whiteColor,
                        shadowColor: Colors.transparent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        "Cancel",
                        style: TextStyle(
                          color: ConstantColor.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: Get.width * 0.02,
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: ConstantColor.primaryGradient,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: ElevatedButton(
                      onPressed: onPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        "Confirm",
                        style: TextStyle(
                          color: ConstantColor.whiteColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _DrawerInvitePreviewCard extends StatelessWidget {
  final String referrerName;

  const _DrawerInvitePreviewCard({
    required this.referrerName,
  });

  Widget _drawerFeatureLine(String emoji, String text) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: Colors.white.withOpacity(0.85),
            fontSize: 12,
            height: 1.3,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [ConstantColor.primary, ConstantColor.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: ConstantColor.primary.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -10,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header row: brand title + FREE JOIN badge (NO IMAGE) ──
                Row(
                  children: [
                    const Text(
                      'SINGLE CLIK',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                      child: const Text(
                        'FREE JOIN',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // ── Divider ──────────────────────────────────────────────
                Container(
                  height: 1,
                  color: Colors.white.withOpacity(0.15),
                ),

                const SizedBox(height: 14),

                const Text(
                  'Join Single Clik Today!',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Digital Network & Directory for all services and products',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.85),
                    height: 1.3,
                  ),
                ),

                const SizedBox(height: 12),

                // ── Feature bullets ──────────────────────────────────────
                _drawerFeatureLine('✅', 'Create profile in minutes'),
                const SizedBox(height: 5),
                _drawerFeatureLine('✅', 'List services & connect with clients'),
                const SizedBox(height: 5),
                _drawerFeatureLine('✅', 'Get discovered locally & beyond'),

                if (referrerName.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    height: 1,
                    color: Colors.white.withOpacity(0.15),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        color: Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Invited by ',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          referrerName.trim(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Delete dialog function - moved outside AppDrawer for reuse
Future deleteDialog(BuildContext context, double height, double width) {
  return showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: ConstantColor.whiteColor,
      surfaceTintColor: ConstantColor.whiteColor,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () {
                      Get.back();
                    },
                    child: Image.asset(
                      "assets/icons/icon_close.png",
                      height: 25,
                      width: 25,
                    ),
                  )
                ],
              ),
              SizedBox(height: height * 0.02),
              Text(
                "Are you sure you want to delete your account? This will permanently erase your account.",
                style: TextStyle(
                  fontSize: Get.width * 0.04,
                  fontWeight: FontWeight.w600,
                  color: ConstantColor.blackColor,
                ),
              ),
              SizedBox(height: height * 0.03),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => postDeleteProfileApi(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        "Delete",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: Get.width * 0.04),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: ConstantColor.primary,
                          width: 1,
                        ),
                      ),
                      child: ElevatedButton(
                        onPressed: () => Get.back(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ConstantColor.whiteColor,
                          shadowColor: Colors.transparent,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          "Cancel",
                          style: TextStyle(
                            color: ConstantColor.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: height * 0.02),
            ],
          ),
        ),
      ),
    ),
  );
}

Future postDeleteProfileApi() async {
  try {
    final request = http.MultipartRequest('POST', Uri.parse(API.deleteProfile));
    request.headers.addAll({
      'Authorization': 'Bearer ${await SharPreferences.getString(SharPreferences.token)}',
    });
    var res = await request.send();
    var responseDone = await http.Response.fromStream(res);

    if (res.statusCode == 200) {
      final responseData = json.decode(responseDone.body);
      debugPrint(responseData.toString());
      if (responseData['code'] == 200) {
        await SharPreferences.clearSharPreference();
        await CacheManager.clearAll();
        Get.offAll(() => const MobileNumberScreen());
        ShowToast.showToast(
          responseData['msg'] ?? ConstantString.dataDeletedSuccessfullyMsg,
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
      e.message.toString(),
      showSuccess: false,
    );
  } on SocketException catch (e) {
    ShowToast.showToast(
      e.message.toString(),
      showSuccess: false,
    );
  } on Error catch (e) {
    ShowToast.showToast(
      ConstantString.somethingWantWrongMsg,
      showSuccess: false,
    );
    debugPrint(e.toString());
  }
}
Widget _buildBackgroundBubbles(double height, double width) {
    return Stack(
      children: [
        // Large bubble top left
        _bubble(
          left: -width * 0.2,
          top: -height * 0.1,
          size: height * 0.4,
          color: ConstantColor.primary,
          opacity: 0.08,
        ),
        // Large bubble bottom right
        _bubble(
          right: -width * 0.2,
          bottom: -height * 0.1,
          size: height * 0.35,
          color: ConstantColor.primaryDark,
          opacity: 0.08,
        ),
        // Medium warm orange bubble center-left
        _bubble(
          left: -width * 0.1,
          top: height * 0.4,
          size: height * 0.22,
          color: ConstantColor.orangeColor,
          opacity: 0.08,
        ),
        // Medium bubble top right
        _bubble(
          right: width * 0.05,
          top: height * 0.12,
          size: height * 0.15,
          color: ConstantColor.primary,
          opacity: 0.08,
        ),
        // Medium bubble bottom left
        _bubble(
          left: width * 0.05,
          bottom: height * 0.15,
          size: height * 0.12,
          color: ConstantColor.primaryDark,
          opacity: 0.08,
        ),
        // Small decorative bubble
        _bubble(
          right: width * 0.2,
          top: height * 0.35,
          size: height * 0.08,
          color: ConstantColor.primary,
          opacity: 0.08,
        ),
      ],
    );
  }

  /// Creates a soft radial bubble positioned anywhere
  Widget _bubble({
    double? left,
    double? right,
    double? top,
    double? bottom,
    required double size,
    required Color color,
    required double opacity,
  }) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(-0.3, -0.3),
            radius: 0.85,
            colors: [
              color.withOpacity(opacity),
              color.withOpacity(0.01),
            ],
          ),
        ),
      ),
    );
  }
