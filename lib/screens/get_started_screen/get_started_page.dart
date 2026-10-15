import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../constants/constant_color.dart';
import '../../constants/constant_string.dart';
import '../../controller/home_controller/home_controller.dart';

class GetStartedPage extends StatefulWidget {
  const GetStartedPage({super.key});

  @override
  State<GetStartedPage> createState() => _GetStartedPageState();
}

class _GetStartedPageState extends State<GetStartedPage> {
  HomeController homeController = Get.put(HomeController());
  bool isTrue = false;
  @override
  void initState() {
    // TODO: implement initState
    Timer(const Duration(seconds: 10), () {
      Get.offNamed('login');
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: Get.width / 30,
          ),
          child: SingleChildScrollView(
              child: Obx(
            () => Column(
              children: [
                SizedBox(
                  height: Get.width,
                  child: Stack(
                    children: [
                      Center(
                        child: Column(
                          children: [
                            SizedBox(height: Get.width / 6.5),
                            // DottedBorder(
                            //   color: ConstantColor.orangeColor,
                            //   borderType: BorderType.Circle,
                            //   strokeWidth: 2,
                            //   dashPattern: [6, 3],
                            //   child: Container(
                            //     height: Get.width / 1.5,
                            //     width: Get.width / 1.5,
                            //     alignment: Alignment.center,
                            //     padding: EdgeInsets.all(Get.width / 9),
                            //     child: DottedBorder(
                            //       color: ConstantColor.cementColor,
                            //       borderType: BorderType.Circle,
                            //       strokeWidth: 1.5,
                            //       dashPattern: [4, 2],
                            //       child: Container(
                            //         height: Get.width / 2,
                            //         width: Get.width / 2,
                            //         alignment: Alignment.center,
                            //         padding: EdgeInsets.all(Get.height * 0.06),
                            //         decoration: const BoxDecoration(
                            //           shape: BoxShape.circle,
                            //         ),
                            //         child: buildImageCircle(
                            //           ConstantString.categoriesImgUrlPath +
                            //               (homeController.onBoardList.value.categories?.categoryImage ?? ""),
                            //           Get.width / 2,
                            //         ),
                            //       ),
                            //     ),
                            //   ),
                            // ),
                          ],
                        ),
                      ),
                      Center(
                        child: CircularAnimation(
                          radius: 70,
                          images: [
                            buildCircularAnimation(
                              homeController.onBoardList.value.data?[1].photo ??
                                  "",
                            ),
                            Container(
                              height: Get.width / 22,
                              width: Get.width / 22,
                              decoration: BoxDecoration(
                                color: ConstantColor.blackColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            buildCircularAnimation(
                              homeController.onBoardList.value.data?[2].photo ??
                                  "",
                            ),
                            Container(
                              height: Get.width / 22,
                              width: Get.width / 22,
                              decoration: BoxDecoration(
                                color: ConstantColor.blackColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            buildCircularAnimation(
                              homeController.onBoardList.value.data?[3].photo ??
                                  "",
                            ),
                            Container(
                              height: Get.width / 22,
                              width: Get.width / 22,
                              decoration: BoxDecoration(
                                color: ConstantColor.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                          animationDuration: const Duration(seconds: 20),
                        ),
                      ),
                      Center(
                        child: CircularAnimation(
                          radius: 140,
                          images: [
                            Container(
                              height: Get.width / 11,
                              width: Get.width / 11,
                              decoration: BoxDecoration(
                                color: ConstantColor.blackColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            buildCircularAnimation(
                              homeController.onBoardList.value.data?[4].photo ??
                                  "",
                            ),
                            Container(
                              height: Get.width / 12,
                              width: Get.width / 12,
                              decoration: BoxDecoration(
                                color: ConstantColor.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            buildCircularAnimation(
                              homeController.onBoardList.value.data?[5].photo ??
                                  "",
                            ),
                            Container(
                              height: Get.width / 12,
                              width: Get.width / 12,
                              decoration: BoxDecoration(
                                color: ConstantColor.blackColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            buildCircularAnimation(
                              homeController.onBoardList.value.data?[6].photo ??
                                  "",
                            ),
                            Container(
                              height: Get.width / 12,
                              width: Get.width / 12,
                              decoration: BoxDecoration(
                                color: ConstantColor.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            buildCircularAnimation(
                              homeController.onBoardList.value.data?[6].photo ??
                                  "",
                            ),
                          ],
                          animationDuration: const Duration(seconds: 20),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  (homeController.onBoardList.value.categories?.category ?? "")
                      .toString()
                      .toUpperCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: ConstantColor.blackColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 23,
                  ),
                ),
                SizedBox(
                  height: Get.height * 0.07,
                ),
                Center(
                  child: Text(
                    "The best place to meet \nyour day to day needs.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: ConstantColor.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 25,
                    ),
                  ),
                ),
                SizedBox(
                  height: Get.width / 20,
                ),
                Center(
                  child: Text(
                    "Discover new opportunities with our SINGLE CLIK! Connect, network, and generate business leads within your community effortlessly. Stay ahead, grow your network, and boost your business with ease.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: ConstantColor.blackColor,
                      fontSize: 16,
                    ),
                  ),
                ),
                SizedBox(
                  height: Get.width / 20,
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: Get.width / 8,
                  ),
                  child: GestureDetector(
                    onTap: () async {
                      Get.offNamed('login');

                      /* EasyLoading.show(status:"Please wait..",);
                      await Future.delayed(Duration(milliseconds: 200,),);
                      bool login = await SharPreferences.getBoolean(SharPreferences.isLogin) ?? false;

                      Timer(const Duration(seconds: 3), () {
                        EasyLoading.dismiss();

                        if (login != null) {
                          if (login) {
                            Get.offNamed('home');
                          } else {
                            Get.offNamed('login');
                          }
                        } else {
                          Get.offNamed('login');
                        }
                      });*/
                    },
                    child: Container(
                      width: Get.width,
                      decoration: BoxDecoration(
                        color: ConstantColor.primary,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      alignment: Alignment.center,
                      padding: EdgeInsets.symmetric(
                        vertical: Get.width / 30,
                      ),
                      child: Text(
                        'Get Started',
                        style: TextStyle(
                          color: ConstantColor.whiteColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: Get.width / 20,
                ),
              ],
            ),
          )),
        ),
      ),
    );
  }
}

Widget buildImageCircle(String imageUrl, double size) {
  return ClipOval(
    child: Image.network(
      imageUrl,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder:
          (BuildContext context, Object error, StackTrace? stackTrace) {
        return Image.network(
          "https://singleclik.com/api/storage/app/public/no_image.jpg",
          width: size,
          height: size,
        );
      },
      loadingBuilder: (BuildContext context, Widget child,
          ImageChunkEvent? loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    (loadingProgress.expectedTotalBytes ?? 1)
                : null,
          ),
        );
      },
    ),
  );
}

Widget buildCircularAnimation(String imageUrls) {
  return ClipOval(
      child: Image.network(
    ConstantString.userImgUrlPath + imageUrls,
    width: Get.width / 8,
    height: Get.width / 8,
    fit: BoxFit.cover,
    errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
      return Image.network(
        "https://singleclik.com/api/storage/app/public/no_image.jpg",
        width: Get.width / 13,
        height: Get.width / 8,
      );
    },
    loadingBuilder:
        (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
      if (loadingProgress == null) {
        return child;
      }
      return Center(
        child: CircularProgressIndicator(
          value: loadingProgress.expectedTotalBytes != null
              ? loadingProgress.cumulativeBytesLoaded /
                  (loadingProgress.expectedTotalBytes ?? 1)
              : null,
        ),
      );
    },
  ));
}

class CircularAnimation extends StatefulWidget {
  final List<Widget> images;
  final Duration animationDuration;
  final double radius;

  const CircularAnimation({
    super.key,
    required this.images,
    required this.animationDuration,
    required this.radius,
  });

  @override
  CircularAnimationState createState() => CircularAnimationState();
}

class CircularAnimationState extends State<CircularAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  RxDouble animationValue = 0.0.obs;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 2 * pi).animate(_controller)
      ..addListener(() {
        // print('SS ${_animation.value}');
        animationValue.value = _animation.value;
        // setState(() {});
//         _controller.repeat();
      })
      ..addStatusListener((status) {
        _controller.repeat();
      });
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Stack(
        children: [
          for (int i = 0; i < widget.images.length; i++)
            OrbitingImage(
              radius: widget.radius, // adjust the radius as needed
              angle: animationValue.value + (i * 2 * pi / widget.images.length),
              child: widget.images[i],
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class OrbitingImage extends StatelessWidget {
  final double radius;
  final double angle;
  final Widget child;

  const OrbitingImage({
    required this.radius,
    required this.angle,
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(radius * cos(angle), radius * sin(angle)),
      child: child,
    );
  }
}
