import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:single_clik/constants/constant_color.dart';
import 'package:single_clik/constants/show_toast.dart';
import 'package:single_clik/controller/auth_controller/sign_name_controller.dart';
import 'package:single_clik/widget/app_button.dart';
import 'package:single_clik/widget/app_text_field.dart';

import 'sign_details_screen.dart';

class SignNameScreen extends StatefulWidget {
  final String phoneNumber;

  const SignNameScreen({super.key, required this.phoneNumber});

  @override
  State<SignNameScreen> createState() => _SignNameScreenState();
}

class _SignNameScreenState extends State<SignNameScreen> {
  SignNameController signNameController = Get.put(SignNameController());

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      body: Obx(
        () => signNameController.isLoading.value
            ? Center(
                child: CircularProgressIndicator(color: ConstantColor.primary),
              )
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: height * 0.08),
                      Center(
                        child: Image.asset(
                          "assets/images/sc_logo_new.png",
                          height: height * 0.25,
                        ),
                      ),
                      SizedBox(height: height * 0.04),
                      // Text(
                      //   "Welcome to",
                      //   style: TextStyle(
                      //     fontSize: 23,
                      //     color: ConstantColor.blackColor,
                      //     fontWeight: FontWeight.w400,
                      //     height: 0,
                      //   ),
                      // ),
                      // Text(
                      //   "Single Click",
                      //   style: TextStyle(
                      //     fontSize: 38,
                      //     color: ConstantColor.primary,
                      //     fontWeight: FontWeight.w400,
                      //     height: 0,
                      //   ),
                      // ),
                      Center(
                        child: Text(
                          "WELCOME TO",
                          style: TextStyle(
                            fontSize: 16,
                            color: ConstantColor.grayColor,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      SizedBox(height: height * 0.01),
                      Center(
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "SINGLE",
                                style: TextStyle(
                                  fontSize: 40,
                                  color: ConstantColor.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                " CLIK",
                                style: TextStyle(
                                  fontSize: 40,
                                  color: ConstantColor.primaryDark,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ]),
                      ),
                      SizedBox(height: height * 0.04),
                      Text(
                        "Hello!👋",
                        style: TextStyle(
                          fontSize: 24,
                          color: ConstantColor.primary,
                          fontWeight: FontWeight.w400,
                          height: 0,
                        ),
                      ),
                      Text(
                        "What we call you",
                        style: TextStyle(
                          fontSize: 24,
                          color: ConstantColor.blackColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: height * 0.03),
                      Text(
                        "Enter your full name",
                        style: TextStyle(
                          fontSize: 20,
                          color: ConstantColor.grayColor,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      SizedBox(height: height * 0.03),
                      appTextFormField(
                        keyboardType: TextInputType.name,
                        textAlign: TextAlign.center,
                        hintText: "Full Name",
                        textInputAction: TextInputAction.done,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 0, vertical: 5),
                        controller: signNameController.nameController.value,
                      ),
                      SizedBox(height: height * 0.1),
                      Center(
                        child: AppButton(
                          onTap: () {
                            if (signNameController
                                .nameController.value.text.isEmpty) {
                              ShowToast.showToast(
                                "Please Enter Full Name",
                                showSuccess: false,
                              );
                            } else {
                              Get.to(() => SignDetailsScreen(
                                    name: signNameController
                                        .nameController.value.text,
                                    phoneNumber: widget.phoneNumber,
                                  ));
                            }
                          },
                          title: "Continue",
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
}
