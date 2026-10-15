import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:single_clik/constants/constant_color.dart';
import 'package:single_clik/constants/show_toast.dart';
import 'package:single_clik/controller/home_controller/update_profile_controller.dart';
import 'package:single_clik/controller/home_controller/home_controller.dart';
import 'package:single_clik/widget/app_button.dart';
import 'package:single_clik/widget/app_image_assets.dart';
import 'package:single_clik/widget/app_text_field.dart';
import '../../../../constants/constant_string.dart';
import '../../../../constants/network_to_file_image.dart';

class UpdateProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const UpdateProfileScreen({
    super.key,
    required this.userData,
  });

  @override
  State<UpdateProfileScreen> createState() => UpdateProfileScreenState();
}

class UpdateProfileScreenState extends State<UpdateProfileScreen> {
  RxBool businessLogin = true.obs;
  // RxBool nameTextFieldEnable = false.obs;
  // RxBool whatsappNumberTextFieldEnable = false.obs;
  UpdateProfileController updateProfileController =
      Get.put(UpdateProfileController());

  @override
  void initState() {
    // TODO: implement initState
    businessLogin.value = widget.userData['user_type'] == 2;
    getData();
    super.initState();
  }

  Future<void> getData() async {
    await updateProfileController.postCategoriesApi();
    debugPrint('User Data: ${widget.userData}');
    updateProfileController.nameController.value.text =
        widget.userData['name'] ?? "";
    updateProfileController.companyNameController.value.text =
        widget.userData['company_name'] ?? "";
    updateProfileController.emailNameController.value.text =
        widget.userData['email'] ?? "";
    updateProfileController.profileTypeSelect.value =
        widget.userData['profile_type'].toString().split(",");

    for (int i = 0; i < updateProfileController.categoryList.length; i++) {
      if (updateProfileController.categoryList[i]['category'] ==
          widget.userData['category']) {
        updateProfileController.categorySelect.value =
            updateProfileController.categoryList[i];
        updateProfileController.postSubCategoriesApi(
            updateProfileController.categorySelect['id'].toString());
      }
    }
    updateProfileController.whatsappNumberController.value.text =
        widget.userData['whatsapp'] ?? "";
    updateProfileController.webSiteController.value.text =
        widget.userData['website'] ?? "";
    updateProfileController.aboutUsController.value.text =
        widget.userData['about_us'] ?? "";
    updateProfileController.areaController.value.text =
        widget.userData['area'] ?? "";
    debugPrint('User Photo ${widget.userData['photo'] ?? ""}');
    updateProfileController.filePath.value =
        '${ConstantString.userImgUrlPath}${widget.userData['photo'] ?? ""}';
    beforeImgPath = updateProfileController.filePath.value;
  }

