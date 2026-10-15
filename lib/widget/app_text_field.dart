import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:single_clik/constants/constant_color.dart';

Widget appTextFormField(
    {Key? key,
    TextEditingController? controller,
    InputDecoration? decoration = const InputDecoration(),
    String? hintText,
    List<TextInputFormatter>? inputFormatters,
    String? label,
    TextInputType? keyboardType,
    TextStyle? style,
    String? Function(String?)? validator,
    Widget? suffixIcon,
    Widget? prefixIcon,
    Color? fillColor,
    TextStyle? hintStyle,
    TextInputAction? textInputAction,
    bool? obscureText = false,
    BorderSide? borderSide,
    InputBorder? border,
    Padding? padding,
    String obscuringCharacter = '•',
    Function(String)? onChanged,
    Function()? onTap,
    BorderRadius? borderRadius,
    Iterable<String>? autofillHints,
    EdgeInsetsGeometry? contentPadding,
    int? maxLines,
    bool? readOnly,
    bool? enable,
    FocusNode? focusNode,
    String? counterText,
    TextAlign textAlign = TextAlign.start,
    int? maxLength}) {
  return TextFormField(
    key: key,
    onTap: onTap,
    controller: controller,
    focusNode: focusNode,
    validator: validator,
    obscureText: obscureText ?? true,
    onChanged: onChanged,
    inputFormatters: inputFormatters,
    textInputAction: textInputAction,
    maxLength: maxLength,
    style: style ??
        TextStyle(
          fontSize: 20,
          color: ConstantColor.blackColor,
          fontWeight: FontWeight.w500,
        ),
    obscuringCharacter: obscuringCharacter,
    autofillHints: autofillHints,
    keyboardType: keyboardType,
    textAlign: textAlign,
    maxLines: maxLines ?? 1,
    cursorColor: ConstantColor.blackColor,
    readOnly: readOnly ?? false,
    decoration: InputDecoration(
      fillColor: Colors.transparent,
      counterText: counterText,
      contentPadding: contentPadding,
      hintText: hintText!,
      hintStyle: hintStyle ??
          TextStyle(
              fontSize: 18,
              color: ConstantColor.grayColor,
              fontWeight: FontWeight.w400),
      labelText: label,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      enabled: enable ?? true,
      border: UnderlineInputBorder(
        borderSide: BorderSide(
          width: 1,
          color: ConstantColor.grayColor,
        ),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(
          width: 1,
          color: ConstantColor.grayColor,
        ),
      ),
      disabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(
          width: 1,
          color: ConstantColor.grayColor,
        ),
      ),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(
          width: 1,
          color: ConstantColor.grayColor,
        ),
      ),
    ),
  );
}
