// ignore_for_file: prefer_interpolation_to_compose_strings

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:single_clik/constants/constant_color.dart';
import 'package:single_clik/constants/show_toast.dart';
import 'package:single_clik/controller/home_controller/user_details_controller.dart';
import 'package:single_clik/widget/app_image_assets.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

import '../../../constants/constant_string.dart';

class UserDetailsScreen extends StatefulWidget {
  final String id;

  const UserDetailsScreen({
    super.key,
    required this.id,
  });

  @override
  State<UserDetailsScreen> createState() => UserDetailsScreenState();
}

class UserDetailsScreenState extends State<UserDetailsScreen> {
  ScrollController scrollController = ScrollController();
  RxBool isSliverAppBarExpanded = false.obs;

  double height = Get.height;
  double width = Get.width;
  bool get _isSliverAppBarExpanded {
    return scrollController.hasClients &&
        scrollController.offset > (width - kToolbarHeight);
  }

  UserDetailsController userDetailsController =
      Get.put(UserDetailsController());

  Future<void> getUserData() async {
    await userDetailsController.postUserByIdApi(widget.id);
  }

  Future<void> _shareProfile() async {
    try {
      Uri uri = Uri.parse(
          "${ConstantString.userImgUrlPath}${userDetailsController.userDetails['photo']}");

      Directory tempDir = await getTemporaryDirectory();
      String tempPath = tempDir.path;
      File file = File(tempPath +
          (DateTime.now().millisecondsSinceEpoch).toString() +
          '.png');
      http.Response response = await http.get(uri);
      await file.writeAsBytes(response.bodyBytes);
      List<String> subCatList = [];
      String subCategory = "";

      if (userDetailsController.userDetailsProduct['subcategories'] != null) {
        for (int i = 0;
            i <
                userDetailsController
                    .userDetailsProduct['subcategories'].length;
            i++) {
          subCatList.add(userDetailsController
              .userDetailsProduct['subcategories'][i]["subcategory"]
              .toString()
              .trim()
              .replaceAll(",", "\n")
              .trim());
        }
      }

      for (int i = 0; i < subCatList.length; i++) {
        subCategory = subCatList.join(", ");
      }

      debugPrint(subCategory);

      Share.shareXFiles(
        [XFile(file.path)],
        text:
            "${userDetailsController.userDetails['name']}\n\n${userDetailsController.userDetails['company_name']}\n$subCategory\n\nMobile : ${userDetailsController.userDetails['mobile']}\nEmail : ${userDetailsController.userDetails['email']}",
      );
    } catch (e) {
      debugPrint('Error sharing profile: $e');
      Share.share(
        "${userDetailsController.userDetails['name']}\n\n${userDetailsController.userDetails['company_name']}\n\nMobile : ${userDetailsController.userDetails['mobile']}\nEmail : ${userDetailsController.userDetails['email']}",
      );
    }
  }

