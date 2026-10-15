import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:multi_dropdown/multi_dropdown.dart';
import 'package:single_clik/constants/constant_color.dart';
import 'package:single_clik/constants/show_toast.dart';
import 'package:single_clik/controller/auth_controller/business_sign_up_controller.dart';
import 'package:single_clik/controller/auth_controller/mobile_number_controller.dart';
import 'package:single_clik/controller/auth_controller/otp_controller.dart';
import 'package:single_clik/controller/home_controller/home_controller.dart';
import 'package:single_clik/controller/home_controller/profile_controller.dart';
import 'package:single_clik/screens/auth_screens/mobile_number_screen.dart';
import 'package:single_clik/screens/auth_screens/otp_screen.dart';
import 'package:single_clik/screens/home_tab_bar_screen.dart';
import 'package:single_clik/utils/shar_preferences.dart';
import 'package:single_clik/widget/app_button.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../constants/constant_string.dart';

class BusinessSignUpPage extends StatefulWidget {
  final bool? newAccount;

  const BusinessSignUpPage({super.key, this.newAccount});

  @override
  State<BusinessSignUpPage> createState() => _BusinessSignUpPageState();
}

class _BusinessSignUpPageState extends State<BusinessSignUpPage> {
  double height = Get.height;
  double width = Get.width;
  RxBool checkTermsCondition = false.obs;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  late MultiSelectController<Map<String, dynamic>> multiSelectController;

  late BusinessSignUpController businessSignUpController;
  late HomeController homeController;

  final FocusNode nameFocusNode = FocusNode();
  final FocusNode mobileNumberFocusNode = FocusNode();
  final FocusNode emailFocusNode = FocusNode();
  final FocusNode categoryFocusNode = FocusNode();
  final FocusNode subCategoryFocusNode = FocusNode();
  final FocusNode whatsappNumberFocusNode = FocusNode();
  final FocusNode aboutFocusNode = FocusNode();
  final FocusNode areaFocusNode = FocusNode();

  WebViewController? webViewController;

