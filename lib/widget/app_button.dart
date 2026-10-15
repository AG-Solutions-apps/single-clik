import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:single_clik/constants/constant_color.dart';

class AppButton extends StatelessWidget {
  final void Function()? onTap;
  final String? title;
  final Widget? child;
  final Color? buttonColor;
  final double? fontSize;
  final Color? buttonTextColor;
  final List<BoxShadow>? boxShadow;
  final bool isLoading;
  final bool arrowShow;
  final double? myWidth;
  final double? height;
  final BorderRadius? borderRadius;

  const AppButton({
    super.key,
    this.onTap,
    this.title = "",
    this.child,
    this.boxShadow,
    this.buttonColor,
    this.fontSize,
    this.buttonTextColor,
    this.isLoading = false,
    this.borderRadius,
    this.myWidth,
    this.height,
    this.arrowShow = true,
  });

  @override
  Widget build(BuildContext context) {
    double width = myWidth ?? MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: width,
        height: height ?? Get.height * 0.06,
        decoration: BoxDecoration(
          color: buttonColor != null ? buttonColor : null,
          gradient: buttonColor == null ? ConstantColor.primaryGradient : null,
          borderRadius: borderRadius ?? BorderRadius.circular(100),
          boxShadow: boxShadow ??
              [
                BoxShadow(
                  color: Colors.black.withAlpha(66), // ≈ 26% opacity
                  offset: const Offset(0, 2),
                  blurRadius: 2,
                  spreadRadius: 0,
                ),
              ],
        ),
        child: Center(
          child: isLoading
              ? LoadingAnimationWidget.staggeredDotsWave(
                  color: Colors.white,
                  size: 26,
                )
              : child ??
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Expanded(
                          child: Text(
                            title!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: fontSize ?? 18,
                              color: buttonTextColor ?? Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (arrowShow)
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Image.asset(
                              "assets/icons/icon_left.png",
                              height: 24,
                            ),
                          ),
                      ],
                    ),
                  ),
        ),
      ),
    );
  }
}
