import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:single_clik/constants/constant_string.dart';
import 'package:single_clik/constants/show_toast.dart';
import 'package:single_clik/utils/shar_preferences.dart';

import '../../services/api.dart';
import 'package:http/http.dart' as http;

class FeedBackController extends GetxController {
  final isLoading = false.obs;
  final isButtonLoading = false.obs;
  final subjectController = TextEditingController().obs;
  final descriptionController = TextEditingController().obs;

  Future postFeedBackApi() async {
    isButtonLoading.value = true;
    var bodyParams = {
      'feedback_subject': subjectController.value.text,
      'feedback_description': descriptionController.value.text
    };
    try {
      final token = await SharPreferences.getString(SharPreferences.token);
      if (token == null || token.trim().isEmpty) {
        isButtonLoading.value = false;
        ShowToast.showToast("Authentication error. Please login again.",
            showSuccess: false);
        return;
      }
      final request =
          http.MultipartRequest('POST', Uri.parse(API.createFeedback));
      request.headers.addAll({
        'Authorization': 'Bearer ${token.trim()}',
        'Accept': 'application/json',
      });
      request.fields.addAll(bodyParams);
      var res = await request.send();
      var responseDone = await http.Response.fromStream(res);

      if (res.statusCode == 200) {
        final responseData = json.decode(responseDone.body);
        debugPrint(responseData.toString());
        if (responseData['code'] == 200) {
          subjectController.value.clear();
          descriptionController.value.clear();
          ShowToast.showToast(
            responseData['msg'] ?? ConstantString.dataSubmittedSuccessfullyMsg,
            showSuccess: true,
          );

          isButtonLoading.value = false;
        } else {
          isButtonLoading.value = false;
          ShowToast.showToast(
            responseData['msg'] ?? ConstantString.somethingWantWrongMsg,
            showSuccess: false,
          );
        }
      } else {
        isButtonLoading.value = false;
        ShowToast.showToast(
          ConstantString.somethingWantWrongMsg,
          showSuccess: false,
        );
      }
    } on TimeoutException catch (e) {
      isButtonLoading.value = false;
      ShowToast.showToast(
        e.message.toString(),
        showSuccess: false,
      );
    } on SocketException catch (e) {
      isButtonLoading.value = false;
      ShowToast.showToast(
        e.message.toString(),
        showSuccess: false,
      );
    } on Error catch (e) {
      isButtonLoading.value = false;
      ShowToast.showToast(
        ConstantString.somethingWantWrongMsg,
        showSuccess: false,
      );
      debugPrint(e.toString());
    }
  }
}
