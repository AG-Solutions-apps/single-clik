import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:single_clik/constants/constant_color.dart';
import 'package:single_clik/controller/home_controller/services_controller.dart';
import 'package:single_clik/screens/home_screens/home_screens/user_list_screen.dart';

class ServicesScreen extends StatefulWidget {
  final String categoryId;
  final String title;

  const ServicesScreen({
    super.key,
    required this.categoryId,
    required this.title,
  });

  @override
  State<ServicesScreen> createState() => ServicesScreenState();
}

class ServicesScreenState extends State<ServicesScreen> {
  ServicesController servicesController = Get.put(ServicesController());

  @override
  void initState() {
    // TODO: implement initState
    servicesController.postSubCategoriesApi(widget.categoryId);
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
          child: const Icon(
            Icons.arrow_back_outlined,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        title: Text(
          widget.title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: Obx(
        () => servicesController.isLoading.value
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : Padding(
                padding: const EdgeInsets.only(top: 10),
                child: ListView.builder(
                  itemCount: servicesController.servicesList.length,
                  shrinkWrap: true,
                  itemBuilder: (context, index) => GestureDetector(
                    onTap: () {
                      Get.to(() => UserListScreen(
                            categoryId: (servicesController.servicesList[index]
                                        ['category'] ??
                                    "")
                                .toString(),
                            categoryName: (servicesController
                                        .servicesList[index]['category'] ??
                                    "")
                                .toString(),
                          ));
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: ConstantColor.whiteColor,
                        boxShadow: [
                          BoxShadow(
                            color: ConstantColor.blackColor.withAlpha(26),
                            offset: Offset(0, 5),
                            spreadRadius: 0,
                            blurRadius: 10,
                          ),
                        ],
                        borderRadius: BorderRadius.circular(15),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      margin: const EdgeInsets.symmetric(
                          vertical: 5, horizontal: 15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            servicesController.servicesList[index]
                                    ['subcategory'] ??
                                "",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: ConstantColor.primary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
