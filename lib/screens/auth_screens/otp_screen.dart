import 'dart:ui' as ui;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:single_clik/constants/constant_color.dart';
import 'package:single_clik/constants/firebase_services.dart';
import 'package:single_clik/constants/show_toast.dart';
import 'package:single_clik/controller/auth_controller/otp_controller.dart';
import 'package:single_clik/screens/home_tab_bar_screen.dart';
import 'package:single_clik/widget/app_button.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../controller/auth_controller/mobile_number_controller.dart';
import '../../utils/shar_preferences.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({
    super.key,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  TextEditingController txtOTP1 = TextEditingController();
  TextEditingController txtOTP2 = TextEditingController();
  TextEditingController txtOTP3 = TextEditingController();
  TextEditingController txtOTP4 = TextEditingController();
  TextEditingController txtOTP5 = TextEditingController();
  TextEditingController txtOTP6 = TextEditingController();

  FocusNode otp1FocusNode = FocusNode();
  FocusNode otp2FocusNode = FocusNode();
  FocusNode otp3FocusNode = FocusNode();
  FocusNode otp4FocusNode = FocusNode();
  FocusNode otp5FocusNode = FocusNode();
  FocusNode otp6FocusNode = FocusNode();

  late MobileNumberController mobileNumberController;
  late OTPController otpController;
  int backspaceCount = 0;
  RxBool checkTermsCondition = false.obs;
  final controller = WebViewController();

  @override
  void initState() {
    super.initState();
    debugPrint('=== OtpScreen Initialized ===');

    // Initialize controllers
    mobileNumberController = Get.find<MobileNumberController>();
    otpController = Get.find<OTPController>();

    debugPrint(
        'Mobile Number from controller: ${mobileNumberController.mobileNumberController.value.text}');
    debugPrint(
        'Verification ID from controller: ${otpController.verify.value}');
    debugPrint(
        'Resend Token from controller: ${otpController.resendToken.value}');
    debugPrint('Stored Password: ${mobileNumberController.password.value}');

    // Start timer if not already started
    if (otpController.start.value == 60) {
      debugPrint('Timer already running');
    } else {
      debugPrint('Starting timer');
      otpController.startTimer();
    }
  }

  @override
  void dispose() {
    debugPrint('=== OtpScreen Disposed ===');
    txtOTP1.dispose();
    txtOTP2.dispose();
    txtOTP3.dispose();
    txtOTP4.dispose();
    txtOTP5.dispose();
    txtOTP6.dispose();
    otp1FocusNode.dispose();
    otp2FocusNode.dispose();
    otp3FocusNode.dispose();
    otp4FocusNode.dispose();
    otp5FocusNode.dispose();
    otp6FocusNode.dispose();
    super.dispose();
  }

  Future<void> _verifyOTPAndLogin() async {
    debugPrint('=== _verifyOTPAndLogin Started ===');
    debugPrint('OTP entered - Field1: ${txtOTP1.text}');
    debugPrint('OTP entered - Field2: ${txtOTP2.text}');
    debugPrint('OTP entered - Field3: ${txtOTP3.text}');
    debugPrint('OTP entered - Field4: ${txtOTP4.text}');
    debugPrint('OTP entered - Field5: ${txtOTP5.text}');
    debugPrint('OTP entered - Field6: ${txtOTP6.text}');

    // Unfocus all OTP fields
    for (var focusNode in [
      otp1FocusNode,
      otp2FocusNode,
      otp3FocusNode,
      otp4FocusNode,
      otp5FocusNode,
      otp6FocusNode
    ]) {
      focusNode.unfocus();
    }

    // Validate OTP input fields
    List<TextEditingController> otpControllers = [
      txtOTP1,
      txtOTP2,
      txtOTP3,
      txtOTP4,
      txtOTP5,
      txtOTP6
    ];

    for (int i = 0; i < otpControllers.length; i++) {
      if (otpControllers[i].text.trim().isEmpty) {
        debugPrint('OTP field ${i + 1} is empty');
        [
          otp1FocusNode,
          otp2FocusNode,
          otp3FocusNode,
          otp4FocusNode,
          otp5FocusNode,
          otp6FocusNode
        ][i]
            .requestFocus();
        return;
      }
    }

    // Construct OTP from input fields
    String fullOTP = otpControllers.map((controller) => controller.text).join();
    otpController.otp.value = fullOTP;
    debugPrint('Full OTP entered: $fullOTP');

    otpController.isButtonLoading.value = true;

    // Check for missing verification ID
    if (otpController.verify.value.isEmpty) {
      debugPrint('ERROR: Verification ID is missing!');
      debugPrint('Verification ID value: ${otpController.verify.value}');
      ShowToast.showToast("Verification ID is missing. Please retry.",
          showSuccess: false);
      otpController.isButtonLoading.value = false;
      return;
    }

    debugPrint('Verification ID present: ${otpController.verify.value}');

    // Check for missing OTP value
    if (otpController.otp.value.trim().isEmpty) {
      debugPrint('ERROR: OTP is empty');
      ShowToast.showToast("Please enter a valid OTP", showSuccess: false);
      otpController.isButtonLoading.value = false;
      return;
    }

    try {
      debugPrint('Creating PhoneAuthCredential with:');
      debugPrint('  VerificationId: ${otpController.verify.value}');
      debugPrint('  SMSCode: ${otpController.otp.value}');

      // Create credentials using the provided OTP
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: otpController.verify.value,
        smsCode: otpController.otp.value,
      );
      debugPrint('PhoneAuthCredential created successfully');

      // Sign in with OTP credential
      debugPrint('Attempting to sign in with credential...');
      UserCredential userCredential =
          await otpController.auth.signInWithCredential(credential);
      debugPrint('Firebase Auth Successful!');
      debugPrint('User UID: ${userCredential.user?.uid}');
      debugPrint('User Phone: ${userCredential.user?.phoneNumber}');

      if (userCredential.user != null) {
        debugPrint(
            'Firebase Authentication successful for user: ${userCredential.user!.uid}');

        // Get the stored password from MobileNumberController
        String password = mobileNumberController.password.value;
        String mobileNumber =
            mobileNumberController.mobileNumberController.value.text.trim();

        debugPrint('Mobile Number: $mobileNumber');
        debugPrint('Stored Password: $password');

        if (password.isEmpty) {
          debugPrint(
              'WARNING: Password is empty! Trying to fetch from API again...');
          // If password is empty, try to get it from API again
          final response = await otpController.postCheckMobileApi({
            "mobile": mobileNumber,
          });
          debugPrint('Re-fetch password response: $response');

          if (response['code'] == 200) {
            password = response['data'].toString();
            debugPrint('Password fetched from API: $password');
          } else {
            debugPrint('Failed to fetch password from API');
            throw Exception('Failed to get user password');
          }
        }

        final fcmToken = await FirebaseService.getFcmToken();
        debugPrint('Calling postLoginApi with:');
        debugPrint('  Mobile: $mobileNumber');
        debugPrint('  Password: $password');
        debugPrint('  Device ID (FCM Token): $fcmToken');

        // Call API for login verification
        final response = await otpController.postLoginApi({
          "mobile": mobileNumber,
          "password": password, // Use the actual password from signup response
          "device_id": fcmToken,
        });

        debugPrint('Login API Response Code: ${response['code']}');
        debugPrint('Login API Response Message: ${response['msg']}');
        debugPrint('Full Response: $response');

        if (response['code'] == 200) {
          debugPrint('✓ Login Successful! Navigating to HomeTabBarScreen');
          otpController.isButtonLoading.value = false;
          ShowToast.showToast("Login Successful!", showSuccess: true);
          Get.offAll(() => const HomeTabBarScreen());
        } else {
          debugPrint('✗ Login failed with code: ${response['code']}');
          otpController.isButtonLoading.value = false;
          ShowToast.showToast(response['msg'] ?? "Login failed",
              showSuccess: false);
        }
      } else {
        debugPrint('ERROR: Firebase authentication returned null user');
        throw Exception('Firebase authentication failed');
      }
    } on FirebaseAuthException catch (error) {
      debugPrint('=== FirebaseAuthException caught ===');
      debugPrint('Error Code: ${error.code}');
      debugPrint('Error Message: ${error.message}');
      debugPrint('Full Error: $error');
      debugPrint('Stack trace: ${StackTrace.current}');

      EasyLoading.dismiss();
      otpController.isButtonLoading.value = false;

      switch (error.code) {
        case 'invalid-verification-code':
          debugPrint('Invalid OTP entered');
          ShowToast.showToast("Invalid OTP. Please try again.",
              showSuccess: false);
          break;
        case 'too-many-requests':
          debugPrint('Too many OTP verification attempts');
          ShowToast.showToast("Too many attempts. Please try again later.",
              showSuccess: false);
          break;
        case 'session-expired':
          debugPrint('Session expired');
          ShowToast.showToast("Session expired. Please request a new OTP.",
              showSuccess: false);
          break;
        case 'invalid-phone-number':
          debugPrint('Invalid phone number');
          ShowToast.showToast("Invalid phone number", showSuccess: false);
          break;
        case 'network-error':
          debugPrint('Network error occurred');
          ShowToast.showToast("Network error. Check your connection.",
              showSuccess: false);
          break;
        default:
          debugPrint('Unknown Firebase error');
          ShowToast.showToast(error.message ?? "Verification failed",
              showSuccess: false);
      }
    } catch (e) {
      debugPrint('=== General Exception caught ===');
      debugPrint('Error: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      otpController.isButtonLoading.value = false;
      ShowToast.showToast(e.toString(), showSuccess: false);
    }
  }

  Future<void> _resendOTP() async {
    debugPrint('=== Resend OTP requested ===');
    String mobileNumber =
        mobileNumberController.mobileNumberController.value.text.trim();
    debugPrint('Resending OTP to: +91$mobileNumber');

    try {
      otpController.start.value = 60;
      otpController.startTimer();
      debugPrint('Timer reset to 60 seconds');

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: "+91$mobileNumber",
        forceResendingToken: otpController.resendToken.value,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) {
          debugPrint('Resend - verificationCompleted triggered');
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('Resend - verificationFailed: ${e.code} - ${e.message}');
          if (e.code == 'too-many-requests') {
            ShowToast.showToast(
              "Sorry, Too many requests\nPlease try again later...",
              showSuccess: false,
            );
          } else if (e.code == 'unknown') {
            ShowToast.showToast(
              "Sorry, Internal error has occurred\nPlease try again later...",
              showSuccess: false,
            );
          } else {
            ShowToast.showToast(
              "Failed to resend OTP: ${e.message}",
              showSuccess: false,
            );
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          debugPrint('Resend - codeSent triggered');
          debugPrint('New Verification ID: $verificationId');
          debugPrint('New Resend Token: $resendToken');

          otpController.resendToken.value = resendToken ?? 0;
          otpController.verify.value = verificationId;
          debugPrint(
              'Updated verificationId in controller: ${otpController.verify.value}');
          debugPrint(
              'Updated resendToken in controller: ${otpController.resendToken.value}');

          ShowToast.showToast("OTP Resent Successfully", showSuccess: true);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint('Resend - codeAutoRetrievalTimeout: $verificationId');
        },
      );
    } catch (e) {
      debugPrint('Error in resend OTP: $e');
      ShowToast.showToast("Failed to resend OTP. Please try again.",
          showSuccess: false);
    }
  }

  void checkAllOTPFill() {
    String otp1 = txtOTP1.text.trim();
    String otp2 = txtOTP2.text.trim();
    String otp3 = txtOTP3.text.trim();
    String otp4 = txtOTP4.text.trim();
    String otp5 = txtOTP5.text.trim();
    String otp6 = txtOTP6.text.trim();

    if (otp1.isNotEmpty &&
        otp2.isNotEmpty &&
        otp3.isNotEmpty &&
        otp4.isNotEmpty &&
        otp5.isNotEmpty &&
        otp6.isNotEmpty) {
      debugPrint(
          'All OTP fields filled. Full OTP: $otp1$otp2$otp3$otp4$otp5$otp6');
      otp1FocusNode.unfocus();
      otp2FocusNode.unfocus();
      otp3FocusNode.unfocus();
      otp4FocusNode.unfocus();
      otp5FocusNode.unfocus();
      otp6FocusNode.unfocus();

      // Optional: Auto-submit when all fields are filled
      // _verifyOTPAndLogin();
    }
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    debugPrint('=== OtpScreen Building ===');

    return Scaffold(
      backgroundColor: ConstantColor.whiteColor,
      body: Obx(
        () => otpController.isLoading.value
            ? Center(
                child: CircularProgressIndicator(
                  color: ConstantColor.primary,
                ),
              )
            : Stack(
                children: [
                  // ── Main Content ────────────────────────────────────────────
                  Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 30),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: height * 0.01),
                            Text(
                              "WELCOME TO",
                              style: TextStyle(
                                fontSize: 13,
                                color: ConstantColor.grayColor,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "SINGLE",
                                  style: TextStyle(
                                    fontSize: 32,
                                    color: ConstantColor.primary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  " CLIK",
                                  style: TextStyle(
                                    fontSize: 32,
                                    color: ConstantColor.primaryDark,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: height * 0.035),
                            isKeyboardVisible
                                ? const SizedBox()
                                : Center(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.8),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: ConstantColor.primary
                                                .withOpacity(0.1),
                                            blurRadius: 15,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                      padding: const EdgeInsets.all(12),
                                      child: Image.asset(
                                        "assets/images/img_mobile_number.png",
                                        height: height * 0.14,
                                      ),
                                    ),
                                  ),
                            SizedBox(height: height * 0.025),
                            Text(
                              "Enter your OTP to Log in",
                              style: TextStyle(
                                fontSize: 22,
                                color: ConstantColor.blackColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: height * 0.025),
                            Row(
                              children: [
                                Text(
                                  "+91 ${mobileNumberController.mobileNumberController.value.text.trim()}",
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: ConstantColor.blackColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                GestureDetector(
                                  onTap: () {
                                    debugPrint(
                                        'Edit button pressed - going back');
                                    Get.back();
                                  },
                                  child: Image.asset(
                                    "assets/icons/icon_edit.png",
                                    height: 22,
                                    width: 22,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: height * 0.03),
                            Center(
                              child: KeyboardListener(
                                focusNode: FocusNode(),
                                onKeyEvent: (value) {
                                  // Handle backspace for OTP fields
                                  if (value.logicalKey ==
                                      LogicalKeyboardKey.backspace) {
                                    backspaceCount++;
                                    if (backspaceCount == 2) {
                                      backspaceCount = 0;
                                      // Handle backspace navigation logic
                                      if (otp2FocusNode.hasFocus &&
                                          txtOTP2.text.isEmpty) {
                                        otp2FocusNode.unfocus();
                                        otp1FocusNode.requestFocus();
                                      } else if (otp3FocusNode.hasFocus &&
                                          txtOTP3.text.isEmpty) {
                                        otp3FocusNode.unfocus();
                                        otp2FocusNode.requestFocus();
                                      } else if (otp4FocusNode.hasFocus &&
                                          txtOTP4.text.isEmpty) {
                                        otp4FocusNode.unfocus();
                                        otp3FocusNode.requestFocus();
                                      } else if (otp5FocusNode.hasFocus &&
                                          txtOTP5.text.isEmpty) {
                                        otp5FocusNode.unfocus();
                                        otp4FocusNode.requestFocus();
                                      } else if (otp6FocusNode.hasFocus &&
                                          txtOTP6.text.isEmpty) {
                                        otp6FocusNode.unfocus();
                                        otp5FocusNode.requestFocus();
                                      }
                                    }
                                  } else {
                                    backspaceCount = 0;
                                  }
                                },
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: txtOTP1,
                                        focusNode: otp1FocusNode,
                                        textAlign: TextAlign.center,
                                        textInputAction: TextInputAction.next,
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                        ],
                                        keyboardType: TextInputType.number,
                                        maxLength: 1,
                                        decoration: otpInputDecoration,
                                        onChanged: (value) {
                                          debugPrint(
                                              'OTP Field 1 changed: $value');
                                          if (value.trim().isNotEmpty) {
                                            otp1FocusNode.unfocus();
                                            otp2FocusNode.requestFocus();
                                          }
                                          checkAllOTPFill();
                                        },
                                      ),
                                    ),
                                    SizedBox(width: Get.width / 40),
                                    Expanded(
                                      child: TextField(
                                        controller: txtOTP2,
                                        focusNode: otp2FocusNode,
                                        textAlign: TextAlign.center,
                                        textInputAction: TextInputAction.next,
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                        ],
                                        keyboardType: TextInputType.number,
                                        maxLength: 1,
                                        decoration: otpInputDecoration,
                                        onChanged: (value) {
                                          debugPrint(
                                              'OTP Field 2 changed: $value');
                                          if (value.trim().isNotEmpty) {
                                            otp2FocusNode.unfocus();
                                            otp3FocusNode.requestFocus();
                                          }
                                          checkAllOTPFill();
                                        },
                                      ),
                                    ),
                                    SizedBox(width: Get.width / 40),
                                    Expanded(
                                      child: TextField(
                                        controller: txtOTP3,
                                        focusNode: otp3FocusNode,
                                        textAlign: TextAlign.center,
                                        textInputAction: TextInputAction.next,
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                        ],
                                        keyboardType: TextInputType.number,
                                        maxLength: 1,
                                        decoration: otpInputDecoration,
                                        onChanged: (value) {
                                          debugPrint(
                                              'OTP Field 3 changed: $value');
                                          if (value.trim().isNotEmpty) {
                                            otp3FocusNode.unfocus();
                                            otp4FocusNode.requestFocus();
                                          }
                                          checkAllOTPFill();
                                        },
                                      ),
                                    ),
                                    SizedBox(width: Get.width / 40),
                                    Expanded(
                                      child: TextField(
                                        controller: txtOTP4,
                                        focusNode: otp4FocusNode,
                                        textAlign: TextAlign.center,
                                        textInputAction: TextInputAction.next,
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                        ],
                                        keyboardType: TextInputType.number,
                                        maxLength: 1,
                                        decoration: otpInputDecoration,
                                        onChanged: (value) {
                                          debugPrint(
                                              'OTP Field 4 changed: $value');
                                          if (value.trim().isNotEmpty) {
                                            otp4FocusNode.unfocus();
                                            otp5FocusNode.requestFocus();
                                          }
                                          checkAllOTPFill();
                                        },
                                      ),
                                    ),
                                    SizedBox(width: Get.width / 40),
                                    Expanded(
                                      child: TextField(
                                        controller: txtOTP5,
                                        focusNode: otp5FocusNode,
                                        textAlign: TextAlign.center,
                                        textInputAction: TextInputAction.next,
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                        ],
                                        keyboardType: TextInputType.number,
                                        maxLength: 1,
                                        decoration: otpInputDecoration,
                                        onChanged: (value) {
                                          debugPrint(
                                              'OTP Field 5 changed: $value');
                                          if (value.trim().isNotEmpty) {
                                            otp5FocusNode.unfocus();
                                            otp6FocusNode.requestFocus();
                                          }
                                          checkAllOTPFill();
                                        },
                                      ),
                                    ),
                                    SizedBox(width: Get.width / 40),
                                    Expanded(
                                      child: TextField(
                                        controller: txtOTP6,
                                        focusNode: otp6FocusNode,
                                        textAlign: TextAlign.center,
                                        textInputAction: TextInputAction.done,
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                        ],
                                        keyboardType: TextInputType.number,
                                        maxLength: 1,
                                        decoration: otpInputDecoration,
                                        onChanged: (value) {
                                          debugPrint(
                                              'OTP Field 6 changed: $value');
                                          checkAllOTPFill();
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: height * 0.025),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  otpController.start.value == 0
                                      ? "Didn't receive OTP - "
                                      : "Resend OTP in ",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: ConstantColor.blackColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                otpController.start.value != 0
                                    ? Text(
                                        "00:${otpController.start.value.toString().length == 1 ? "0${otpController.start.value}" : otpController.start.value}",
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: ConstantColor.blackColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      )
                                    : GestureDetector(
                                        onTap: _resendOTP,
                                        child: Text(
                                          "Resend",
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: ConstantColor.primary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                              ],
                            ),
                            SizedBox(height: height * 0.035),
                            AppButton(
                              onTap: _verifyOTPAndLogin,
                              title: "Log in",
                              isLoading: otpController.isButtonLoading.value,
                              arrowShow: false,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  InputDecoration otpInputDecoration = InputDecoration(
    filled: true,
    fillColor: Colors.white.withOpacity(0.8),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: ConstantColor.primary.withOpacity(0.3),
        width: 1,
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: ConstantColor.grayColor.withOpacity(0.3),
        width: 1,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: ConstantColor.primary,
        width: 2,
      ),
    ),
    contentPadding: EdgeInsets.symmetric(
        horizontal: Get.width / 35, vertical: Get.width / 25),
    counterText: '',
  );
}