  String beforeImgPath = '';

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
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
          "Update Profile",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: ConstantColor.whiteColor,
          ),
        ),
      ),
      body: Obx(
        () => updateProfileController.isLoading.value
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: height * 0.03),
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: Get.width / 2,
                              width: Get.width / 2,
                              child: Stack(
                                children: [
                                  Center(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(7),
                                      child: Container(
                                        height: Get.width / 2.5,
                                        width: Get.width / 2.5,
                                        decoration: BoxDecoration(
                                          color: const Color(0xffFFF0E9),
                                          borderRadius:
                                              BorderRadius.circular(7),
                                        ),
                                        child: updateProfileController
                                                .filePath.value.isNotEmpty
                                            ? AppImageAsset(
                                                key: ValueKey(
                                                    'update_profile_photo_${Get.find<HomeController>().photoVersion.value}'),
                                                image: updateProfileController
                                                    .filePath.value,
                                                isFile: !updateProfileController
                                                    .filePath.value
                                                    .startsWith("http"),
                                                fit: BoxFit.cover,
                                                height: 100,
                                                width: 100,
                                              )
                                            : Center(
                                                child: Image.asset(
                                                  "assets/icons/icon_camera.png",
                                                  height: 30,
                                                  width: 30,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.bottomRight,
                                    child: GestureDetector(
                                      onTap: () async {
                                        final ImagePicker picker =
                                            ImagePicker();

                                        final XFile? image =
                                            await picker.pickImage(
                                                source: ImageSource.gallery);
                                        if (image != null) {
                                          await updateProfileController
                                              .cropImage(image);
                                          if (updateProfileController
                                              .croppedProfileFile!
                                              .value
                                              .path
                                              .isNotEmpty) {
                                            updateProfileController
                                                    .filePath.value =
                                                updateProfileController
                                                    .croppedProfileFile!
                                                    .value
                                                    .path;
                                            await updateProfileController
                                                .autoUploadProfilePhoto();
                                          }
                                        }
                                      },
                                      child: Container(
                                        height: Get.width / 10,
                                        width: Get.width / 10,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: ConstantColor.primary,
                                        ),
                                        alignment: Alignment.center,
                                        child: Icon(
                                          Icons.photo_rounded,
                                          color: ConstantColor.whiteColor,
                                          size: Get.width / 15,
                                        ),
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                            SizedBox(
                                width: businessLogin.value ? width * 0.02 : 0),
                            businessLogin.value
                                ? Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(height: width * 0.03),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Name",
                                              style: headingTextStyle,
                                            ),
                                            Text(
                                              updateProfileController
                                                      .nameController.value.text
                                                      .trim()
                                                      .isNotEmpty
                                                  ? updateProfileController
                                                      .nameController.value.text
                                                  : ConstantString.naLabel,
                                              style: valueTextStyle,
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: width * 0.01),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Number",
                                              style: headingTextStyle,
                                            ),
                                            Text(
                                              updateProfileController
                                                      .whatsappNumberController
                                                      .value
                                                      .text
                                                      .trim()
                                                      .isNotEmpty
                                                  ? updateProfileController
                                                      .whatsappNumberController
                                                      .value
                                                      .text
                                                  : ConstantString.naLabel,
                                              style: valueTextStyle,
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: width * 0.01),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Category",
                                              style: headingTextStyle,
                                            ),
                                            Text(
                                              // updateProfileController
                                              //                     .categorySelect[
                                              //                 'category'] !=
                                              //             null &&
                                              //         updateProfileController
                                              //             .categorySelect[
                                              //                 'category']
                                              //             .toString()
                                              //             .trim()
                                              //             .isNotEmpty
                                              //     ? updateProfileController
                                              //         .categorySelect[
                                              //             'category']
                                              //         .toString()
                                              //     : ConstantString.naLabel,
                                              "IT Company, Event Planner",
                                              style: valueTextStyle,
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: width * 0.01),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Sub Category",
                                              style: headingTextStyle,
                                            ),
                                            Text(
                                              // updateProfileController
                                              //                     .subCategorySelect[
                                              //                 'subcategory'] !=
                                              //             null &&
                                              //         updateProfileController
                                              //             .subCategorySelect[
                                              //                 'subcategory']
                                              //             .toString()
                                              //             .trim()
                                              //             .isNotEmpty
                                              //     ? updateProfileController
                                              //         .subCategorySelect[
                                              //             'subcategory']
                                              //         .toString()
                                              //     : ConstantString.naLabel,
                                              "Mobile Apps, Web Developer, Event Planner",
                                              style: valueTextStyle,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  )
                                : const SizedBox(),
                          ],
                        ),
                      ),
                      businessLogin.value
                          ? const SizedBox()
                          : appTextFormField(
                              keyboardType: TextInputType.name,
                              hintText: "Name",
                              textInputAction: TextInputAction.next,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 0, vertical: 5),
                              controller:
                                  updateProfileController.nameController.value,
                            ),
                      SizedBox(height: businessLogin.value ? 0 : height * 0.02),
                      appTextFormField(
                        keyboardType: TextInputType.name,
                        hintText: "Company Name",
                        textInputAction: TextInputAction.next,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 0, vertical: 5),
                        controller:
                            updateProfileController.companyNameController.value,
                      ),
                      SizedBox(height: height * 0.02),
                      Text(
                        "Profile Type",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: ConstantColor.blackColor,
                        ),
                      ),
                      SizedBox(height: height * 0.01),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                if (updateProfileController.profileTypeSelect
                                    .contains("0")) {
                                  updateProfileController.profileTypeSelect
                                      .remove("0");
                                } else {
                                  updateProfileController.profileTypeSelect
                                      .add("0");
                                }
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: const Color(0xffABAAAF),
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 10),
                                child: Row(
                                  children: [
                                    Image.asset(
                                      updateProfileController.profileTypeSelect
                                              .contains("0")
                                          ? "assets/icons/icon_select_radio.png"
                                          : "assets/icons/icon_unselect_radio.png",
                                      height: 20,
                                      width: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      "Business",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: updateProfileController
                                                .profileTypeSelect
                                                .contains("0")
                                            ? ConstantColor.blackColor
                                            : ConstantColor.grayColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: width * 0.02),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                if (updateProfileController.profileTypeSelect
                                    .contains("1")) {
                                  updateProfileController.profileTypeSelect
                                      .remove("1");
                                } else {
                                  updateProfileController.profileTypeSelect
                                      .add("1");
                                }
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: const Color(0xffABAAAF),
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 10),
                                child: Row(
                                  children: [
                                    Image.asset(
                                      updateProfileController.profileTypeSelect
                                              .contains("1")
                                          ? "assets/icons/icon_select_radio.png"
                                          : "assets/icons/icon_unselect_radio.png",
                                      height: 20,
                                      width: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      "Service",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: updateProfileController
                                                .profileTypeSelect
                                                .contains("1")
                                            ? ConstantColor.blackColor
                                            : ConstantColor.grayColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: businessLogin.value ? 0 : height * 0.02),
                      businessLogin.value
                          ? const SizedBox()
                          : Text(
                              "Category",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: ConstantColor.blackColor,
                              ),
                            ),
                      SizedBox(height: businessLogin.value ? 0 : height * 0.01),
                      businessLogin.value
                          ? const SizedBox()
                          : Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                  color: ConstantColor.bgColor,
                                  borderRadius: BorderRadius.circular(7),
                                  border: Border.all(
                                    color: const Color(0xffDDDDDD),
                                  )),
                              padding: const EdgeInsets.symmetric(
                                vertical: 0,
                                horizontal: 10,
                              ),
                              child: DropdownButton(
                                dropdownColor: ConstantColor.bgColor,
                                value: updateProfileController
                                        .categorySelect['category'] ??
                                    "",
                                padding: EdgeInsets.zero,
                                onChanged: updateProfileController
                                                .categorySelect['category'] !=
                                            null &&
                                        updateProfileController
                                            .categorySelect['category']
                                            .toString()
                                            .trim()
                                            .isNotEmpty
                                    ? null
                                    : (dynamic newValue) {
                                        for (int i = 0;
                                            i <
                                                updateProfileController
                                                    .categoryList.length;
                                            i++) {
                                          if (updateProfileController
                                                      .categoryList[i]
                                                  ['category'] ==
                                              newValue) {
                                            updateProfileController
                                                .categorySelect
                                                .value = updateProfileController
                                                    .categoryList[i] ??
                                                {};
                                            updateProfileController
                                                .postSubCategoriesApi(
                                                    updateProfileController
                                                        .categorySelect['id']
                                                        .toString());
                                          }
                                        }
                                        updateProfileController
                                            .isCategoryLoading.value = true;
                                      },
                                isExpanded: true,
                                items: updateProfileController.categoryList.map(
                                  (val) {
                                    return DropdownMenuItem(
                                      value: val['category'] ?? {},
                                      child: Text(
                                        val['category'] ?? "",
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: ConstantColor.blackColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                      ),
                                    );
                                  },
                                ).toList(),
                                underline: const SizedBox(),
                                icon: Icon(
                                  Icons.arrow_drop_down_sharp,
                                  size: 25,
                                  color: ConstantColor.blackColor,
                                ),
                              ),
                            ),
                      SizedBox(height: businessLogin.value ? 0 : height * 0.02),
                      businessLogin.value
                          ? const SizedBox()
                          : Text(
                              "Sub-Category",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: ConstantColor.blackColor,
                              ),
                            ),
                      SizedBox(height: businessLogin.value ? 0 : height * 0.01),
                      businessLogin.value
                          ? const SizedBox()
                          : Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                  color: ConstantColor.bgColor,
                                  borderRadius: BorderRadius.circular(7),
                                  border: Border.all(
                                    color: const Color(0xffDDDDDD),
                                  )),
                              padding: const EdgeInsets.symmetric(
                                vertical: 0,
                                horizontal: 10,
                              ),
                              child: DropdownButton(
                                dropdownColor: ConstantColor.bgColor,
                                value: updateProfileController
                                        .subCategorySelect['subcategory'] ??
                                    "",
                                padding: EdgeInsets.zero,
                                isExpanded: true,
                                onChanged: (dynamic newValue) {
                                  for (int i = 0;
                                      i <
                                          updateProfileController
                                              .subCategoryList.length;
                                      i++) {
                                    if (updateProfileController
                                                .subCategoryList[i]
                                            ['subcategory'] ==
                                        newValue) {
                                      updateProfileController.subCategorySelect
                                          .value = updateProfileController
                                              .subCategoryList[i] ??
                                          {};
                                    }
                                  }
                                },
                                hint: Text(
                                  "No SubCategory",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: ConstantColor.grayColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                items:
                                    updateProfileController.subCategoryList.map(
                                  (val) {
                                    return DropdownMenuItem(
                                      value: val['subcategory'] ?? "",
                                      child: Text(
                                        val['subcategory'] ?? "",
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: ConstantColor.blackColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                      ),
                                    );
                                  },
                                ).toList(),
                                underline: const SizedBox(),
                                icon: Icon(
                                  Icons.arrow_drop_down_sharp,
                                  size: 25,
                                  color: ConstantColor.blackColor,
                                ),
                              ),
                            ),
                      SizedBox(
                          height: !businessLogin.value ? 0 : height * 0.02),
                      !businessLogin.value
                          ? const SizedBox()
                          : appTextFormField(
                              keyboardType: TextInputType.number,
                              hintText: "Whatsapp Number",
                              textInputAction: TextInputAction.next,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 0, vertical: 5),
                              controller: updateProfileController
                                  .whatsappNumberController.value,
                            ),
                      SizedBox(height: height * 0.02),
                      appTextFormField(
                        keyboardType: TextInputType.url,
                        hintText: "Website",
                        textInputAction: TextInputAction.next,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 0, vertical: 5),
                        controller:
                            updateProfileController.webSiteController.value,
                      ),
                      SizedBox(height: height * 0.02),
                      appTextFormField(
                        keyboardType: TextInputType.streetAddress,
                        hintText: "Area",
                        textInputAction: TextInputAction.done,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 0, vertical: 5),
                        controller:
                            updateProfileController.areaController.value,
                      ),
                      SizedBox(height: height * 0.02),
                      appTextFormField(
                        keyboardType: TextInputType.text,
                        hintText: "About Us",
                        style: TextStyle(fontSize: 13),
                        textInputAction: TextInputAction.next,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 0, vertical: 5),
                        controller:
                            updateProfileController.aboutUsController.value,
                        maxLines: 5,
                      ),
                      // SizedBox(height: height * 0.02),
                      // Row(
                      //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      //   children: [
                      //     Text(
                      //       "Upload your\nPhoto",
                      //       style: TextStyle(
                      //         fontSize: 18,
                      //         color: ConstantColor.blackColor,
                      //         fontWeight: FontWeight.w500,
                      //       ),
                      //     ),
                      //     ClipRRect(
                      //       borderRadius: BorderRadius.circular(7),
                      //       child: GestureDetector(
                      //         onTap: () async {
                      //           final ImagePicker picker = ImagePicker();
                      //
                      //           final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                      //           if (image != null) {
                      //             controller.filePath.value = image.path;
                      //             print(controller.filePath.value);
                      //           }
                      //         },
                      //         child: Container(
                      //           height: 160,
                      //           width: 160,
                      //           decoration: BoxDecoration(
                      //             color: const Color(0xffFFF0E9),
                      //             borderRadius: BorderRadius.circular(7),
                      //           ),
                      //           child: controller.filePath.value != ""
                      //               ? AppImageAsset(
                      //                   image: controller.filePath.contains("cache") ? controller.filePath.value : "${ConstantString.userImgUrlPath}${controller.filePath}",
                      //                   isFile: controller.filePath.contains("cache"),
                      //                   fit: BoxFit.cover,
                      //                   height: 100,
                      //                   width: 100,
                      //                 )
                      //               : Center(
                      //                   child: Image.asset(
                      //                     "assets/icons/icon_camera.png",
                      //                     height: 30,
                      //                     width: 30,
                      //                   ),
                      //                 ),
                      //         ),
                      //       ),
                      //     )
                      //   ],
                      // ),
                      SizedBox(height: height * 0.05),
                      Center(
                        child: AppButton(
                          onTap: () {
                            if (updateProfileController
                                .nameController.value.text.isEmpty) {
                              ShowToast.showToast(
                                "Please Enter Name",
                                showSuccess: false,
                              );
                            } else if (updateProfileController
                                .companyNameController.value.text.isEmpty) {
                              ShowToast.showToast(
                                "Please Enter Company Name",
                                showSuccess: false,
                              );
                            } else if (updateProfileController
                                .profileTypeSelect.isEmpty) {
                              ShowToast.showToast(
                                "Please Select Profile Type",
                                showSuccess: false,
                              );
                            } else if (updateProfileController
                                .categorySelect.isEmpty) {
                              ShowToast.showToast(
                                "Please Select Category",
                                showSuccess: false,
                              );
                            } else if (updateProfileController
                                .subCategorySelect.isEmpty) {
                              ShowToast.showToast(
                                "Please Select Sub-Category",
                                showSuccess: false,
                              );
                            } else if (updateProfileController
                                .whatsappNumberController.value.text.isEmpty) {
                              ShowToast.showToast(
                                "Please Enter Whatsapp Number",
                                showSuccess: false,
                              );
                            } else if (updateProfileController
                                .webSiteController.value.text.isEmpty) {
                              ShowToast.showToast(
                                "Please Enter Website",
                                showSuccess: false,
                              );
                            } else if (updateProfileController
                                .aboutUsController.value.text.isEmpty) {
                              ShowToast.showToast(
                                "Please Enter About Us",
                                showSuccess: false,
                              );
                            } else if (updateProfileController
                                .areaController.value.text.isEmpty) {
                              ShowToast.showToast(
                                "Please Enter Area",
                                showSuccess: false,
                              );
                            } else {
                              updateProfileController.postUpdateProfileApi(
                                {
                                  'name': updateProfileController
                                      .nameController.value.text,
                                  'company_name': updateProfileController
                                      .companyNameController.value.text,
                                  'email': updateProfileController
                                      .emailNameController.value.text,
                                  'profile_type': updateProfileController
                                      .profileTypeSelect
                                      .join(","),
                                  'category': updateProfileController
                                      .categorySelect['id']
                                      .toString(),
                                  'sub_category': updateProfileController
                                      .subCategorySelect['id']
                                      .toString(),
                                  'whatsapp': updateProfileController
                                      .whatsappNumberController.value.text,
                                  'website': updateProfileController
                                      .webSiteController.value.text,
                                  'about_us': updateProfileController
                                      .aboutUsController.value.text,
                                  'area': updateProfileController
                                      .areaController.value.text,
                                },
                                updateProfileController
                                    .croppedProfileFile!.value.path
                                    .trim(),
                              );
                            }
                          },
                          isLoading:
                              updateProfileController.isButtonLoading.value,
                          title: "Update",
                          myWidth: Get.width / 2,
                        ),
                      ),
                      SizedBox(height: height * 0.02),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  TextStyle headingTextStyle = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: ConstantColor.grayColor,
  );

  TextStyle valueTextStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: ConstantColor.blackColor,
  );
}
