import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:single_clik/services/api.dart';
import 'package:single_clik/utils/shar_preferences.dart';

class UserListController extends GetxController {
  final isLoading = false.obs;

  RxList userList = [].obs;

  Future postUserListApi(String? profileType) async {
    try {
      isLoading.value = true;
      final token = await SharPreferences.getString(SharPreferences.token);
      if (token == null || token.trim().isEmpty) {
        debugPrint('UserList: No auth token');
        isLoading.value = false;
        return;
      }
      final request = http.MultipartRequest(
          'POST', Uri.parse(API.dashboardProfileCategoryWise));
      request.headers.addAll({
        'Authorization': 'Bearer ${token.trim()}',
        'Accept': 'application/json',
      });
      request.fields.addAll({'categories': profileType!});

      var res = await request.send();
      var responseDone = await http.Response.fromStream(res);
      if (res.statusCode == 200) {
        var responseData = json.decode(responseDone.body);
        debugPrint("ResponseDone : ${responseDone.body}");
        userList.value = responseData['data'] ?? [];
        isLoading.value = false;
      } else {
        isLoading.value = false;
        // ShowToast.showToast(responseData['msg'] ?? 'Something went wrong.',showSuccess: false,);
      }
    }
    // on TimeoutException catch (e) {
    //   isLoading.value = false;
    //   ShowToast.showToast(e.message.toString(),showSuccess: false,);
    // } on SocketException catch (e) {
    //   isLoading.value = false;
    //   ShowToast.showToast(e.message.toString(),showSuccess: false,);
    // }
    catch (e) {
      isLoading.value = false;
      // ShowToast.showToast('Something went wrong.',showSuccess: false,);
      debugPrint(e.toString());
    }
  }
}