  Widget _buildCircularIconButton({
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color borderColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: bgColor,
              border: Border.all(color: borderColor, width: 1.5),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.sms_outlined, color: Colors.blue),
                ),
                title: const Text(
                  "SMS",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle:
                    Text(userDetailsController.userDetails['mobile'] ?? ""),
                onTap: () async {
                  Navigator.pop(context);
                  var contact = userDetailsController.userDetails['mobile'];
                  var url = "sms:$contact";
                  try {
                    await launchUrl(Uri.parse(url));
                  } on Exception {
                    ShowToast.showToast(
                      "Could not launch SMS.",
                      showSuccess: false,
                    );
                  }
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child:
                      const Icon(Icons.copy_all_outlined, color: Colors.grey),
                ),
                title: const Text(
                  "Copy Contact Details",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(context);
                  final name = userDetailsController.userDetails['name'] ?? "";
                  final company =
                      userDetailsController.userDetails['company_name'] ?? "";
                  final mobile =
                      userDetailsController.userDetails['mobile'] ?? "";
                  final email =
                      userDetailsController.userDetails['email'] ?? "";

                  String copyText = "Name: $name\n";
                  if (company.toString().isNotEmpty) {
                    copyText += "Company: $company\n";
                  }
                  copyText += "Mobile: $mobile\n";
                  if (email.toString().isNotEmpty) {
                    copyText += "Email: $email";
                  }

                  Clipboard.setData(ClipboardData(text: copyText));
                  ShowToast.showToast(
                    "Contact details copied to clipboard.",
                    showSuccess: true,
                  );
                },
              ),
              if (userDetailsController.userDetails['website'] != null &&
                  userDetailsController.userDetails['website']
                      .toString()
                      .trim()
                      .isNotEmpty)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.language, color: Colors.orange),
                  ),
                  title: const Text(
                    "Visit Website",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(userDetailsController.userDetails['website']
                      .toString()
                      .trim()),
                  onTap: () {
                    Navigator.pop(context);
                    var website = userDetailsController.userDetails['website']
                        .toString()
                        .trim();
                    if (!website.startsWith("http")) {
                      website = "https://" + website;
                    }
                    launchUrl(Uri.parse(website),
                        mode: LaunchMode.externalApplication);
                  },
                ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  @override
  void initState() {
    getUserData();
    scrollController.addListener(
      () {
        isSliverAppBarExpanded.value = _isSliverAppBarExpanded;
      },
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ConstantColor.whiteColor,
      // appBar: AppBar(
      //   backgroundColor: ConstantColor.bgColor,
      //   leading: GestureDetector(
      //     onTap: () {
      //       Get.back();
      //     },
      //     child: Icon(
      //       Icons.arrow_back_outlined,
      //       color: ConstantColor.blackColor,
      //     ),
      //   ),
      // ),
      bottomNavigationBar: Container(
        height: 95,
        color: ConstantColor.whiteColor,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildCircularIconButton(
              icon: Icons.chat_bubble_outline_rounded,
              label: "WhatsApp",
              bgColor: const Color(0xFFE5FBE5),
              borderColor: const Color(0xFFB9F6CA),
              iconColor: const Color(0xFF00C853),
              onTap: () async {
                var contact =
                    '+91' + userDetailsController.userDetails['mobile'];
                var androidUrl = "whatsapp://send?phone=$contact";
                var iosUrl = "https://wa.me/$contact";

                try {
                  if (Platform.isIOS) {
                    await launchUrl(Uri.parse(iosUrl));
                  } else {
                    await launchUrl(Uri.parse(androidUrl));
                  }
                } on Exception {
                  ShowToast.showToast(
                    "WhatsApp is not installed.",
                    showSuccess: false,
                  );
                }
              },
            ),
            _buildCircularIconButton(
              icon: Icons.mail_outline_outlined,
              label: "Email",
              bgColor: const Color(0xFFFEECEB),
              borderColor: const Color(0xFFFFCDD2),
              iconColor: const Color(0xFFEA4335),
              onTap: () async {
                var contact = userDetailsController.userDetails['email'];
                var androidUrl = "mailto:$contact";
                var iosUrl = "mailto:$contact";

                try {
                  if (Platform.isIOS) {
                    await launchUrl(Uri.parse(iosUrl));
                  } else {
                    await launchUrl(Uri.parse(androidUrl));
                  }
                } on Exception {
                  ShowToast.showToast(
                    "Could not launch Email.",
                    showSuccess: false,
                  );
                }
              },
            ),
            _buildCircularIconButton(
              icon: Icons.share,
              label: "Share",
              bgColor: const Color(0xFFF3E5F5),
              borderColor: const Color(0xFFE1BEE7),
              iconColor: const Color(0xFFAB47BC),
              onTap: () async {
                await _shareProfile();
              },
            ),
            _buildCircularIconButton(
              icon: Icons.call,
              label: "Call",
              bgColor: const Color(0xFFE1F5FE),
              borderColor: const Color(0xFFB3E5FC),
              iconColor: const Color(0xFF0288D1),
              onTap: () {
                launchUrl(Uri.parse(
                    "tel:${'+91' + userDetailsController.userDetails['mobile']}"));
              },
            ),
            _buildCircularIconButton(
              icon: Icons.more_horiz_rounded,
              label: "More",
              bgColor: const Color(0xFFEEF0FC),
              borderColor: const Color(0xFFC5CAE9),
              iconColor: const Color(0xFF283593),
              onTap: () {
                _showMoreOptions(context);
              },
            ),
          ],
        ),
      ),
      body: Obx(
        () => userDetailsController.isLoading.value
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : DefaultTabController(
                length: 3,
                child: NestedScrollView(
                  controller: scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                    return [
                      Obx(
                        () => SliverAppBar(
                          elevation: 0,
                          title: isSliverAppBarExpanded.value
                              ? Row(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: ConstantColor.whiteColor,
                                          width: 1,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: ClipOval(
                                        child: AppImageAsset(
                                          image:
                                              "${ConstantString.userImgUrlPath}${userDetailsController.userDetails['photo']}",
                                          isFile: false,
                                          fit: BoxFit.cover,
                                          height: Get.width / 10,
                                          width: Get.width / 10,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: width / 30,
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          userDetailsController
                                                  .userDetails['name'] ??
                                              "",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: ConstantColor.whiteColor,
                                          ),
                                        ),
                                        userDetailsController.userDetails[
                                                        'company_name'] ==
                                                    null ||
                                                userDetailsController
                                                            .userDetails[
                                                        'company_name'] ==
                                                    null
                                                        .toString()
                                                        .trim()
                                                        .isEmpty
                                            ? const SizedBox()
                                            : Text(
                                                userDetailsController
                                                            .userDetails[
                                                        'company_name'] ??
                                                    "",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: ConstantColor
                                                      .whiteColor
                                                      .withOpacity(0.8),
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                      ],
                                    ),
                                  ],
                                )
                              : null,
                          pinned: true,
                          expandedHeight: width,
                          backgroundColor: Colors.transparent,
                          iconTheme: IconThemeData(
                            color: ConstantColor.whiteColor,
                          ),
                          flexibleSpace: Container(
                            decoration: BoxDecoration(
                              gradient: ConstantColor.primaryGradient,
                            ),
                            child: isSliverAppBarExpanded.value
                                ? null
                                : FlexibleSpaceBar(
                                    background: Column(
                                      children: [
                                        AppBar(
                                          backgroundColor: Colors.transparent,
                                          elevation: 0,
                                        ),
                                        Center(
                                          child: GestureDetector(
                                            onTap: () {
                                              showDialog(
                                                context: context,
                                                builder: (context) {
                                                  return Dialog(
                                                    insetPadding:
                                                        EdgeInsets.symmetric(
                                                      horizontal:
                                                          Get.width / 30,
                                                    ),
                                                    backgroundColor:
                                                        ConstantColor
                                                            .whiteColor,
                                                    child: SizedBox(
                                                      child: AppImageAsset(
                                                        image:
                                                            "${ConstantString.userImgUrlPath}${userDetailsController.userDetails['photo']}",
                                                        isFile: false,
                                                        height: Get.width / 1.2,
                                                        width: Get.width / 1.2,
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                  );
                                                },
                                              );
                                            },
                                            child: Container(
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color:
                                                      ConstantColor.whiteColor,
                                                  width: 3,
                                                ),
                                                shape: BoxShape.circle,
                                              ),
                                              child: ClipOval(
                                                child: AppImageAsset(
                                                  image:
                                                      "${ConstantString.userImgUrlPath}${userDetailsController.userDetails['photo']}",
                                                  isFile: false,
                                                  fit: BoxFit.cover,
                                                  height: Get.width / 1.8,
                                                  width: Get.width / 1.8,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: height * 0.01),
                                        Text(
                                          userDetailsController
                                                  .userDetails['name'] ??
                                              "",
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: ConstantColor.whiteColor,
                                          ),
                                        ),
                                        SizedBox(height: height * 0.01),
                                        userDetailsController.userDetails[
                                                        'company_name'] ==
                                                    null ||
                                                userDetailsController
                                                            .userDetails[
                                                        'company_name'] ==
                                                    null
                                                        .toString()
                                                        .trim()
                                                        .isEmpty
                                            ? const SizedBox()
                                            : Column(
                                                children: [
                                                  Text(
                                                    "Company",
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                      color: ConstantColor
                                                          .whiteColor
                                                          .withOpacity(0.7),
                                                    ),
                                                  ),
                                                  Text(
                                                    userDetailsController
                                                                .userDetails[
                                                            'company_name'] ??
                                                        "",
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: ConstantColor
                                                          .whiteColor,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ],
                                              ),
                                        SizedBox(height: height * 0.01)
                                      ],
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      SliverPersistentHeader(
                        delegate: MySliverPersistentHeaderDelegate(
                          TabBar(
                            controller: userDetailsController.tabController,
                            indicatorColor: ConstantColor.whiteColor,
                            indicatorSize: TabBarIndicatorSize.tab,
                            indicatorWeight: 3,
                            labelColor: ConstantColor.whiteColor,
                            unselectedLabelColor:
                                ConstantColor.whiteColor.withOpacity(0.7),
                            labelStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            unselectedLabelStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            tabs: [
                              Tab(
                                text: userDetailsController
                                            .userDetails['profile_type']
                                            ?.toString() ==
                                        "1"
                                    ? "Services"
                                    : "Product &\nServices",
                              ),
                              const Tab(
                                text: "About Us",
                              ),
                              const Tab(
                                text: "Contact",
                              ),
                            ],
                          ),
                        ),
                        pinned: true,
                      ),
                    ];
                  },
                  body: TabBarView(
                    controller: userDetailsController.tabController,
                    children: [
                      _buildProductsAndServicesTabContent(),
                      _buildAboutTabContent(),
                      _buildContactTabContent(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildAboutTabContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: height * 0.03),
            Text(
              userDetailsController.userDetails['about_us'] == null ||
                      userDetailsController.userDetails['about_us']
                          .toString()
                          .trim()
                          .isEmpty
                  ? "No details available."
                  : userDetailsController.userDetails['about_us']
                      .toString()
                      .replaceAll("/", "\n"),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: ConstantColor.blackColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsAndServicesTabContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // Services Offered Header
            Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: Colors.deepOrange,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  "Services Offered",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Check if categories list is empty
            if (userDetailsController.userDetailsProduct['categories'] ==
                    null ||
                (userDetailsController.userDetailsProduct['categories'] as List)
                    .isEmpty)
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                child: Text(
                  "No services listed",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            else
              ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: userDetailsController
                    .userDetailsProduct['categories'].length,
                itemBuilder: (context, index) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          ' ' +
                              userDetailsController
                                  .userDetailsProduct['categories'][index]
                                      ["category"]
                                  .toString()
                                  .trim()
                                  .replaceAll(",", "\n")
                                  .trim(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.deepOrange,
                          ),
                        ),
                      ),
                      ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: userDetailsController
                            .userDetailsProduct['subcategories'].length,
                        itemBuilder: (context, index2) {
                          return userDetailsController
                                          .userDetailsProduct['subcategories']
                                      [index2]["category_id"] !=
                                  userDetailsController
                                          .userDetailsProduct['categories']
                                      [index]["u_catg_id"]
                              ? const SizedBox.shrink()
                              : Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            left: 30, right: 10),
                                        child: Icon(Icons.circle,
                                            size: 7,
                                            color: ConstantColor.primary),
                                      ),
                                      Expanded(
                                        child: Text(
                                          userDetailsController
                                              .userDetailsProduct[
                                                  'subcategories'][index2]
                                                  ["subcategory"]
                                              .toString()
                                              .trim()
                                              .replaceAll(",", "\n")
                                              .trim(),
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: ConstantColor.blackColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                  );
                },
              ),

            if (userDetailsController.userDetails['profile_type']?.toString() !=
                "1") ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 16),

              // Products Header
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 18,
                    decoration: BoxDecoration(
                      color: ConstantColor.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Products",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Products Display List
              Builder(
                builder: (context) {
                  final products = List.from(userDetailsController
                          .userDetailsProduct['products'] ??
                      userDetailsController
                          .userDetailsProduct['product_services'] ??
                      userDetailsController.userDetails['products'] ??
                      userDetailsController.userDetails['product_services'] ??
                      []);

                  if (products.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 30),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_bag_outlined,
                                size: 48, color: Colors.grey[300]),
                            const SizedBox(height: 12),
                            Text(
                              "No products uploaded by this business yet",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, idx) {
                      final product = products[idx];
                      return GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) {
                              return Dialog(
                                insetPadding: EdgeInsets.symmetric(
                                  horizontal: Get.width / 20,
                                ),
                                backgroundColor: ConstantColor.whiteColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AppBar(
                                      backgroundColor: Colors.transparent,
                                      elevation: 0,
                                      leading: IconButton(
                                        icon: const Icon(Icons.close,
                                            color: Colors.black),
                                        onPressed: () => Get.back(),
                                      ),
                                      title: Text(
                                        (product['product_name'] ?? '')
                                            .toString(),
                                        style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxHeight: Get.height * 0.6,
                                        maxWidth: Get.width * 0.9,
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 8),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: AppImageAsset(
                                            image:
                                                "${ConstantString.productImgUrlPath}${product['product_images'] ?? ''}",
                                            isFile: false,
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(11)),
                                  child: AppImageAsset(
                                    image:
                                        "${ConstantString.productImgUrlPath}${product['product_images'] ?? ''}",
                                    isFile: false,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(
                                  (product['product_name'] ?? '').toString(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildContactTabContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: height * 0.03),
            Text(
              "Mobile Number",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: ConstantColor.grayColor,
              ),
            ),
            Text(
              userDetailsController.userDetails['mobile'] ?? "",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: ConstantColor.blackColor,
              ),
            ),
            SizedBox(height: height * 0.03),
            Text(
              "Email",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: ConstantColor.grayColor,
              ),
            ),
            Text(
              userDetailsController.userDetails['email'] ?? "",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: ConstantColor.blackColor,
              ),
            ),
            SizedBox(height: height * 0.03),
            Text(
              "Whatsapp",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: ConstantColor.grayColor,
              ),
            ),
            Text(
              userDetailsController.userDetails['whatsapp'] ?? "",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: ConstantColor.blackColor,
              ),
            ),
            SizedBox(height: height * 0.03),
            Text(
              "Area",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: ConstantColor.grayColor,
              ),
            ),
            Text(
              userDetailsController.userDetails['area'] ?? "",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: ConstantColor.blackColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MySliverPersistentHeaderDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  MySliverPersistentHeaderDelegate(this._tabBar);

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: BoxDecoration(
        gradient: ConstantColor.primaryGradient,
      ),
      child: _tabBar,
    );
  }

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  bool shouldRebuild(MySliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}
