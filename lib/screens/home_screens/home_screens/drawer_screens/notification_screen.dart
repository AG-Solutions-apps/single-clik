import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:single_clik/constants/constant_color.dart';
import 'package:single_clik/controller/home_controller/notification_screen.dart';

import '../../../../constants/constant_string.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  NotificationController notificationController =
      Get.put(NotificationController());

  @override
  void initState() {
    // TODO: implement initState
    notificationController.getAllNotifications();
    super.initState();
  }

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
          "Notification",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: ConstantColor.whiteColor,
          ),
        ),
      ),
      body: Obx(
        () => notificationController.isLoading.value
            ? Center(
                child: CircularProgressIndicator(color: ConstantColor.primary),
              )
            : notificationController.notificationDataList.isEmpty
                ? RefreshIndicator(
                    onRefresh: () async {
                      await notificationController.getAllNotifications();
                    },
                    color: ConstantColor.primary,
                    backgroundColor: ConstantColor.whiteColor,
                    child: ListView(
                      children: [
                        SizedBox(
                          height: Get.height / 2.5,
                        ),
                        Center(
                          child: Text(
                            ConstantString.dataNotFoundLabel,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: ConstantColor.blackColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      await notificationController.getAllNotifications();
                    },
                    color: ConstantColor.primary,
                    backgroundColor: ConstantColor.whiteColor,
                    child: ListView.builder(
                      itemCount:
                          notificationController.notificationDataList.length,
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      itemBuilder: (context, index) {
                        String heading = notificationController
                                            .notificationDataList[index]
                                        ['notification_heading'] ==
                                    null ||
                                notificationController
                                    .notificationDataList[index]
                                        ['notification_heading']
                                    .toString()
                                    .trim()
                                    .isEmpty
                            ? 'Heading ${ConstantString.naLabel}'
                            : notificationController.notificationDataList[index]
                                    ['notification_heading']
                                .toString()
                                .trim();
                        String description = notificationController
                                            .notificationDataList[index]
                                        ['notification_des'] ==
                                    null ||
                                notificationController
                                    .notificationDataList[index]
                                        ['notification_des']
                                    .toString()
                                    .trim()
                                    .isEmpty
                            ? 'Description ${ConstantString.naLabel}'
                            : notificationController.notificationDataList[index]
                                    ['notification_des']
                                .toString()
                                .trim();
                        DateTime notificationDate = DateTime(0);
                        if (notificationController.notificationDataList[index]
                                    ['notification_date'] !=
                                null &&
                            notificationController.notificationDataList[index]
                                    ['notification_date']
                                .toString()
                                .trim()
                                .isNotEmpty) {
                          try {
                            notificationDate = DateTime.parse(
                                notificationController
                                    .notificationDataList[index]
                                        ['notification_date']
                                    .toString());
                          } catch (error) {
                            notificationDate = DateTime(0);
                          }
                        }
                        return Container(
                          padding: EdgeInsets.all(Get.width / 30),
                          margin: EdgeInsets.only(
                            top: Get.width / 30,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xffE2E2E2),
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                heading,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: ConstantColor.blackColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: height * 0.01),
                              Padding(
                                padding: const EdgeInsets.only(right: 50),
                                child: Text(
                                  description,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: ConstantColor.grayColor,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                              notificationDate.year <= 0
                                  ? const SizedBox()
                                  : Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        DateFormat('dd-MM-yyyy')
                                            .format(notificationDate),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: ConstantColor.blackColor,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}
