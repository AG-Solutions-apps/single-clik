import 'dart:async';
import 'dart:io';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:single_clik/constants/constant_color.dart';
import 'package:single_clik/constants/constant_string.dart';
import 'package:single_clik/constants/network_to_file_image.dart';
import 'package:single_clik/controller/auth_controller/business_sign_up_controller.dart';
import 'package:single_clik/controller/home_controller/profile_controller.dart';
import 'package:single_clik/controller/home_controller/home_controller.dart';
import 'package:single_clik/screens/auth_screens/business_sign_up_page.dart';
import 'package:single_clik/screens/home_screens/enquiries_received_screens/enquiries_received_screen.dart';
import 'package:single_clik/screens/home_screens/enquiries_sent_screens/enquiries_sent_screen.dart';
import 'package:single_clik/screens/home_screens/home_screens/home_screen.dart';
import 'package:single_clik/widget/drawer.dart';
import 'package:badges/badges.dart' as badges;
import 'package:url_launcher/url_launcher.dart';

import '../constants/show_toast.dart';
import '../controller/home_controller/enquiries_received_controller.dart';
import '../controller/home_controller/enquiries_sent_controller.dart';
import '../widget/app_image_assets.dart';

class HomeTabBarScreen extends StatefulWidget {
  final int? selectTab;
  
  const HomeTabBarScreen({
    super.key,
    this.selectTab = 0,
  });

  @override
  State<HomeTabBarScreen> createState() => HomeTabBarScreenState();
}

