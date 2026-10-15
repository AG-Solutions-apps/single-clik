import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:single_clik/constants/constant_color.dart';
import 'package:single_clik/constants/firebase_services.dart' as services;
import 'package:single_clik/controller/app_update_controller.dart';
import 'package:single_clik/screens/auth_screens/mobile_number_screen.dart';
import 'package:single_clik/screens/get_started_screen/get_started_page.dart';
import 'package:single_clik/screens/home_tab_bar_screen.dart';
import 'package:single_clik/splash_screen.dart';

double latitude = 0.0;
double longitude = 0.0;
String address = "";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Get.put(AppUpdateController(), permanent: true);

  try {
    await Firebase.initializeApp();

    debugPrint("✅ Firebase initialized successfully");

    await services.FirebaseService().initNotification();
  } catch (e) {
    debugPrint("❌ Firebase Initialization Failed: $e");
  }

  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint("Flutter Error: ${details.exception}");
  };

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runZonedGuarded(
    () {
      runApp(const MyApp());
    },
    (error, stackTrace) {
      debugPrint("Caught error: $error");
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'SINGLE CLICK',
      debugShowCheckedModeBanner: false,
      builder: EasyLoading.init(),
      theme: ThemeData(
        useMaterial3: false,
        hoverColor: Colors.white,
        scaffoldBackgroundColor: Colors.white,
        primaryColor: ConstantColor.primary,
        fontFamily: 'Nunito-SemiBold',
        colorScheme: ColorScheme.fromSwatch(
          accentColor: ConstantColor.primary,
        ),
      ),
      initialRoute: 'splash',
      routes: {
        "splash": (context) => const SplashScreen(),
        "getStarted": (context) => const GetStartedPage(),
        "login": (context) => const MobileNumberScreen(),
        "home": (context) => HomeTabBarScreen(),
      },
      home: const SplashScreen(),
    );
  }
}