  @override
  void initState() {
    super.initState();

    multiSelectController = MultiSelectController<Map<String, dynamic>>();

    if (Get.isRegistered<BusinessSignUpController>()) {
      businessSignUpController = Get.find<BusinessSignUpController>();
    } else {
      businessSignUpController = Get.put(BusinessSignUpController());
    }

    if (Get.isRegistered<HomeController>()) {
      homeController = Get.find<HomeController>();
    } else {
      homeController = Get.put(HomeController());
    }

    if (widget.newAccount != true) {
      _preFillUserData();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadCategories();
    });
  }

  void _preFillUserData() {
    final userData = homeController.userData;
    if (userData.isNotEmpty) {
      businessSignUpController.txtCompanyName.value.text =
          userData['company_name']?.toString() ?? '';
      businessSignUpController.selectedProfileType.value =
          _getProfileTypeValue(userData['profile_type']?.toString() ?? '');
      businessSignUpController.txtWhatsappNo.value.text =
          userData['whatsapp']?.toString() ?? '';
      businessSignUpController.txtWebsite.value.text =
          userData['website']?.toString() ?? '';
      businessSignUpController.txtAbout.value.text =
          userData['about_us']?.toString() ?? '';
      businessSignUpController.txtArea.value.text =
          userData['area']?.toString() ?? '';
      businessSignUpController.filePath.value =
          userData['photo']?.toString() ?? '';
    }
  }

  String _getProfileTypeValue(String profileType) {
    switch (profileType) {
      case '0':
        return 'Business';
      case '1':
        return 'Service';
      case '0,1':
        return 'Business/Service';
      default:
        return '';
    }
  }

  @override
  void dispose() {
    nameFocusNode.dispose();
    mobileNumberFocusNode.dispose();
    emailFocusNode.dispose();
    categoryFocusNode.dispose();
    subCategoryFocusNode.dispose();
    whatsappNumberFocusNode.dispose();
    aboutFocusNode.dispose();
    areaFocusNode.dispose();
    webViewController?.clearCache();
    super.dispose();
  }

  Future<void> loadCategories() async {
    try {
      final categories = await businessSignUpController.getCategoryDataApi();
      businessSignUpController.categoryDataList.value = categories;

      if (widget.newAccount != true &&
          homeController.userData['category_id'] != null) {
        final categoryId = homeController.userData['category_id'].toString();
        final selectedCat = categories.firstWhere(
          (cat) => cat['id'].toString() == categoryId,
          orElse: () => <String, dynamic>{},
        );
        if (selectedCat.isNotEmpty) {
          businessSignUpController.selectedCategory.value = selectedCat;
          await _loadSubCategories(selectedCat['id'].toString());

          final subCategoryIds =
              (homeController.userData['sub_category_id']?.toString() ?? '')
                  .split(',');
          if (subCategoryIds.isNotEmpty && subCategoryIds.first.isNotEmpty) {
            await Future.delayed(const Duration(milliseconds: 500));
            final List<DropdownItem<Map<String, dynamic>>> selectedItems = [];
            for (var sub in businessSignUpController.subCategoryDataList) {
              if (subCategoryIds.contains(sub['id'].toString())) {
                selectedItems.add(DropdownItem<Map<String, dynamic>>(
                  value: sub,
                  label: sub['subcategory'].toString(),
                ));
              }
            }
            multiSelectController.setItems(selectedItems);
          }
        }
      }
    } catch (error) {
      debugPrint('Error loading categories: $error');
    }
  }

  Future<void> _loadSubCategories(String categoryId) async {
    try {
      EasyLoading.show(status: ConstantString.pleaseWaitLabel);
      final subCategories =
          await businessSignUpController.getSubCategoryDataCategoryIdWiseApi(
        parameters: {'category_id': categoryId},
      );
      businessSignUpController.subCategoryDataList.value = subCategories;

      final List<DropdownItem<Map<String, dynamic>>> items = [];
      for (var element in subCategories) {
        items.add(DropdownItem<Map<String, dynamic>>(
          value: element,
          label: element['subcategory'].toString(),
        ));
      }
      multiSelectController.setItems(items);
      EasyLoading.dismiss();
    } catch (error) {
      EasyLoading.dismiss();
      debugPrint('Error loading subcategories: $error');
    }
  }

  WebViewController _getWebViewController() {
    if (webViewController == null) {
      webViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (String url) {
              debugPrint('Page finished loading: $url');
            },
          ),
        );
    }
    return webViewController!;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Form(
          key: formKey,
          child: Obx(
            () => SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: height * 0.04),
                  _buildHeader(),
                  SizedBox(height: height * 0.02),
                  _buildTitle(),
                  widget.newAccount == true
                      ? _buildNewAccountForm()
                      : _buildExistingAccountForm(),
                  SizedBox(height: height * 0.03),
                  _buildTermsAndConditions(),
                  SizedBox(height: height * 0.01),
                  _buildSubmitButton(),
                  SizedBox(height: height * 0.03),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "WELCOME TO",
                style: TextStyle(
                  fontSize: 16,
                  color: ConstantColor.grayColor,
                  fontWeight: FontWeight.w400,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "SINGLE",
                    style: TextStyle(
                      fontSize: 35,
                      color: ConstantColor.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    " CLIK",
                    style: TextStyle(
                      fontSize: 35,
                      color: ConstantColor.primaryDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Image.asset(
          "assets/images/sc_logo_new.png",
          height: width * 0.28,
          width: width * 0.28,
          errorBuilder: (context, error, stackTrace) => SizedBox(
            height: width * 0.28,
            width: width * 0.28,
            child: Icon(Icons.business, size: 50),
          ),
        ),
      ],
    );
  }

  Widget _buildTitle() {
    return Text(
      widget.newAccount == true
          ? "Create your Business Account"
          : "Update My Business / Services",
      style: TextStyle(
        fontSize: 24,
        color: ConstantColor.blackColor,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildNewAccountForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFullNameField(),
        SizedBox(height: height * 0.03),
        _buildCompanyNameField(),
        SizedBox(height: height * 0.03),
        _buildMobileNumberField(),
        SizedBox(height: height * 0.03),
        _buildEmailField(),
        _buildProfileTypeDropdown(),
        _buildCategorySubcategoryFields(),
        _buildWhatsappField(),
        _buildWebsiteField(),
        _buildAboutField(),
        _buildAreaField(),
        _buildReferredCodeField(),
        _buildPhotoUploadField(),
      ],
    );
  }

  Widget _buildExistingAccountForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfilePhoto(),
            SizedBox(width: width * 0.02),
            Expanded(child: _buildUserInfo()),
          ],
        ),
        SizedBox(height: height * 0.03),
        _buildCompanyNameField(),
        _buildProfileTypeDropdown(),
        _buildCategorySubcategoryFields(),
        _buildWhatsappField(),
        _buildWebsiteField(),
        _buildAboutField(),
        _buildAreaField(),
      ],
    );
  }

  Widget _buildFullNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: "Full Name", style: _textFieldLabelTextStyle),
              TextSpan(
                text: "*",
                style: _textFieldLabelTextStyle.copyWith(color: Colors.red),
              ),
            ],
          ),
        ),
        TextFormField(
          controller: businessSignUpController.txtFullName.value,
          keyboardType: TextInputType.name,
          focusNode: nameFocusNode,
          style: _textFieldTextStyle,
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.words,
          decoration: _inputDecoration(hintText: "Enter your full name"),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your full name';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCompanyNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Company Name", style: _textFieldLabelTextStyle),
        TextFormField(
          controller: businessSignUpController.txtCompanyName.value,
          keyboardType: TextInputType.name,
          style: _textFieldTextStyle,
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.words,
          decoration: _inputDecoration(hintText: "Enter your Company name"),
        ),
      ],
    );
  }

  Widget _buildMobileNumberField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: "Mobile Number", style: _textFieldLabelTextStyle),
              TextSpan(
                text: "*",
                style: _textFieldLabelTextStyle.copyWith(color: Colors.red),
              ),
            ],
          ),
        ),
        TextFormField(
          controller: businessSignUpController.txtMobileNo.value,
          keyboardType: TextInputType.phone,
          focusNode: mobileNumberFocusNode,
          style: _textFieldTextStyle,
          maxLength: 10,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textInputAction: TextInputAction.next,
          decoration: _inputDecoration(
            hintText: "Enter your Mobile number",
            prefixIcon: Padding(
              padding: const EdgeInsets.only(top: 5, bottom: 5, right: 20),
              child: Text(
                "+91",
                style: TextStyle(
                  fontSize: 22,
                  color: ConstantColor.blackColor,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your mobile number';
            } else if (value.trim().length != 10) {
              return 'Please enter a valid 10-digit mobile number';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: "Email ID", style: _textFieldLabelTextStyle),
              TextSpan(
                text: "*",
                style: _textFieldLabelTextStyle.copyWith(color: Colors.red),
              ),
            ],
          ),
        ),
        TextFormField(
          controller: businessSignUpController.txtEmailId.value,
          keyboardType: TextInputType.emailAddress,
          focusNode: emailFocusNode,
          style: _textFieldTextStyle,
          textInputAction: TextInputAction.next,
          decoration: _inputDecoration(hintText: "Enter your Email id"),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your email id';
            } else if (!RegExp(
                    r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                .hasMatch(value.trim())) {
              return 'Please enter a valid email id';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildProfileTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: height * 0.03),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: "Profile Type", style: _textFieldLabelTextStyle),
              TextSpan(
                text: "*",
                style: _textFieldLabelTextStyle.copyWith(color: Colors.red),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: ConstantColor.grayColor)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              dropdownColor: ConstantColor.whiteColor,
              style: _textFieldTextStyle,
              hint: Text("Select one", style: _textFieldHintTextStyle),
              isExpanded: true,
              value: businessSignUpController.selectedProfileType.value.isEmpty
                  ? null
                  : businessSignUpController.selectedProfileType.value,
              items: businessSignUpController.profileTypeList
                  .map((element) => DropdownMenuItem<String>(
                        value: element,
                        child: Text(element, style: _textFieldTextStyle),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  businessSignUpController.selectedProfileType.value = value;
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySubcategoryFields() {
    if (businessSignUpController.isLoadingCategories.value) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: height * 0.03),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (businessSignUpController.categoryDataList.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: height * 0.03),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: "Category", style: _textFieldLabelTextStyle),
                TextSpan(
                  text: "*",
                  style: _textFieldLabelTextStyle.copyWith(color: Colors.red),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border:
                  Border(bottom: BorderSide(color: ConstantColor.grayColor)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Map<String, dynamic>>(
                dropdownColor: ConstantColor.whiteColor,
                style: _textFieldTextStyle,
                hint: Text("Select one", style: _textFieldHintTextStyle),
                isExpanded: true,
                value: businessSignUpController.selectedCategory.isEmpty ||
                        businessSignUpController.selectedCategory['id'] == null
                    ? null
                    : businessSignUpController.categoryDataList.firstWhere(
                        (element) =>
                            element['id'].toString() ==
                            businessSignUpController.selectedCategory['id']
                                .toString(),
                        orElse: () => <String, dynamic>{},
                      ),
                items: businessSignUpController.categoryDataList
                    .map((element) => DropdownMenuItem<Map<String, dynamic>>(
                          value: element,
                          child: Text(
                            element['category'].toString(),
                            style: _textFieldTextStyle,
                          ),
                        ))
                    .toList(),
                onChanged: (value) async {
                  if (value != null) {
                    await _loadSubCategories(value['id'].toString());
                    businessSignUpController.selectedCategory.value = value;
                  }
                },
              ),
            ),
          ),
          SizedBox(height: height * 0.03),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: "Sub Category", style: _textFieldLabelTextStyle),
                TextSpan(
                  text: "*",
                  style: _textFieldLabelTextStyle.copyWith(color: Colors.red),
                ),
              ],
            ),
          ),
          if (businessSignUpController.subCategoryDataList.isEmpty &&
              businessSignUpController.selectedCategory.isNotEmpty)
            TextFormField(
              controller: businessSignUpController.txtOtherSubCategory.value,
              keyboardType: TextInputType.name,
              style: _textFieldTextStyle,
              focusNode: subCategoryFocusNode,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              decoration: _inputDecoration(hintText: "Enter your Sub Category"),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your sub category';
                }
                return null;
              },
            )
          else
            MultiDropdown<Map<String, dynamic>>(
              items: businessSignUpController.subCategoryDataList
                  .map((element) => DropdownItem<Map<String, dynamic>>(
                        value: element,
                        label: element['subcategory'].toString(),
                      ))
                  .toList(),
              controller: multiSelectController,
              chipDecoration: ChipDecoration(
                backgroundColor: ConstantColor.primary,
                labelStyle: TextStyle(color: ConstantColor.whiteColor),
                borderRadius: BorderRadius.circular(6),
                padding: EdgeInsets.symmetric(
                  horizontal: Get.width / 70,
                  vertical: Get.width / 150,
                ),
                deleteIcon: Icon(
                  Icons.close_rounded,
                  color: ConstantColor.whiteColor,
                  size: Get.width / 20,
                ),
                wrap: true,
                runSpacing: 6,
                spacing: 10,
              ),
              dropdownItemDecoration: DropdownItemDecoration(
                selectedIcon: Icon(Icons.check_box_rounded,
                    color: ConstantColor.whiteColor),
                selectedTextColor: ConstantColor.whiteColor,
                backgroundColor: ConstantColor.primary.withAlpha(77),
                selectedBackgroundColor: ConstantColor.primary.withAlpha(230),
              ),
              fieldDecoration: FieldDecoration(
                hintText: "Select one or more",
                hintStyle: _textFieldHintTextStyle,
                border: UnderlineInputBorder(
                  borderSide:
                      BorderSide(width: 1, color: ConstantColor.grayColor),
                ),
              ),
            ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: height * 0.03),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: "Category", style: _textFieldLabelTextStyle),
                TextSpan(
                  text: "*",
                  style: _textFieldLabelTextStyle.copyWith(color: Colors.red),
                ),
              ],
            ),
          ),
          TextFormField(
            controller: businessSignUpController.txtOtherCategory.value,
            keyboardType: TextInputType.name,
            style: _textFieldTextStyle,
            focusNode: categoryFocusNode,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
            decoration: _inputDecoration(hintText: "Enter your Category"),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your category';
              }
              return null;
            },
          ),
          SizedBox(height: height * 0.03),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: "Sub Category", style: _textFieldLabelTextStyle),
                TextSpan(
                  text: "*",
                  style: _textFieldLabelTextStyle.copyWith(color: Colors.red),
                ),
              ],
            ),
          ),
          TextFormField(
            controller: businessSignUpController.txtOtherSubCategory.value,
            keyboardType: TextInputType.name,
            focusNode: subCategoryFocusNode,
            style: _textFieldTextStyle,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
            decoration: _inputDecoration(hintText: "Enter your Sub Category"),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your sub category';
              }
              return null;
            },
          ),
        ],
      );
    }
  }

  Widget _buildWhatsappField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: height * 0.03),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                  text: "Whatsapp Number", style: _textFieldLabelTextStyle),
              TextSpan(
                text: "*",
                style: _textFieldLabelTextStyle.copyWith(color: Colors.red),
              ),
            ],
          ),
        ),
        TextFormField(
          controller: businessSignUpController.txtWhatsappNo.value,
          keyboardType: TextInputType.phone,
          focusNode: whatsappNumberFocusNode,
          style: _textFieldTextStyle,
          maxLength: 10,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textInputAction: TextInputAction.next,
          decoration: _inputDecoration(
            hintText: "Enter your Whatsapp number",
            prefixIcon: Padding(
              padding: const EdgeInsets.only(top: 5, bottom: 5, right: 20),
              child: Text(
                "+91",
                style: TextStyle(
                  fontSize: 22,
                  color: ConstantColor.blackColor,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your whatsapp number';
            } else if (value.trim().length != 10) {
              return 'Please enter a valid 10-digit whatsapp number';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildWebsiteField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: height * 0.03),
        Text("Website", style: _textFieldLabelTextStyle),
        TextFormField(
          controller: businessSignUpController.txtWebsite.value,
          keyboardType: TextInputType.url,
          textCapitalization: TextCapitalization.none,
          style: _textFieldTextStyle,
          textInputAction: TextInputAction.next,
          decoration:
              _inputDecoration(hintText: "Enter your Website (optional)"),
        ),
      ],
    );
  }

  Widget _buildAboutField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: height * 0.03),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: "About", style: _textFieldLabelTextStyle),
              TextSpan(
                text: "*",
                style: _textFieldLabelTextStyle.copyWith(color: Colors.red),
              ),
            ],
          ),
        ),
        TextFormField(
          controller: businessSignUpController.txtAbout.value,
          keyboardType: TextInputType.multiline,
          focusNode: aboutFocusNode,
          maxLines: 3,
          style: _textFieldTextStyle,
          textInputAction: TextInputAction.next,
          decoration: _inputDecoration(hintText: "Tell us about your business"),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter about your business';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildAreaField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: height * 0.03),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: "Area", style: _textFieldLabelTextStyle),
              TextSpan(
                text: "*",
                style: _textFieldLabelTextStyle.copyWith(color: Colors.red),
              ),
            ],
          ),
        ),
        TextFormField(
          controller: businessSignUpController.txtArea.value,
          keyboardType: TextInputType.text,
          focusNode: areaFocusNode,
          textCapitalization: TextCapitalization.words,
          style: _textFieldTextStyle,
          textInputAction: TextInputAction.done,
          decoration: _inputDecoration(hintText: "Enter your service area"),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your area';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildReferredCodeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: height * 0.03),
        Text("Referred Code", style: _textFieldLabelTextStyle),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: businessSignUpController.txtReferredCode.value,
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.characters,
                style: _textFieldTextStyle,
                textInputAction: TextInputAction.next,
                onChanged: (val) {
                  if (businessSignUpController
                          .verifiedReferralCode.value.isNotEmpty &&
                      val.trim() !=
                          businessSignUpController.verifiedReferralCode.value) {
                    businessSignUpController.resetReferralStatus();
                  } else if (businessSignUpController
                          .referralMessage.value.isNotEmpty &&
                      val.trim().isEmpty) {
                    businessSignUpController.resetReferralStatus();
                  }
                },
                decoration: _inputDecoration(
                    hintText: "Enter referral code (optional)"),
              ),
            ),
            const SizedBox(width: 8),
            Obx(() {
              return businessSignUpController.isVerifyingReferral.value
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: ConstantColor.primary,
                      ),
                    )
                  : TextButton(
                      onPressed: () async {
                        FocusScope.of(context).unfocus();
                        await businessSignUpController.checkReferralApi(
                          businessSignUpController.txtReferredCode.value.text,
                        );
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: ConstantColor.primary.withOpacity(0.1),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        "Verify",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: ConstantColor.primary,
                        ),
                      ),
                    );
            }),
          ],
        ),
        Obx(() {
          if (businessSignUpController.referralMessage.value.isEmpty) {
            return const SizedBox.shrink();
          }
          final isSuccess = businessSignUpController.isReferralVerified.value;
          return Padding(
            padding: const EdgeInsets.only(top: 6, left: 2),
            child: Row(
              children: [
                Icon(
                  isSuccess ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: isSuccess ? Colors.green : Colors.red,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    businessSignUpController.referralMessage.value,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isSuccess ? Colors.green : Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPhotoUploadField() {
    return Column(
      children: [
        SizedBox(height: height * 0.02),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Upload your Photo",
              style: TextStyle(
                fontSize: 18,
                color: ConstantColor.blackColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: GestureDetector(
                onTap: () async {
                  final ImagePicker picker = ImagePicker();
                  final XFile? image =
                      await picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    await businessSignUpController.cropImage(image);
                  }
                },
                child: Container(
                  height: 160,
                  width: 160,
                  decoration: BoxDecoration(
                    color: const Color(0xffFFF0E9),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child:
                      businessSignUpController.croppedProfileFile.value?.path !=
                                  null &&
                              businessSignUpController
                                  .croppedProfileFile.value!.path.isNotEmpty
                          ? Image.file(
                              File(businessSignUpController
                                  .croppedProfileFile.value!.path),
                              height: 160,
                              width: 160,
                              fit: BoxFit.cover,
                            )
                          : const Center(
                              child: Icon(Icons.camera_alt,
                                  size: 30, color: Colors.grey),
                            ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProfilePhoto() {
    return SizedBox(
      height: Get.width / 2.5,
      width: Get.width / 2.5,
      child: Stack(
        children: [
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: Container(
                height: Get.width / 3,
                width: Get.width / 3,
                decoration: BoxDecoration(
                  color: const Color(0xffFFF0E9),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: businessSignUpController.filePath.value.isNotEmpty
                    ? (businessSignUpController.filePath.value.contains("cache")
                        ? Image.file(
                            File(businessSignUpController.filePath.value),
                            height: Get.width / 3,
                            width: Get.width / 3,
                            fit: BoxFit.cover,
                          )
                        : Image.network(
                            "${ConstantString.userImgUrlPath}${businessSignUpController.filePath.value}",
                            height: Get.width / 3,
                            width: Get.width / 3,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Center(
                              child: Icon(Icons.person,
                                  size: 50, color: Colors.grey),
                            ),
                          ))
                    : const Center(
                        child: Icon(Icons.person, size: 50, color: Colors.grey),
                      ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: GestureDetector(
              onTap: () async {
                final ImagePicker picker = ImagePicker();
                final XFile? image =
                    await picker.pickImage(source: ImageSource.gallery);
                if (image != null) {
                  businessSignUpController.filePath.value = image.path;
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
                  Icons.camera_alt,
                  color: ConstantColor.whiteColor,
                  size: Get.width / 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfo() {
    final userData = homeController.userData;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow("Full Name", userData['name']),
        SizedBox(height: height * 0.01),
        _buildInfoRow("Mobile", userData['mobile']),
        SizedBox(height: height * 0.01),
        _buildInfoRow("Email", userData['email']),
        SizedBox(height: height * 0.01),
        _buildInfoRow("Area", userData['area']),
        SizedBox(height: height * 0.01),
        _buildInfoRow("Referred Code", userData['referred_by_code']),
      ],
    );
  }

  Widget _buildInfoRow(String label, dynamic value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _userConstHeadingTextStyle),
        Text(
          value == null || value.toString().trim().isEmpty
              ? ConstantString.naLabel
              : value.toString(),
          style: _userConstValueTextStyle,
        ),
      ],
    );
  }

  Widget _buildTermsAndConditions() {
    return Center(
      child: Obx(
        () => Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Checkbox(
              value: checkTermsCondition.value,
              onChanged: (value) => checkTermsCondition.value = value ?? false,
              activeColor: ConstantColor.primary,
            ),
            GestureDetector(
              onTap: () {
                final controller = _getWebViewController();
                controller
                    .loadRequest(Uri.parse(ConstantString.businessTermsUrl));

                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      titlePadding: EdgeInsets.zero,
                      contentPadding: EdgeInsets.zero,
                      content: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.9,
                        height: MediaQuery.of(context).size.height * 0.7,
                        child: Column(
                          children: [
                            Align(
                              alignment: Alignment.topRight,
                              child: IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                            Expanded(
                              child: WebViewWidget(controller: controller),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'I read & agree to ',
                      style: TextStyle(
                        color: ConstantColor.blackColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    TextSpan(
                      text: 'Terms & Conditions',
                      style: TextStyle(
                        color: ConstantColor.primary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Center(
      child: AppButton(
        onTap: _handleSubmit,
        title: widget.newAccount == true ? "Create Account" : "Update Profile",
        isLoading: businessSignUpController.isButtonLoading.value,
        myWidth: Get.width / 2,
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    if (!checkTermsCondition.value) {
      ShowToast.showToast("Please accept our terms & conditions",
          showSuccess: false);
      return;
    }

    if (businessSignUpController.selectedProfileType.value.isEmpty) {
      ShowToast.showToast("Please select profile type", showSuccess: false);
      return;
    }

    if (businessSignUpController.categoryDataList.isEmpty &&
        businessSignUpController.txtOtherCategory.value.text.trim().isEmpty) {
      ShowToast.showToast("Please enter category", showSuccess: false);
      return;
    }

    if (businessSignUpController.categoryDataList.isNotEmpty &&
        businessSignUpController.selectedCategory.isEmpty) {
      ShowToast.showToast("Please select category", showSuccess: false);
      return;
    }

    if (businessSignUpController.subCategoryDataList.isEmpty &&
        businessSignUpController.txtOtherSubCategory.value.text
            .trim()
            .isEmpty &&
        businessSignUpController.selectedCategory.isNotEmpty) {
      ShowToast.showToast("Please enter sub category", showSuccess: false);
      return;
    }

    if (businessSignUpController.subCategoryDataList.isNotEmpty &&
        multiSelectController.selectedItems.isEmpty) {
      ShowToast.showToast("Please select sub category", showSuccess: false);
      return;
    }

    if (businessSignUpController.txtWhatsappNo.value.text.trim().isEmpty ||
        businessSignUpController.txtWhatsappNo.value.text.trim().length != 10) {
      ShowToast.showToast("Please enter valid whatsapp number",
          showSuccess: false);
      return;
    }

    if (businessSignUpController.txtAbout.value.text.trim().isEmpty) {
      ShowToast.showToast("Please enter about your business",
          showSuccess: false);
      return;
    }

    if (businessSignUpController.txtArea.value.text.trim().isEmpty) {
      ShowToast.showToast("Please enter your area", showSuccess: false);
      return;
    }

    FocusScope.of(context).unfocus();

    // For existing users converting to business: block if already submitted
    if (widget.newAccount != true) {
      EasyLoading.show(status: ConstantString.pleaseWaitLabel);
      final checkResult =
          await businessSignUpController.checkProfileBusinessProfileApi();
      EasyLoading.dismiss();
      if (checkResult['status'] == true) {
        if (mounted) {
          _showAlreadySubmittedDialog(context);
        }
        return;
      }
    }

    try {
      final bool isUpdateProfile = widget.newAccount != true;

      String referralCodeToSend = "";
      if (isUpdateProfile) {
        referralCodeToSend =
            homeController.userData['referred_by_code']?.toString() ?? '';
      } else {
        String enteredCode =
            businessSignUpController.txtReferredCode.value.text.trim();
        if (enteredCode.isNotEmpty) {
          if (businessSignUpController.isReferralVerified.value &&
              enteredCode ==
                  businessSignUpController.verifiedReferralCode.value) {
            referralCodeToSend = enteredCode;
          } else {
            bool isValid =
                await businessSignUpController.checkReferralApi(enteredCode);
            if (isValid) {
              referralCodeToSend = enteredCode;
            } else {
              // Invalid code: DO NOT send code to backend
              referralCodeToSend = "";
            }
          }
        }
      }

      final Map<String, String> bodyParams = {
        'user_type': '2',
        'name': isUpdateProfile
            ? (homeController.userData['name']?.toString() ?? '')
            : businessSignUpController.txtFullName.value.text.trim(),
        'company_name':
            businessSignUpController.txtCompanyName.value.text.trim(),
        'mobile': isUpdateProfile
            ? (homeController.userData['mobile']?.toString() ?? '')
            : businessSignUpController.txtMobileNo.value.text.trim(),
        'email': isUpdateProfile
            ? (homeController.userData['email']?.toString() ?? '')
            : businessSignUpController.txtEmailId.value.text.trim(),
        'profile_type': _getProfileTypeValueForApi(
            businessSignUpController.selectedProfileType.value),
        'category': businessSignUpController.categoryDataList.isEmpty
            ? ''
            : (businessSignUpController.selectedCategory['id']?.toString() ??
                ''),
        'other_category': businessSignUpController.categoryDataList.isNotEmpty
            ? ''
            : businessSignUpController.txtOtherCategory.value.text.trim(),
        'sub_category': businessSignUpController.categoryDataList.isEmpty ||
                businessSignUpController.subCategoryDataList.isEmpty
            ? ''
            : multiSelectController.selectedItems
                .map((e) => e.value['id']?.toString() ?? '0')
                .join(','),
        'other_sub_category': businessSignUpController
                    .categoryDataList.isNotEmpty &&
                businessSignUpController.subCategoryDataList.isNotEmpty
            ? ''
            : businessSignUpController.txtOtherSubCategory.value.text.trim(),
        'whatsapp': businessSignUpController.txtWhatsappNo.value.text.trim(),
        'website': businessSignUpController.txtWebsite.value.text.trim(),
        'about_us': businessSignUpController.txtAbout.value.text.trim(),
        'area': isUpdateProfile
            ? (homeController.userData['area']?.toString() ?? '')
            : businessSignUpController.txtArea.value.text.trim(),
        'referred_by_code': referralCodeToSend,
      };

      debugPrint('Request Body: $bodyParams');

      String photoPath = "";
      if (isUpdateProfile) {
        photoPath = businessSignUpController.filePath.value;
      } else {
        photoPath =
            businessSignUpController.croppedProfileFile.value?.path ?? "";
      }

      EasyLoading.show(status: ConstantString.pleaseWaitLabel);

      if (isUpdateProfile) {
        final response = await businessSignUpController.postUpdateProfileApi(
            bodyParams, photoPath);
        await EasyLoading.dismiss();

        if (response['code'] == 200) {
          // ✅ Mark locally so user cannot re-submit
          await BusinessSignUpController.markBusinessRequestSubmitted();
          await homeController.postFetchProfileApi(forceRefresh: true);
          ShowToast.showToast(
              response['msg'] ??
                  "Request submitted successfully! Please wait for admin approval.",
              showSuccess: true);

          if (mounted) {
            Get.offAll(() => const HomeTabBarScreen());
          }
        } else {
          ShowToast.showToast(
              response['msg'] ?? ConstantString.somethingWantWrongMsg,
              showSuccess: false);
        }
      } else {
        final response = await businessSignUpController.postBusinessSignUpApi(
            bodyParams, photoPath);
        await EasyLoading.dismiss();

        // Account created successfully
        if (response['code'] == 200 &&
            businessSignUpController.isAccountCreated.value) {
          // ✅ Mark locally so user cannot re-submit
          await BusinessSignUpController.markBusinessRequestSubmitted();
          ShowToast.showToast(
              response['msg'] ?? "Account created successfully! Please login.",
              showSuccess: true);

          // Get mobile number
          String mobileNumber = bodyParams['mobile'] ?? '';

          // Navigate to Mobile Number Screen
          if (mounted) {
            Get.offAll(() => const MobileNumberScreen());

            // After navigation, pre-fill the mobile number
            Future.delayed(const Duration(milliseconds: 500), () {
              if (Get.isRegistered<MobileNumberController>()) {
                final mobileNumberController =
                    Get.find<MobileNumberController>();
                mobileNumberController.mobileNumberController.value.text =
                    mobileNumber;
              }
            });
          }
        } else {
          ShowToast.showToast(
              response['msg'] ?? ConstantString.somethingWantWrongMsg,
              showSuccess: false);
        }
      }
    } catch (error) {
      await EasyLoading.dismiss();
      debugPrint('Submit Error: $error');

      String errorMsg = error.toString();
      if (errorMsg.startsWith("Exception: ")) {
        errorMsg = errorMsg.replaceFirst("Exception: ", "");
      }
      ShowToast.showToast(errorMsg, showSuccess: false);
    }
  }

  String _getProfileTypeValueForApi(String profileType) {
    switch (profileType.toLowerCase()) {
      case 'business':
        return '0';
      case 'service':
        return '1';
      case 'business/service':
        return '0,1';
      default:
        return '';
    }
  }

  final TextStyle _textFieldLabelTextStyle = TextStyle(
    fontSize: 20,
    color: ConstantColor.blackColor,
    fontWeight: FontWeight.w500,
  );

  final TextStyle _textFieldHintTextStyle = const TextStyle(fontSize: 14);

  final TextStyle _textFieldTextStyle = TextStyle(
    fontSize: 21,
    color: ConstantColor.blackColor,
  );

  final TextStyle _userConstHeadingTextStyle = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: ConstantColor.grayColor,
  );

  final TextStyle _userConstValueTextStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: ConstantColor.blackColor,
  );

  // ── Already-Submitted protection dialog ─────────────────────────
  ProfileController get _profileController =>
      Get.isRegistered<ProfileController>()
          ? Get.find<ProfileController>()
          : Get.put(ProfileController());

  void _showAlreadySubmittedDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                  style:
                      TextStyle(fontSize: 14, color: Colors.grey, height: 1.4),
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
                        child: Text("Close",
                            style: TextStyle(color: Colors.grey[700])),
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
                                await _profileController.postDeveloperApi();
                            EasyLoading.dismiss();
                            if (value['code'] == 200) {
                              final phone =
                                  value['data']['company_mobile'] ?? '';
                              final url = Uri.parse('tel:+$phone');
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url);
                              } else {
                                ShowToast.showToast("Could not launch dialer",
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

  InputDecoration _inputDecoration({
    required String hintText,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      border: const UnderlineInputBorder(
        borderSide: BorderSide(width: 1),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(width: 1),
      ),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 5),
      hintText: hintText,
      hintStyle: _textFieldHintTextStyle,
      counterText: '',
      prefixIcon: prefixIcon,
    );
  }
}
