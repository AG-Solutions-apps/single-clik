import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:single_clik/constants/constant_color.dart';
import 'package:single_clik/constants/constant_string.dart';
import 'package:single_clik/widget/app_image_assets.dart';

import '../../../../controller/home_controller/profile_controller.dart';
import 'feedback_screen.dart';

class AboutUsScreen extends StatefulWidget {
  const AboutUsScreen({super.key});

  @override
  State<AboutUsScreen> createState() => _AboutUsScreenState();
}

class _AboutUsScreenState extends State<AboutUsScreen> {
  ProfileController profileController = Get.put(ProfileController());
  RxMap aboutUsData = {}.obs;
  double height = Get.height;
  double width = Get.width;

  Future<void> getAboutUsData() async {
    profileController.isButtonLoading.value = true;
    await profileController.postDeveloperApi().then((value) {
      profileController.isButtonLoading.value = false;
      if (value['code'] == 200) {
        aboutUsData.value = value['data'] ?? {};
      }
    }).catchError((error) {
      aboutUsData.value = {};
      profileController.isButtonLoading.value = false;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    getAboutUsData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ConstantColor.bgColor,
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
          "About Us",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: ConstantColor.whiteColor,
          ),
        ),
      ),
      body: Obx(
        () => profileController.isButtonLoading.value
            ? Center(
                child: CircularProgressIndicator(
                  color: ConstantColor.primary,
                ),
              )
            : SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(0),
                  child: Container(
                    height: height,
                    width: width,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: FileImage(
                          File(profileController.aboutUsBGImgFilePath.value),
                        ),
                        fit: BoxFit.fill,
                      ),
                    ),
                    padding: EdgeInsets.all(width / 15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    aboutUsData['company_name'] == null ||
                                            aboutUsData['company_name']
                                                .toString()
                                                .trim()
                                                .isEmpty
                                        ? 'Name ${ConstantString.naLabel}'
                                        : aboutUsData['company_name']
                                            .toString()
                                            .trim(),
                                    style: TextStyle(
                                      fontSize: 35,
                                      color: ConstantColor.primary,
                                      fontWeight: FontWeight.w400,
                                      height: 0,
                                    ),
                                  ),
                                  Text(
                                    aboutUsData['company_sub_heading'] ==
                                                null ||
                                            aboutUsData['company_sub_heading']
                                                .toString()
                                                .trim()
                                                .isEmpty
                                        ? 'Sub Heading ${ConstantString.naLabel}'
                                        : aboutUsData['company_sub_heading']
                                            .toString()
                                            .trim(),
                                    style: TextStyle(
                                      fontSize: 21,
                                      color: ConstantColor.blackColor,
                                      fontWeight: FontWeight.w400,
                                      height: 0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            aboutUsData['company_logo'] == null ||
                                    aboutUsData['company_logo']
                                        .toString()
                                        .trim()
                                        .isEmpty
                                ? const SizedBox()
                                : AppImageAsset(
                                    image:
                                        "${ConstantString.developerImgUrlPath}${aboutUsData['company_logo'].toString().trim()}",
                                    height: width * 0.3,
                                    width: width * 0.3,
                                    fit: BoxFit.contain,
                                  ),
                          ],
                        ),
                        SizedBox(
                          height: aboutUsData['about'] == null ||
                                  aboutUsData['about'].toString().trim().isEmpty
                              ? 0
                              : width / 12,
                        ),
                        aboutUsData['about'] == null ||
                                aboutUsData['about'].toString().trim().isEmpty
                            ? const SizedBox()
                            : Text(
                                aboutUsData['about'] == null ||
                                        aboutUsData['about']
                                            .toString()
                                            .trim()
                                            .isEmpty
                                    ? 'About ${ConstantString.naLabel}'
                                    : aboutUsData['about'].toString().trim(),
                                textAlign: TextAlign.justify,
                                style: TextStyle(
                                  fontSize: 21,
                                  color: ConstantColor.blackColor,
                                  fontWeight: FontWeight.w400,
                                  height: 0,
                                ),
                              ),
                        SizedBox(
                          height: aboutUsData['button_text'] == null ||
                                  aboutUsData['button_text']
                                      .toString()
                                      .trim()
                                      .isEmpty
                              ? 0
                              : width / 12,
                        ),
                        aboutUsData['button_text'] == null ||
                                aboutUsData['button_text']
                                    .toString()
                                    .trim()
                                    .isEmpty
                            ? const SizedBox()
                            : GestureDetector(
                                onTap: () {
                                  Get.to(() => const FeedbackScreen());
                                },
                                child: Container(
                                  width: width,
                                  decoration: BoxDecoration(
                                    color: ConstantColor.primaryDark,
                                    borderRadius: BorderRadius.circular(width),
                                  ),
                                  padding: EdgeInsets.all(width / 30),
                                  alignment: Alignment.center,
                                  child: Text(
                                    aboutUsData['button_text'] == null ||
                                            aboutUsData['button_text']
                                                .toString()
                                                .trim()
                                                .isEmpty
                                        ? 'Text ${ConstantString.naLabel}'
                                        : aboutUsData['button_text']
                                            .toString()
                                            .trim(),
                                    textAlign: TextAlign.justify,
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: ConstantColor.whiteColor,
                                      fontWeight: FontWeight.w600,
                                      height: 0,
                                    ),
                                  ),
                                ),
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
