import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:single_clik/constants/constant_color.dart';
import 'package:single_clik/controller/home_controller/feedback_controller.dart';
import 'package:single_clik/widget/app_button.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  FeedBackController feedBackController = Get.put(FeedBackController());
  FocusNode focusNode = FocusNode();
  FocusNode descriptionFocusNode = FocusNode();
  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;

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
          "Feedback",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: ConstantColor.whiteColor,
          ),
        ),
      ),
      body: Obx(
        () => feedBackController.isLoading.value
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : GestureDetector(
                onTap: () {
                  FocusManager.instance.primaryFocus?.unfocus();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: ListView(children: [
                    SizedBox(height: height * 0.05),
                    Image.asset(
                      'assets/images/feedbackPageLogo.png',
                      height: Get.width / 1.5,
                      width: Get.width / 1.5,
                      fit: BoxFit.cover,
                    ),
                    SizedBox(height: height * 0.06),
                    TextFormField(
                      controller: feedBackController.subjectController.value,
                      onChanged: (value) {},
                      textInputAction: TextInputAction.newline,
                      focusNode: focusNode,
                      maxLength: 80,
                      style: TextStyle(
                        fontSize: 16,
                        color: ConstantColor.blackColor,
                        fontWeight: FontWeight.w500,
                      ),
                      keyboardType: TextInputType.multiline,
                      cursorColor: ConstantColor.blackColor,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        fillColor: ConstantColor.bgColor,
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 15),
                        hintText: "Subject",
                        counterText: "",
                        hintStyle: TextStyle(
                            fontSize: 16,
                            color: ConstantColor.grayColor,
                            fontWeight: FontWeight.w400),
                        filled: true,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(7.0),
                            borderSide: const BorderSide(
                              color: Color(0xffDDDDDD),
                            )),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(7.0),
                            borderSide: const BorderSide(
                              color: Color(0xffDDDDDD),
                            )),
                        disabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(7.0),
                            borderSide: const BorderSide(
                              color: Color(0xffDDDDDD),
                            )),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(7.0),
                            borderSide: const BorderSide(
                              color: Color(0xffDDDDDD),
                            )),
                      ),
                    ),
                    SizedBox(height: height * 0.03),
                    TextFormField(
                      controller:
                          feedBackController.descriptionController.value,
                      onChanged: (value) {},
                      textInputAction: TextInputAction.newline,
                      maxLines: 5,
                      maxLength: 500,
                      focusNode: descriptionFocusNode,
                      style: TextStyle(
                        fontSize: 16,
                        color: ConstantColor.blackColor,
                        fontWeight: FontWeight.w500,
                      ),
                      keyboardType: TextInputType.multiline,
                      cursorColor: ConstantColor.blackColor,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        fillColor: ConstantColor.bgColor,
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 15),
                        hintText: "Description",
                        hintStyle: TextStyle(
                            fontSize: 16,
                            color: ConstantColor.grayColor,
                            fontWeight: FontWeight.w400),
                        filled: true,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(7.0),
                            borderSide: const BorderSide(
                              color: Color(0xffDDDDDD),
                            )),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(7.0),
                            borderSide: const BorderSide(
                              color: Color(0xffDDDDDD),
                            )),
                        disabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(7.0),
                            borderSide: const BorderSide(
                              color: Color(0xffDDDDDD),
                            )),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(7.0),
                            borderSide: const BorderSide(
                              color: Color(0xffDDDDDD),
                            )),
                      ),
                    ),
                    SizedBox(height: height * 0.03),
                    AppButton(
                      onTap: () async {
                        if (feedBackController.subjectController.value.text
                            .trim()
                            .isEmpty) {
                          descriptionFocusNode.unfocus();
                          focusNode.requestFocus();
                          Get.snackbar(
                            "Input Required!",
                            'Please Enter Subject',
                            snackPosition: SnackPosition.BOTTOM,
                          );
                          /* ShowToast.showToast(
                            'Please Enter Subject',
                            showSuccess: false,
                          );*/
                        } else if (feedBackController
                            .descriptionController.value.text
                            .trim()
                            .isEmpty) {
                          focusNode.unfocus();
                          descriptionFocusNode.requestFocus();
                          Get.snackbar(
                            "Input Required!",
                            'Please Enter Description',
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        } else {
                          focusNode.unfocus();
                          descriptionFocusNode.unfocus();
                          await feedBackController.postFeedBackApi();
                          Get.back();
                        }
                      },
                      title: "Submit",
                      arrowShow: false,
                      isLoading: feedBackController.isButtonLoading.value,
                    ),
                    SizedBox(height: height * 0.02),
                  ]),
                ),
              ),
      ),
    );
  }
}
