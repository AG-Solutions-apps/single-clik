import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:single_clik/constants/constant_color.dart';
import 'package:single_clik/constants/constant_string.dart';
import 'package:single_clik/controller/home_controller/home_controller.dart';
import 'package:single_clik/controller/home_controller/profile_controller.dart';
import 'package:single_clik/screens/home_screens/home_screens/drawer_screens/update_profile_screen.dart';
import 'package:single_clik/widget/app_button.dart';
import 'package:single_clik/widget/app_image_assets.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../constants/show_toast.dart';
import '../../../../controller/home_controller/update_profile_controller.dart';
import '../../../../widget/drawer.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final HomeController homeController = Get.put(HomeController());
  final ProfileController profileController = Get.put(ProfileController());
  final UpdateProfileController updateProfileController = Get.put(UpdateProfileController());

  RxBool businessLogin = true.obs;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      businessLogin.value = homeController.userData['user_type'] == 2;
      profileController.postFetchProfileApi();
    });
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xffF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: ConstantColor.primaryGradient,
          ),
        ),
        leading: GestureDetector(
          onTap: () => Get.back(),
          child: const Center(
            child: Icon(
              Icons.arrow_back_outlined,
              color: Colors.white,
            ),
          ),
        ),
        title: const Text(
          "Profile",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: Obx(() {
        if (profileController.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final profileData = profileController.profileMap;
        final name = (profileData['name'] ?? '').toString();
        final companyName = (profileData['company_name'] ?? '').toString();

        return SingleChildScrollView(
          child: Column(
            children: [
              // ── Header Profile Photo Section ──
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[200]!),
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: ConstantColor.primary,
                                width: 3,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: ClipOval(
                              child: AppImageAsset(
                                key: ValueKey('profile_photo_${homeController.photoVersion.value}'),
                                image: profileController.filePath.value,
                                isFile: !profileController.filePath.value.startsWith("http"),
                                fit: BoxFit.cover,
                                height: Get.width / 3,
                                width: Get.width / 3,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () async {
                                final ImagePicker picker = ImagePicker();
                                final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                                if (image != null) {
                                  await profileController.cropImage(image);
                                  if (profileController.croppedProfileFile!.value.path.isNotEmpty) {
                                    profileController.filePath.value = profileController.croppedProfileFile!.value.path;
                                    await profileController.autoUploadProfilePhoto();
                                  }
                                }
                              },
                              
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      businessLogin.value
                          ? (companyName.isNotEmpty ? companyName : "Company Name")
                          : (name.isNotEmpty ? name : "Username"),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: ConstantColor.blackColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: ConstantColor.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        businessLogin.value ? "Business Account" : "User Account",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: ConstantColor.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── Details Card ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: businessLogin.value
                        ? [
                            _buildInfoRow(Icons.business_rounded, "Company Name", companyName),
                            const Divider(height: 1),
                            _buildInfoRow(Icons.phone_iphone_rounded, "Mobile", (profileData['mobile'] ?? '').toString()),
                            const Divider(height: 1),
                            _buildInfoRow(Icons.chat_bubble_outline_rounded, "Whatsapp", (profileData['whatsapp'] ?? '').toString()),
                            const Divider(height: 1),
                            _buildInfoRow(Icons.email_outlined, "Email", (profileData['email'] ?? '').toString()),
                            const Divider(height: 1),
                            _buildInfoRow(Icons.language_rounded, "Website", (profileData['website'] ?? '').toString()),
                            const Divider(height: 1),
                            _buildInfoRow(Icons.category_outlined, "Category", "IT Company, Event Planner"),
                            const Divider(height: 1),
                            _buildInfoRow(Icons.dashboard_customize_outlined, "Sub Category", "Mobile Apps, Web Developer, Event Planner"),
                            const Divider(height: 1),
                            _buildInfoRow(Icons.info_outline_rounded, "About Us", (profileData['about_us'] ?? '').toString()),
                            const Divider(height: 1),
                            _buildInfoRow(Icons.location_on_outlined, "Area", (profileData['area'] ?? '').toString()),
                          ]
                        : [
                            _buildInfoRow(Icons.person_outline_rounded, "Name", name),
                            const Divider(height: 1),
                            _buildInfoRow(Icons.phone_iphone_rounded, "Mobile", (profileData['mobile'] ?? '').toString()),
                            const Divider(height: 1),
                            _buildInfoRow(Icons.email_outlined, "Email ID", (profileData['email'] ?? '').toString()),
                            const Divider(height: 1),
                            _buildInfoRow(Icons.location_on_outlined, "Area", (profileData['area'] ?? '').toString()),
                          ],
                  ),
                ),
              ),
              // ── Products Section (only for Business accounts) ──
              if (businessLogin.value) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Products",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: ConstantColor.blackColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Builder(
                      builder: (context) {
                        final products = List.from(profileData['products'] ?? profileData['product_services'] ?? []);
                        if (products.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Column(
                                children: [
                                  Icon(Icons.shopping_bag_outlined, size: 40, color: Colors.grey[300]),
                                  const SizedBox(height: 8),
                                  Text(
                                    "No products added yet",
                                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        return GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.0,
                          ),
                          itemCount: products.length,
                          itemBuilder: (context, index) {
                            final product = products[index];
                            return Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey[200]!),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                                          child: AppImageAsset(
                                            image: "${ConstantString.productImgUrlPath}${product['product_images'] ?? ''}",
                                            isFile: false,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(6),
                                        child: Text(
                                          (product['product_name'] ?? '').toString(),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Delete button
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => _confirmDeleteProduct(context, product),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.delete_forever_rounded, color: Colors.white, size: 16),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      }
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // ── Actions Buttons ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          if (homeController.userData['user_type'] == 1) {
                            if (homeController.userData['category'] != null &&
                                homeController.userData['category'].toString().trim().isNotEmpty) {
                              _showAlreadyJoinedDialog(context, width, height);
                            } else {
                              _showEditProfileBottomSheet(context);
                            }
                          } else {
                            Get.to(() => UpdateProfileScreen(
                                userData: Map<String, dynamic>.from(profileController.profileMap)
                            ))!.then((value) {
                              if (value == true) {
                                profileController.postFetchProfileApi();
                              }
                            });
                          }
                        },
                        title: "Edit Profile",
                        arrowShow: false,
                      ),
                    ),
                    if (businessLogin.value) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppButton(
                          borderRadius: BorderRadius.circular(8),
                          title: "Add Product",
                          arrowShow: false,
                          onTap: () => _showAddProductBottomSheet(context),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Delete Account Option ──
              InkWell(
                onTap: () => deleteDialog(context, height, width),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  child: Text(
                    "Delete Account",
                    style: TextStyle(
                      decoration: TextDecoration.underline,
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: ConstantColor.primary,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value.trim().isEmpty ? ConstantString.naLabel : value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: ConstantColor.blackColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAlreadyJoinedDialog(BuildContext context, double width, double height) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          insetPadding: EdgeInsets.symmetric(horizontal: Get.width / 20),
          child: Padding(
            padding: EdgeInsets.all(width / 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Text(
                    ConstantString.alreadyJoinAsMsg,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: ConstantColor.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(height: height * 0.04),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        title: "Cancel",
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => Get.back(),
                        buttonColor: Colors.white,
                        buttonTextColor: ConstantColor.primary,
                        arrowShow: false,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Obx(() => AppButton(
                        title: "Call us",
                        onTap: () async {
                          profileController.isButtonLoading.value = true;
                          await profileController.postDeveloperApi().then((value) async {
                            if (value['code'] == 200) {
                              Uri url = Uri.parse('tel:+${value['data']['company_mobile'] ?? ''}');
                              if (await canLaunchUrl(url)) {
                                profileController.isButtonLoading.value = false;
                                Get.back();
                                await launchUrl(url);
                              } else {
                                profileController.isButtonLoading.value = false;
                                Get.back();
                                ShowToast.showToast(
                                  ConstantString.somethingWantWrongMsg,
                                  showSuccess: false,
                                );
                              }
                            } else {
                              profileController.isButtonLoading.value = false;
                              Get.back();
                              ShowToast.showToast(
                                value['msg'] ?? ConstantString.somethingWantWrongMsg,
                                showSuccess: false,
                              );
                            }
                          }).catchError((error) {
                            debugPrint('Error: $error');
                            profileController.isButtonLoading.value = false;
                            Get.back();
                            ShowToast.showToast(error.toString(), showSuccess: false);
                          });
                        },
                        arrowShow: false,
                        borderRadius: BorderRadius.circular(8),
                        buttonTextColor: Colors.white,
                        isLoading: profileController.isButtonLoading.value,
                      )),
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

  void _showEditProfileBottomSheet(BuildContext context) {
    profileController.nameController.value.text = (profileController.profileMap['name'] ?? '').toString();
    profileController.emailController.value.text = (profileController.profileMap['email'] ?? '').toString();
    profileController.areaController.value.text = (profileController.profileMap['area'] ?? '').toString();
    profileController.referredCodeController.value.text = (profileController.profileMap['referred_by_code'] ?? '').toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    height: 5,
                    width: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Edit Profile Details",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: ConstantColor.primary,
                  ),
                ),
                const SizedBox(height: 20),
                _buildSheetTextField("Full Name", profileController.nameController.value, TextInputType.name),
                const SizedBox(height: 15),
                _buildSheetTextField("Email Address", profileController.emailController.value, TextInputType.emailAddress),
                const SizedBox(height: 15),
                _buildSheetTextField("Area / Location", profileController.areaController.value, TextInputType.text),
                const SizedBox(height: 15),
                _buildSheetTextField("Referred By Code (Optional)", profileController.referredCodeController.value, TextInputType.text),
                const SizedBox(height: 25),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Get.back(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey[600],
                          side: BorderSide(color: Colors.grey[300]!),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text("Cancel"),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Obx(() => ElevatedButton(
                        onPressed: profileController.isButtonLoading.value
                            ? null
                            : () async {
                                profileController.isButtonLoading.value = true;
                                Map<String, String> bodyParams = {
                                  'name': profileController.nameController.value.text.trim(),
                                  'email': profileController.emailController.value.text.trim(),
                                  'area': profileController.areaController.value.text.trim(),
                                  'referred_by_code': profileController.referredCodeController.value.text.trim(),
                                  'profile_type': (profileController.profileMap['profile_type'] ?? '0').toString(),
                                };
                                await profileController
                                    .postUpdateProfileApi(
                                        bodyParams,
                                        profileController.filePath.value.contains("cache") 
                                            ? profileController.filePath.value.trim() 
                                            : "")
                                    .then((value) async {
                                  if (value != null && value['code'] == 200) {
                                    await profileController.postFetchProfileApi();
                                    await AppImageCacheManager.clearImageCache();
                                    homeController.photoVersion.value++;
                                    homeController.postFetchProfileApi(forceRefresh: true);
                                    Get.back();
                                    ShowToast.showToast(
                                      value['msg'] ?? ConstantString.dataUpdatedSuccessfullyMsg,
                                      showSuccess: true,
                                    );
                                  } else {
                                    ShowToast.showToast(
                                      value['msg'] ?? ConstantString.somethingWantWrongMsg,
                                      showSuccess: false,
                                    );
                                  }
                                }).catchError((error) {
                                  debugPrint('Error: $error');
                                  ShowToast.showToast(error.toString(), showSuccess: false);
                                }).whenComplete(() {
                                  profileController.isButtonLoading.value = false;
                                });
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ConstantColor.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: profileController.isButtonLoading.value
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text("Save Changes"),
                      )),
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

  Widget _buildSheetTextField(String label, TextEditingController controller, TextInputType type) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: type,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: ConstantColor.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  void _confirmDeleteProduct(BuildContext context, dynamic product) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete Product"),
          content: Text("Are you sure you want to delete '${product['product_name']}'?"),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                Get.back();
                EasyLoading.show(status: 'Deleting product...');
                try {
                  await profileController.postDeleteProductApi(
                    (product['id'] ?? product['product_id'] ?? '').toString(),
                  );
                  ShowToast.showToast("Product deleted successfully!", showSuccess: true);
                  await profileController.postFetchProfileApi();
                } catch (e) {
                  ShowToast.showToast("Error: $e", showSuccess: false);
                } finally {
                  EasyLoading.dismiss();
                }
              },
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _pickProductImage(BuildContext context, RxString selectedProductImagePath) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: Colors.deepOrange),
                title: const Text("Choose from Gallery"),
                onTap: () async {
                  Get.back();
                  final ImagePicker picker = ImagePicker();
                  final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    selectedProductImagePath.value = image.path;
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: Colors.deepOrange),
                title: const Text("Take a Photo"),
                onTap: () async {
                  Get.back();
                  final ImagePicker picker = ImagePicker();
                  final XFile? image = await picker.pickImage(source: ImageSource.camera);
                  if (image != null) {
                    selectedProductImagePath.value = image.path;
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddProductBottomSheet(BuildContext context) {
    final nameController = TextEditingController();
    final RxString selectedProductImagePath = ''.obs;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    height: 5,
                    width: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Add New Product",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: ConstantColor.primary,
                  ),
                ),
                const SizedBox(height: 20),
                _buildSheetTextField("Product Name", nameController, TextInputType.text),
                const SizedBox(height: 15),
                Text(
                  "Product Image",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Obx(() => selectedProductImagePath.value.isEmpty
                    ? GestureDetector(
                        onTap: () => _pickProductImage(context, selectedProductImagePath),
                        child: Container(
                          height: 120,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_outlined, size: 40, color: Colors.grey[400]),
                              const SizedBox(height: 8),
                              Text("Select product image", style: TextStyle(color: Colors.grey[500])),
                            ],
                          ),
                        ),
                      )
                    : Stack(
                        children: [
                          Container(
                            height: 150,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(selectedProductImagePath.value),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () => selectedProductImagePath.value = '',
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, color: Colors.white, size: 18),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () => _pickProductImage(context, selectedProductImagePath),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.edit, color: Colors.white, size: 12),
                                    SizedBox(width: 4),
                                    Text("Change", style: TextStyle(color: Colors.white, fontSize: 11)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      )),
                const SizedBox(height: 25),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Get.back(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey[600],
                          side: BorderSide(color: Colors.grey[300]!),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text("Cancel"),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final pName = nameController.text.trim();
                          final pImage = selectedProductImagePath.value;
                          if (pName.isEmpty) {
                            ShowToast.showToast("Please enter product name", showSuccess: false);
                            return;
                          }
                          if (pImage.isEmpty) {
                            ShowToast.showToast("Please select product image", showSuccess: false);
                            return;
                          }
                          
                          Get.back();
                          EasyLoading.show(status: 'Adding product...');
                          try {
                            final result = await profileController.postCreateProductApi(pName, pImage);
                            if (result != null && (result['code'] == 200 || result['code'] == 201)) {
                              ShowToast.showToast("Product added successfully!", showSuccess: true);
                              await profileController.postFetchProfileApi();
                            } else {
                              ShowToast.showToast(result['msg'] ?? result['message'] ?? "Failed to add product", showSuccess: false);
                            }
                          } catch (e) {
                            ShowToast.showToast("Error: $e", showSuccess: false);
                          } finally {
                            EasyLoading.dismiss();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ConstantColor.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text("Add Product"),
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
}


