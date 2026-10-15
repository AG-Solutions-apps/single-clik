import 'package:flutter/material.dart';
import 'package:single_clik/constants/constant_color.dart';
import 'package:webview_flutter/webview_flutter.dart';

class TermsAndConditionPage extends StatefulWidget {
  final String url;

  const TermsAndConditionPage({
    super.key,
    required this.url,
  });

  @override
  State<TermsAndConditionPage> createState() => TermsAndConditionPageState();
}

class TermsAndConditionPageState extends State<TermsAndConditionPage> {
  final controller = WebViewController();

  @override
  void initState() {
    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.url));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: ConstantColor.primaryGradient,
          ),
        ),
      ),
      backgroundColor: ConstantColor.whiteColor,
      body: WebViewWidget(controller: controller),
    ));
  }
}