class HomeTabBarScreenState extends State<HomeTabBarScreen>
    with SingleTickerProviderStateMixin {
 late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  List homeTabBarList = [
    {"title": "Home", "image": "assets/icons/hm1.png"},
    {"title": "Received", "image": "assets/icons/rec.png"},
    {"title": "My Enquiries", "image": "assets/icons/sen.png"},
  ];

  HomeController homeController = Get.put(HomeController());
  EnquiriesReceivedController enquiriesReceivedController = Get.put(EnquiriesReceivedController());
  EnquiriesSentController enquiriesSentController = Get.put(EnquiriesSentController());

  List screenList = [
    const HomeScreen(),
    const EnquiriesReceivedScreen(),
    const EnquiriesSentScreen(),
  ];
  
  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.4,
    ).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
  
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        homeController.selectTab.value = widget.selectTab ?? 0;
      }
    });
    if (homeController.userData.isNotEmpty) {
      if (homeController.userData['user_type'] != 2) {
        homeTabBarList[1] = {
          "title": "Join as",
          "image": "assets/icons/logo (1).png"
        };
        homeTabBarList[2] = {
          "title": "My Enquiries",
          "image": "assets/icons/sen.png"
        };
      } else {
        homeTabBarList[1] = {
          "title": "Recd Enquiry",
          "image": "assets/icons/rec.png"
        };
        homeTabBarList[2] = {
          "title": "Sent Enquiry",
          "image": "assets/icons/sen.png"
        };
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        getUserData();
      }
    });
  }

  Future<void> getUserData() async {
    await homeController.postFetchProfileApi().then(
      (value) async {
        debugPrint(homeController.userData['user_type'].toString());
        if (homeController.userData['user_type'] != 2) {
          if (mounted) {
            setState(() {
              homeTabBarList[1] = {
                "title": "Join as",
                "image": "assets/icons/logo (1).png"
              };
              homeTabBarList[2] = {
                "title": "My Enquiries",
                "image": "assets/icons/sen.png"
              };
            });
          }
        } else {
          if (mounted) {
            setState(() {
              homeTabBarList[1] = {
                "title": "Recd Enquiry",
                "image": "assets/icons/rec.png"
              };
              homeTabBarList[2] = {
                "title": "Sent Enquiry",
                "image": "assets/icons/sen.png"
              };
            });
          }
        }

        debugPrint("list length${homeTabBarList.length}");

        if (homeController.selectTab.value == 0) {
          await openPopupSliderList();
          await homeController.postDashboardApi("");
          await homeController.postDashboardSliderApi("");
          await homeController.postDashboardAdvSliderApi();
          // await homeController.postBusinessDashboardApi("0");
          // await homeController.postBusinessDashboardApi("1");
          await homeController.getSentEnquiriesUnreadCount("1");
          await homeController.postCategoriesApi();
        }
      },
    );
  }
 @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }
  Future<void> openPopupSliderList() async {
    await homeController.postDashboardAdvPopUpSliderApi().then((value) {
      if (homeController.allAdvPopUpSliderList.isNotEmpty) {

        if(!mounted) return;

        showDialog(
          context: context,
          builder: (context) {
            return Dialog(
              insetPadding: EdgeInsets.symmetric(
                horizontal: Get.width / 30,
              ),
              backgroundColor: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () async {
                        Get.back();
                        await homeController.postBusinessDashboardApi("0");
                        await homeController.postBusinessDashboardApi("1");
                      },
                      child: Container(
                        height: Get.width / 12,
                        width: Get.width / 12,
                        decoration: BoxDecoration(
                          color: ConstantColor.whiteColor,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.close,
                          color: Colors.black,
                          size: Get.width / 18,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: Get.width / 30,
                  ),
                  homeController.allAdvPopUpSliderList.length == 1
                      ? SizedBox(
                          height: Get.height / 1.2,
                          child: GestureDetector(
                            onTap: () async {
                              final rawUrl = (homeController.allAdvPopUpSliderList[0]['slider_url'] ?? '').toString().trim();
                              if (rawUrl.isNotEmpty) {
                                Uri url = Uri.parse(rawUrl);
                                try {
                                  await launchUrl(url, mode: LaunchMode.externalApplication);
                                } catch (e) {
                                  ShowToast.showToast(
                                    'Could not launch URL',
                                    showSuccess: false,
                                  );
                                }
                              } else {
                                ShowToast.showToast(
                                  'Url ${ConstantString.notAvailableLabel}',
                                  showSuccess: false,
                                );
                              }
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: AppImageAsset(
                                image:
                                    "${ConstantString.sliderImgUrlPath}${homeController.allAdvPopUpSliderList[0]['slider_images']}",
                                isFile: false,
                                height: Get.height / 1.3,
                                width: Get.width / 1.1,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        )
                      : CarouselSlider(
                          options: CarouselOptions(
                            height: Get.height / 1.2,
                            autoPlay: true,
                            viewportFraction: 1,
                            enlargeCenterPage: false,
                            autoPlayInterval: const Duration(seconds: 6),
                          ),
                          items: List.generate(
                            homeController.allAdvPopUpSliderList.length,
                            (index) => GestureDetector(
                              onTap: () async {
                                final rawUrl = (homeController.allAdvPopUpSliderList[index]['slider_url'] ?? '').toString().trim();
                                if (rawUrl.isNotEmpty) {
                                  Uri url = Uri.parse(rawUrl);
                                  try {
                                    await launchUrl(url, mode: LaunchMode.externalApplication);
                                  } catch (e) {
                                    ShowToast.showToast(
                                      'Could not launch URL',
                                      showSuccess: false,
                                    );
                                  }
                                } else {
                                  ShowToast.showToast(
                                    'Url ${ConstantString.notAvailableLabel}',
                                    showSuccess: false,
                                  );
                                }
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: AppImageAsset(
                                  image:
                                      "${ConstantString.sliderImgUrlPath}${homeController.allAdvPopUpSliderList[index]['slider_images']}",
                                  isFile: false,
                                  height: Get.height / 1.3,
                                  width: Get.width / 1.1,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ),
                ],
              ),
            );
          },
        );
      }
    });
  }

  BusinessSignUpController businessSignUpController =
      Get.put(BusinessSignUpController());
  ProfileController profileController = Get.put(ProfileController());
  RxBool searchClick = true.obs;
  RxBool showText = true.obs;

  DateTime? currentBackPressTime;

  Future<bool> onWillPop() {
    DateTime now = DateTime.now();
    debugPrint('currentBackPressTime $currentBackPressTime $now');
    debugPrint('selectTab ${homeController.selectTab.value}');
    debugPrint('tabIndex ${homeController.tabIndex.value}');

    // If search is active, close search first
    if (homeController.isSearchOpen.value) {
      homeController.isSearchOpen.value = false;
      homeController.searchController.value.clear();
      homeController.searchProduct('');
      return Future.value(false);
    }

    if (homeController.selectTab.value == 0 &&
        homeController.tabIndex.value == 0) {
      homeController.searchController.value.clear();
      homeController.searchProduct('');
      if (currentBackPressTime == null ||
          now.difference(currentBackPressTime!) > const Duration(seconds: 2)) {
        currentBackPressTime = now;
        ShowToast.showToast(
          'Press back again to exit',
          position: EasyLoadingToastPosition.bottom,
        );
        return Future.value(false);
      }
    } else {
      homeController.selectTab.value = 0;
      homeController.tabController.index = 0;
      homeController.update();
      return Future.value(false);
    }

    return Future.value(true);
  }

  @override
  Widget build(BuildContext context) {
     double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final shouldPop = await onWillPop();
          if (shouldPop) {
            SystemNavigator.pop();
          }
        }
      },
      child: Scaffold(
        extendBody: true,
        key: homeController.scaffoldKey,
        backgroundColor: Colors.white,
        body: Obx(
          () => screenList[homeController.selectTab.value],
        ),
        drawer: const AppDrawer(),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight + 30),
          child: Obx(() {
            return AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  gradient: ConstantColor.primaryGradient,
                ),
              ),
              leading: GestureDetector(
                onTap: () {
                  homeController.scaffoldKey.currentState!.openDrawer();
                },
                child: Center(
                  child: Image.asset(
                    "assets/icons/icon_menu.png",
                    height: 28,
                    width: 28,
                  ),
                ),
              ),
              actions: [
                // ── Refresh button (all tabs, both user & business) ──────────────
                Obx(() {
                  final spinning = homeController.isFullRefreshing.value;
                  return Tooltip(
                    message: 'Refresh App',
                    child: IconButton(
                      icon: AnimatedRotation(
                        turns: spinning ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 800),
                        child: Icon(
                          Icons.refresh_rounded,
                          color: spinning
                              ? Colors.white54
                              : Colors.white,
                        ),
                      ),
                      onPressed: spinning
                          ? null
                          : () async {
                              await homeController.fullAppRefresh();
                            },
                    ),
                  );
                }),
                // ── Search button (home tab only) ─────────────────────────────────
                Obx(() => homeController.selectTab.value == 0 &&
                        homeController.tabIndex.value == 0 &&
                        !homeController.isLoading.value
                    ? IconButton(
                        icon: Icon(homeController.isSearchOpen.value ? Icons.close : Icons.search),
                        onPressed: () {
                          setState(() {
                            if (homeController.isSearchOpen.value) {
                              homeController.searchController.value.clear();
                              homeController.searchProduct("");
                            }
                            homeController.isSearchOpen.value = !homeController.isSearchOpen.value;
                          });
                        },
                      )
                    : Container()),
              ],
              title: Obx(
                () => homeController.selectTab.value == 0 &&
                        homeController.tabIndex.value == 0 &&
                        !homeController.isLoading.value
                    ?
                    AnimatedSwitcher(
                        duration: Duration(milliseconds: 300),
                        child: homeController.isSearchOpen.value
                            ? SizedBox(
                                height: 35,
                                child: TextField(
                                    key: ValueKey(1), // Unique key for animation
                                    controller: homeController.searchController.value,
                                    onChanged: (value) {
                                      debugPrint('value on Change : $value');
                                      homeController.searchProduct(value);
                                    },
                                    onSubmitted: (value) {
                                      debugPrint('value on Change : $value');
                                      homeController.searchProduct(value);
                                    },
                                    decoration: InputDecoration(
                                      fillColor: Colors.white,
                                      contentPadding: const EdgeInsets.symmetric(
                                          vertical: 0, horizontal: 15),
                                      hintText: "Search",
                                      hintStyle: TextStyle(
                                          fontSize: 18,
                                          color: ConstantColor.grayColor,
                                          fontWeight: FontWeight.w400),
                                      filled: true,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(100.0),
                                        borderSide: const BorderSide(
                                          color: Colors.transparent,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(100.0),
                                        borderSide: const BorderSide(
                                          color: Colors.transparent,
                                        ),
                                      ),
                                      disabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(100.0),
                                        borderSide: const BorderSide(
                                          color: Colors.transparent,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(100.0),
                                        borderSide: const BorderSide(
                                          color: Colors.transparent,
                                        ),
                                      ),
                                    ),
                                  ),
                              )
                            : Text('Single Clik',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w400,
                                  color: ConstantColor.whiteColor,
                                ),
                                key: ValueKey(2)),
                      )
                    : Text(
                        homeController.selectTab.value == 0
                            ? "Single Clik"
                            : homeController.selectTab.value == 1
                                ? "Enquiries Received"
                                : "My Enquiries",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w400,
                          color: ConstantColor.whiteColor,
                        ),
                      ),
              ),
              bottom: _buildTabBarForCurrentTab(),
            );
          }),
        ),
       bottomNavigationBar: Container(
  color: Colors.transparent, // Required for the floating gap effect
  padding: const EdgeInsets.only(left: 16, bottom: 24, right: 0),
  height: 80,
  child: Row(
    children: [
      /// ── Left Floating Pill (3 Tabs) ──
      Expanded(
        child: Container(
          decoration: BoxDecoration(
          color: Colors.white,
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Obx(
            () => Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                homeTabBarList.length,
                (index) {
                  final isSelected = homeController.selectTab.value == index;
                  
                  // Keep original logo color for 'Join as', otherwise use Red/Grey tint
                  Color? iconColor;
                  if (index == 1 && homeController.userData['user_type'] != 2) {
                    iconColor = null; 
                  } else {
                    iconColor = isSelected ? const Color.fromARGB(255, 106, 133, 231) : const Color(0xff8A95A5);
                  }

                Widget styledIcon = SizedBox(
  height: 16,
  width: 16,
  child: Image.asset(
    homeTabBarList[index]['image'],
    color: isSelected
        ? const Color(0xff0B3C9B) // Blue when selected
        : const Color(0xff8A95A5), // Grey when not selected
  ),
);

                  return Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        // ── START OF YOUR ORIGINAL ON-TAP LOGIC ──
                        homeController.isSearchOpen.value = false;
                        homeController.tabController.index = 0;
                        enquiriesReceivedController.tabController.index = 0;
                        enquiriesSentController.tabController.index = 0;
                        if (homeController.selectTab.value != 0) {
                          homeController.searchController.value.clear();
                          homeController.searchProduct('');
                        }
                        if (index == 1) {
                          if (homeController.userData['user_type'] != 2) {
                            EasyLoading.show(status: ConstantString.pleaseWaitLabel);
                            final checkResult = await businessSignUpController.checkProfileBusinessProfileApi();
                            EasyLoading.dismiss();

                            if (checkResult['status'] == true) {
                              if (context.mounted) {
                                _showAlreadySubmittedDialog(context);
                              }
                            } else {
                              if (homeController.userData['category'] != null &&
                                  homeController.userData['category'].toString().trim().isNotEmpty) {
                                EasyLoading.showError(ConstantString.alreadyJoinAsMsg);
                              } else {
                                EasyLoading.show(status: ConstantString.pleaseWaitLabel);
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
                                String photoPath = await NetworkToFileImage.networkToFileImage
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
                                  ShowToast.showToast(error.message.toString(), showSuccess: false);
                                } on SocketException catch (error) {
                                  businessSignUpController.categoryDataList.value = [];
                                  businessSignUpController.subCategoryDataList.value = [];
                                  EasyLoading.dismiss();
                                  ShowToast.showToast(error.message.toString(), showSuccess: false);
                                } catch (error) {
                                  businessSignUpController.categoryDataList.value = [];
                                  businessSignUpController.subCategoryDataList.value = [];
                                  debugPrint(error.toString());
                                  EasyLoading.dismiss();
                                  ShowToast.showToast('Something went wrong.', showSuccess: false);
                                }
                                EasyLoading.dismiss();
                                await Get.to(() => const BusinessSignUpPage());
                                await getUserData();
                              }
                            }
                          } else {
                            enquiriesReceivedController.markOpenEnquiriesAsSeen();
                            homeController.selectTab.value = index;
                          }
                        } else {
                          homeController.selectTab.value = index;
                        }
                        if (homeController.userData['user_type'] == 2) {
                          await homeController.getSentEnquiriesUnreadCount("1");
                        }
                        // ── END OF YOUR ORIGINAL ON-TAP LOGIC ──
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color.fromARGB(255, 227, 232, 251) : Colors.transparent,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            /// Badge & Icon Logic
                            index == 1 && homeController.userData['user_type'] == 2
                                ? Obx(() {
                                    final newCount = enquiriesReceivedController.newOpenCount.value;
                                    final unreadCount = homeController.receivedUnreadCount.value;
                                    final badgeCount = newCount > 0 ? newCount : unreadCount;
                                    return badgeCount == 0
                                        ? styledIcon
                                        : badges.Badge(
                                            badgeContent: Text(
                                              badgeCount.toString(),
                                              style: const TextStyle(color: Colors.white, fontSize: 10),
                                            ),
                                            badgeStyle: const badges.BadgeStyle(
                                                badgeColor: Color.fromARGB(255, 134, 141, 227), padding: EdgeInsets.all(5)),
                                            child: styledIcon,
                                          );
                                  })
                                : index == 2
                                    ? Obx(() => homeController.pendingOpenInquiriesCount.value.toString() == "0"
                                        ? styledIcon
                                        : badges.Badge(
                                            badgeContent: Text(
                                              homeController.pendingOpenInquiriesCount.value.toString(),
                                              style: const TextStyle(color: Colors.white, fontSize: 10),
                                            ),
                                            badgeStyle: const badges.BadgeStyle(
                                                badgeColor: const Color.fromARGB(255, 106, 133, 231), padding: EdgeInsets.all(5)),
                                            child: styledIcon,
                                          ))
                                    : styledIcon,
                            
                            const SizedBox(height: 0),
                            
                            /// Title
                            Text(
                              homeTabBarList[index]['title'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                color: isSelected ? const Color(0xff0B3C9B) : const Color(0xff8A95A5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
      
      const SizedBox(width: 12),

      /// ── Right Chopped Pill (Healthy Mode) ──
      Container(
        width: 85,
        decoration: const BoxDecoration(
         gradient: LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      const Color(0xff4F86FF), // Light Blue
      const Color(0xff0B3C9B), // Primary Blue
    ],
  ),// The dark green from the image
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(35),
            bottomLeft: Radius.circular(35),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(-2, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(35),
              bottomLeft: Radius.circular(35),
            ),
             onTap: () {
                    raiseInquiryDialog(context, homeController, height, width);
                  },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
              ScaleTransition(
  scale: _pulseAnimation,
  child: const Icon(
    Icons.add,
    color: Colors.white,
    size: 18,
  ),
),
              const Text(
                            "New Enquiry",
                             
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10.5,
                               color: Colors.white
                              ),
                            ),
              ],
            ),
          ),
        ),
      ),
    ],
  ),
),
      ),
    );
  }

  PreferredSizeWidget _buildTabBarForCurrentTab() {
    final int selectTab = homeController.selectTab.value;
    if (selectTab == 0) {
      return TabBar(
        controller: homeController.tabController,
        indicatorColor: ConstantColor.whiteColor,
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorWeight: 2,
        onTap: (value) async {
          homeController.tabIndex.value = value;
          homeController.isSearchOpen.value = false;
          if (value == 0) {
            await homeController.getSentEnquiriesUnreadCount("1");
          } else if (value == 1) {
            await homeController.getSentEnquiriesUnreadCount("1");
          } else if (value == 2) {
            await homeController.getSentEnquiriesUnreadCount("1");
          }
        },
        tabs: [
          Tab(
            child: Text(
              "All",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: ConstantColor.whiteColor,
              ),
            ),
          ),
          Tab(
            child: Text(
              "Business",
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: ConstantColor.whiteColor),
            ),
          ),
          Tab(
            child: Text(
              "Services",
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: ConstantColor.whiteColor),
            ),
          ),
        ],
      );
    } else if (selectTab == 1) {
      return TabBar(
        controller: enquiriesReceivedController.tabController,
        indicatorColor: ConstantColor.whiteColor,
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorWeight: 4,
        onTap: (value) async {
          if (value == 0) {
            await enquiriesReceivedController.postReceivedApi("1");
            await homeController.getSentEnquiriesUnreadCount("1");
          } else if (value == 1) {
            await enquiriesReceivedController.postReceivedApi("2");
            await homeController.getSentEnquiriesUnreadCount("1");
          }
        },
        tabs: [
          Tab(
            child: Text(
              "Open",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: ConstantColor.whiteColor,
              ),
            ),
          ),
          Tab(
            child: Text(
              "Closed",
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: ConstantColor.whiteColor),
            ),
          ),
        ],
      );
    } else {
      return TabBar(
        controller: enquiriesSentController.tabController,
        indicatorColor: ConstantColor.whiteColor,
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorWeight: 4,
        onTap: (value) async {
          if (value == 0) {
            await enquiriesSentController.postSentApi("1", isAutoRefresh: false);
            await homeController.getSentEnquiriesUnreadCount("1");
          } else if (value == 1) {
            await enquiriesSentController.postSentApi("2", isAutoRefresh: false);
          }
        },
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Open",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: ConstantColor.whiteColor,
                  ),
                ),
                Obx(() {
                  if (enquiriesSentController.getUnreadCount() > 0) {
                    return Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        enquiriesSentController.getUnreadCount().toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }
                  return const SizedBox();
                }),
              ],
            ),
          ),
          Tab(
            child: Text(
              "Closed",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: ConstantColor.whiteColor,
              ),
            ),
          ),
        ],
      );
    }
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
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
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
                            final value =
                                await profileController.postDeveloperApi();
                            EasyLoading.dismiss();
                            if (value['code'] == 200) {
                              final phone =
                                  value['data']['company_mobile'] ?? '';
                              Uri url = Uri.parse('tel:+$phone');
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url);
                              } else {
                                ShowToast.showToast(
                                    "Could not launch dialer",
                                    showSuccess: false);
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
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
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
   Future<void> raiseInquiryDialog(BuildContext context,
    HomeController controller,
    double height,
    double width) async {

  await controller.postCategoriesApi();
  controller.categorySelect.value = {};
  controller.subCategorySelect.value = {};
  controller.priorityTypeSelect.value = "";
  controller.subCategoryList.value = [];
  controller.inquiryController.value.clear();
  
  List categoryList = List.from(controller.categoryList);

  categoryList.removeWhere(
    (element) =>
        element['category'].toString().trim().toLowerCase() ==
        'Not in List'.trim().toLowerCase(),
  );

  if (!context.mounted) return;
  final dialogContext = context;

  return showDialog(
    context: dialogContext,
    barrierDismissible: false,
    builder: (context) => Obx(
      () => Dialog(
        backgroundColor: ConstantColor.whiteColor,
        surfaceTintColor: ConstantColor.whiteColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    "Raise Inquiry",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: ConstantColor.blackColor,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  "Category",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                      color: const Color(0xffF7F8FA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xffEBEFF2),
                        width: 1,
                      )),
                  padding: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 16,
                  ),
                  child: DropdownButton(
                    dropdownColor: ConstantColor.whiteColor,
                    value: controller.categorySelect['category'] == null ||
                            controller.categorySelect['category']
                                .toString()
                                .trim()
                                .isEmpty
                        ? null
                        : controller.categorySelect['category'].toString(),
                    padding: EdgeInsets.zero,
                    isExpanded: true,
                    onChanged: (dynamic newValue) {
                      for (int i = 0; i < categoryList.length; i++) {
                        if (categoryList[i]['category'].toString() == newValue.toString()) {
                          debugPrint('Selected Category Data: ${categoryList[i]}');
                          controller.categorySelect.value = categoryList[i] ?? {};
                          debugPrint('Category ID: ${controller.categorySelect['id']}');
                          controller.postSubCategoriesApi(
                              controller.categorySelect['id'].toString());
                        }
                      }
                    },
                    items: categoryList.map(
                      (val) {
                        return DropdownMenuItem(
                          value: val['category']?.toString() ?? "",
                          child: Text(
                            val['category']?.toString() ?? "",
                            style: TextStyle(
                              fontSize: 15,
                              color: ConstantColor.blackColor,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      },
                    ).toList(),
                    underline: const SizedBox(),
                    hint: Text(
                      "Select Category",
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade400,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    icon: Icon(
                      Icons.arrow_drop_down,
                      size: 24,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Sub-Category",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                      color: const Color(0xffF7F8FA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xffEBEFF2),
                        width: 1,
                      )),
                  padding: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 16,
                  ),
                  child: DropdownButton(
                    dropdownColor: ConstantColor.whiteColor,
                    value: controller.subCategorySelect['subcategory'] == null ||
                            controller.subCategorySelect['subcategory']
                                .toString()
                                .trim()
                                .isEmpty
                        ? null
                        : controller.subCategorySelect['subcategory'].toString(),
                    padding: EdgeInsets.zero,
                    isExpanded: true,
                    onChanged: (dynamic newValue) {
                      for (int i = 0; i < controller.subCategoryList.length; i++) {
                        if (controller.subCategoryList[i]['subcategory'].toString() == newValue.toString()) {
                          debugPrint('Selected SubCategory Data: ${controller.subCategoryList[i]}');
                          controller.subCategorySelect.value = controller.subCategoryList[i] ?? {};
                          debugPrint('SubCategory ID: ${controller.subCategorySelect['id']}');
                        }
                      }
                    },
                    hint: Text(
                      "Select SubCategory",
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade400,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    items: controller.subCategoryList.map(
                      (val) {
                        return DropdownMenuItem(
                          value: val['subcategory']?.toString() ?? "",
                          child: Text(
                            val['subcategory']?.toString() ?? "",
                            style: TextStyle(
                              fontSize: 15,
                              color: ConstantColor.blackColor,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      },
                    ).toList(),
                    underline: const SizedBox(),
                    icon: Icon(
                      Icons.arrow_drop_down,
                      size: 24,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Priority type",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        controller.priorityTypeSelect.value = "Urgent";
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            controller.priorityTypeSelect.value == "Urgent"
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: controller.priorityTypeSelect.value == "Urgent"
                                ? const Color(0xff0B3C9B)
                                : Colors.grey.shade400,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Urgent",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: controller.priorityTypeSelect.value == "Urgent"
                                  ? ConstantColor.blackColor
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 32),
                    GestureDetector(
                      onTap: () {
                        controller.priorityTypeSelect.value = "General";
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            controller.priorityTypeSelect.value == "General"
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: controller.priorityTypeSelect.value == "General"
                                ? const Color(0xff0B3C9B)
                                : Colors.grey.shade400,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "General",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: controller.priorityTypeSelect.value == "General"
                                  ? ConstantColor.blackColor
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xffF7F8FA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xffEBEFF2),
                      width: 1,
                    ),
                  ),
                  child: TextFormField(
                    controller: controller.inquiryController.value,
                    textInputAction: TextInputAction.newline,
                    maxLines: 5,
                    style: TextStyle(
                      fontSize: 15,
                      color: ConstantColor.blackColor,
                      fontWeight: FontWeight.w500,
                    ),
                    keyboardType: TextInputType.multiline,
                    cursorColor: ConstantColor.blackColor,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 16),
                      hintText: "Need Photographer for one day for birthday celebration.",
                      hintStyle: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w400),
                      filled: false,
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          if (!controller.isButtonLoading.value) {
                            Get.back();
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xffD0D5DD), width: 1.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          "CANCEL",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xff344054),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: ConstantColor.primaryGradient,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: ElevatedButton(
                          onPressed: controller.isButtonLoading.value
                              ? null
                              : () async {
                                  // Validate selections
                                  if (controller.categorySelect.isEmpty) {
                                    ShowToast.showToast('Please Select Category', showSuccess: false);
                                    return;
                                  }
                                  
                                  if (controller.subCategorySelect.isEmpty) {
                                    ShowToast.showToast('Please Select Sub-Category', showSuccess: false);
                                    return;
                                  }
                                  
                                  if (controller.priorityTypeSelect.value.isEmpty) {
                                    ShowToast.showToast('Please Select Priority Type', showSuccess: false);
                                    return;
                                  }
                                  
                                  // Get IDs safely
                                  String categoryId = controller.categorySelect['id']?.toString() ?? '';
                                  String subCategoryId = controller.subCategorySelect['id']?.toString() ?? '';
                                  String priorityType = controller.priorityTypeSelect.value == "Urgent" ? "0" : "1";
                                  String inquiryText = controller.inquiryController.value.text.trim();
                                  
                                  // Validate IDs
                                  if (categoryId.isEmpty) {
                                    ShowToast.showToast('Invalid Category selected', showSuccess: false);
                                    return;
                                  }
                                  
                                  if (subCategoryId.isEmpty) {
                                    ShowToast.showToast('Invalid Sub-Category selected', showSuccess: false);
                                    return;
                                  }
                                  
                                  var bodyParams = {
                                    'category': categoryId,
                                    'sub_category': subCategoryId,
                                    'type': priorityType,
                                    'enq_text': inquiryText,
                                  };
                                  
                                  debugPrint('Sending Inquiry with params: $bodyParams');
                                  
                                  // Call API
                                  bool success = await controller.postCreateEnquiryApi(bodyParams);
                                  
                                  if (success) {
                                    if (context.mounted) {
                                      Navigator.of(context).pop();
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                          ),
                          child: controller.isButtonLoading.value
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  "SUBMIT",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
}