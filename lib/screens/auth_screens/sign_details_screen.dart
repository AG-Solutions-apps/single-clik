import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:single_clik/constants/constant_color.dart';
import 'package:single_clik/constants/show_toast.dart';
import 'package:single_clik/controller/auth_controller/sign_details_controller.dart';
import 'package:single_clik/widget/app_button.dart';

class SignDetailsScreen extends StatefulWidget {
  final String name;
  final String phoneNumber;

  const SignDetailsScreen({
    super.key,
    required this.name,
    required this.phoneNumber,
  });

  @override
  State<SignDetailsScreen> createState() => _SignDetailsScreenState();
}

class _SignDetailsScreenState extends State<SignDetailsScreen> {
  SignDetailsController signDetailsController =
      Get.put(SignDetailsController());

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: ConstantColor.whiteColor,
      body: Obx(
        () => signDetailsController.isLoading.value
            ? Center(
                child: CircularProgressIndicator(
                  color: ConstantColor.primary,
                ),
              )
            : Stack(
                children: [
                  // ── Main Content ─────────────────────────────
                  SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: height * 0.05),

                          // Back Button
                          GestureDetector(
                            onTap: () => Get.back(),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    ConstantColor.primary.withOpacity(0.15),
                                    ConstantColor.primaryDark.withOpacity(0.05),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                border: Border.all(
                                  color: ConstantColor.primary.withOpacity(0.3),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        ConstantColor.primary.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.arrow_back_rounded,
                                color: ConstantColor.primary,
                                size: 24,
                              ),
                            ),
                          ),

                          SizedBox(height: height * 0.02),

                          // Welcome Section
                          Center(
                            child: TweenAnimationBuilder(
                              tween: Tween<double>(begin: 0, end: 1),
                              duration: const Duration(milliseconds: 800),
                              builder: (context, double value, child) {
                                return Opacity(
                                  opacity: value,
                                  child: Transform.translate(
                                    offset: Offset(0, 20 * (1 - value)),
                                    child: child,
                                  ),
                                );
                              },
                              child: Column(
                                children: [
                                  Text(
                                    "WELCOME TO",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: ConstantColor.grayColor,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                  SizedBox(height: height * 0.008),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      ShaderMask(
                                        shaderCallback: (bounds) =>
                                            LinearGradient(
                                          colors: [
                                            ConstantColor.primary,
                                            ConstantColor.primaryDark,
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ).createShader(bounds),
                                        child: const Text(
                                          "SINGLE",
                                          style: TextStyle(
                                            fontSize: 38,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 1,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        " CLIK",
                                        style: TextStyle(
                                          fontSize: 38,
                                          color: ConstantColor.primaryDark,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(height: height * 0.03),

                          // Hello Message Card
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  ConstantColor.primary.withOpacity(0.08),
                                  ConstantColor.primaryDark.withOpacity(0.05),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: ConstantColor.primary.withOpacity(0.2),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: ConstantColor.primary.withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Hello! 👋",
                                  style: TextStyle(
                                    fontSize: 24,
                                    color: ConstantColor.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: height * 0.005),
                                Text(
                                  widget.name,
                                  style: TextStyle(
                                    fontSize: 28,
                                    color: ConstantColor.blackColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: height * 0.01),
                                Text(
                                  "Let's complete your profile to get started",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: ConstantColor.grayColor,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: height * 0.03),

                          // Email Field
                          _buildLabelWithAsterisk("Email ID"),
                          SizedBox(height: height * 0.008),
                          _buildTextField(
                            controller:
                                signDetailsController.emailController.value,
                            hint: "Enter your email address",
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            action: TextInputAction.next,
                          ),

                          SizedBox(height: height * 0.02),

                          // Area Field
                          _buildLabelWithAsterisk("Area"),
                          SizedBox(height: height * 0.008),
                          _buildTextField(
                            controller:
                                signDetailsController.areaController.value,
                            hint: "Enter your area (e.g., Bangalore, Mumbai)",
                            icon: Icons.location_on_outlined,
                            keyboardType: TextInputType.text,
                            action: TextInputAction.next,
                          ),

                          SizedBox(height: height * 0.02),

                          // Referred Code Field
                          Text(
                            "Referred Code (Optional)",
                            style: TextStyle(
                              fontSize: 16,
                              color: ConstantColor.blackColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: height * 0.008),
                          _buildReferralTextField(
                            controller: signDetailsController
                                .referredCodeController.value,
                            hint: "Enter referred code (if any)",
                            icon: Icons.card_giftcard_outlined,
                            onVerifyTap: () async {
                              FocusScope.of(context).unfocus();
                              await signDetailsController.checkReferralApi(
                                signDetailsController
                                    .referredCodeController.value.text,
                              );
                            },
                          ),
                          Obx(() {
                            if (signDetailsController
                                .referralMessage.value.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            final isSuccess =
                                signDetailsController.isReferralVerified.value;
                            return Padding(
                              padding: const EdgeInsets.only(top: 6, left: 4),
                              child: Row(
                                children: [
                                  Icon(
                                    isSuccess
                                        ? Icons.check_circle_rounded
                                        : Icons.cancel_rounded,
                                    color:
                                        isSuccess ? Colors.green : Colors.red,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      signDetailsController
                                          .referralMessage.value,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: isSuccess
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),

                          SizedBox(height: height * 0.025),

                          // Photo Upload Section
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  ConstantColor.primary.withOpacity(0.05),
                                  ConstantColor.primaryDark.withOpacity(0.02),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: ConstantColor.primary.withOpacity(0.15),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      ConstantColor.primary.withOpacity(0.08),
                                  blurRadius: 15,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Upload your Photo",
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: ConstantColor.blackColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(height: height * 0.005),
                                    Text(
                                      "Optional • Max 5MB",
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: ConstantColor.grayColor,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                                GestureDetector(
                                  onTap: () async {
                                    final ImagePicker picker = ImagePicker();
                                    final XFile? image = await picker.pickImage(
                                      source: ImageSource.gallery,
                                    );
                                    if (image != null) {
                                      signDetailsController.cropImage(image);
                                    }
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    height: 85,
                                    width: 85,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.white,
                                          ConstantColor.primary
                                              .withOpacity(0.05),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: ConstantColor.primary
                                            .withOpacity(0.4),
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: ConstantColor.primary
                                              .withOpacity(0.15),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: signDetailsController
                                                    .croppedProfileFile !=
                                                null &&
                                            signDetailsController
                                                .croppedProfileFile!
                                                .value
                                                .path
                                                .isNotEmpty
                                        ? ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(14),
                                            child: Image.file(
                                              File(signDetailsController
                                                  .croppedProfileFile!
                                                  .value
                                                  .path),
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : Center(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.camera_alt_outlined,
                                                  color: ConstantColor.primary,
                                                  size: 28,
                                                ),
                                                SizedBox(
                                                    height: height * 0.005),
                                                Text(
                                                  "Add Photo",
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color:
                                                        ConstantColor.primary,
                                                    fontWeight: FontWeight.w500,
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

                          SizedBox(height: height * 0.04),

                          // Continue Button
                          TweenAnimationBuilder(
                            tween: Tween<double>(begin: 0, end: 1),
                            duration: const Duration(milliseconds: 600),
                            builder: (context, double value, child) {
                              return Opacity(
                                opacity: value,
                                child: Transform.translate(
                                  offset: Offset(0, 30 * (1 - value)),
                                  child: child,
                                ),
                              );
                            },
                            child: AppButton(
                              onTap: () async {
                                if (signDetailsController
                                    .emailController.value.text.isEmpty) {
                                  ShowToast.showToast("Please Enter Email ID",
                                      showSuccess: false);
                                } else if (!RegExp(
                                        r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                                    .hasMatch(signDetailsController
                                        .emailController.value.text
                                        .trim())) {
                                  ShowToast.showToast(
                                      "Please Enter Valid Email ID",
                                      showSuccess: false);
                                } else if (signDetailsController
                                    .areaController.value.text.isEmpty) {
                                  ShowToast.showToast("Please Enter Area",
                                      showSuccess: false);
                                } else {
                                  String referralCodeToSend = "";
                                  String enteredCode = signDetailsController
                                      .referredCodeController.value.text
                                      .trim();

                                  if (enteredCode.isNotEmpty) {
                                    if (signDetailsController
                                            .isReferralVerified.value &&
                                        enteredCode ==
                                            signDetailsController
                                                .verifiedReferralCode.value) {
                                      referralCodeToSend = enteredCode;
                                    } else {
                                      bool isValid = await signDetailsController
                                          .checkReferralApi(enteredCode);
                                      if (isValid) {
                                        referralCodeToSend = enteredCode;
                                      } else {
                                        // Invalid code: do NOT send code to backend
                                        referralCodeToSend = "";
                                      }
                                    }
                                  }

                                  Map<String, String> bodyParams = {
                                    'person_name': widget.name.trim(),
                                    'person_mobile': widget.phoneNumber.trim(),
                                    'person_email': signDetailsController
                                        .emailController.value.text
                                        .trim(),
                                    'person_area': signDetailsController
                                        .areaController.value.text
                                        .trim(),
                                    'referred_by_code': referralCodeToSend,
                                    'user_type': '1',
                                  };
                                  await signDetailsController.postSignUpApi(
                                    bodyParams,
                                    signDetailsController
                                                    .croppedProfileFile !=
                                                null &&
                                            signDetailsController
                                                .croppedProfileFile!
                                                .value
                                                .path
                                                .isNotEmpty
                                        ? signDetailsController
                                            .croppedProfileFile!.value.path
                                            .trim()
                                        : signDetailsController.filePath.value
                                            .trim(),
                                  );
                                }
                              },
                              isLoading:
                                  signDetailsController.isButtonLoading.value,
                              title: "Continue",
                            ),
                          ),

                          SizedBox(height: height * 0.05),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ── Reusable text field ───────────────────────────────────────────────────

  Widget _buildReferralTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required VoidCallback onVerifyTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xffF7F8FA), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffEBEFF2), width: 1),
        boxShadow: [
          BoxShadow(
            color: ConstantColor.primary.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.done,
              textCapitalization: TextCapitalization.characters,
              onChanged: (val) {
                if (signDetailsController
                        .verifiedReferralCode.value.isNotEmpty &&
                    val.trim() !=
                        signDetailsController.verifiedReferralCode.value) {
                  signDetailsController.resetReferralStatus();
                } else if (signDetailsController
                        .referralMessage.value.isNotEmpty &&
                    val.trim().isEmpty) {
                  signDetailsController.resetReferralStatus();
                }
              },
              style: TextStyle(fontSize: 16, color: ConstantColor.blackColor),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle:
                    TextStyle(fontSize: 14, color: ConstantColor.grayColor),
                prefixIcon: Icon(icon, color: ConstantColor.primary, size: 22),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
          ),
          Obx(() {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: signDetailsController.isVerifyingReferral.value
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: ConstantColor.primary,
                      ),
                    )
                  : TextButton(
                      onPressed: onVerifyTap,
                      style: TextButton.styleFrom(
                        backgroundColor: ConstantColor.primary.withOpacity(0.1),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        "Verify",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: ConstantColor.primary,
                        ),
                      ),
                    ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required TextInputType keyboardType,
    required TextInputAction action,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xffF7F8FA), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffEBEFF2), width: 1),
        boxShadow: [
          BoxShadow(
            color: ConstantColor.primary.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        textInputAction: action,
        style: TextStyle(fontSize: 16, color: ConstantColor.blackColor),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(fontSize: 14, color: ConstantColor.grayColor),
          prefixIcon: Icon(icon, color: ConstantColor.primary, size: 22),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  // ── Label with red asterisk ───────────────────────────────────────────────

  Widget _buildLabelWithAsterisk(String label) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: label,
            style: TextStyle(
              fontSize: 16,
              color: ConstantColor.blackColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const TextSpan(
            text: " *",
            style: TextStyle(
              fontSize: 16,
              color: Colors.red,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
