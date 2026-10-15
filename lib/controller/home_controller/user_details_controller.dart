import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:single_clik/services/api.dart';
import 'package:single_clik/utils/shar_preferences.dart';

class UserDetailsController extends GetxController
    with GetSingleTickerProviderStateMixin {
  final isLoading = false.obs;

  late TabController tabController;

  Map userDetails = {}.obs;
  Map userDetailsProduct = {}.obs;
  @override
  void onInit() {
    tabController = TabController(length: 3, vsync: this, initialIndex: 0);
    super.onInit();
  }

  Future postUserByIdApi(String? userId) async {
    try {
      isLoading.value = true;
      final token = await SharPreferences.getString(SharPreferences.token);
      if (token == null || token.trim().isEmpty) {
        debugPrint('UserById: No auth token');
        isLoading.value = false;
        return;
      }
      final request = http.MultipartRequest('POST', Uri.parse(API.userById));
      request.headers.addAll({
        'Authorization': 'Bearer ${token.trim()}',
        'Accept': 'application/json',
      });
      request.fields.addAll({'user_id': userId!});

      debugPrint(API.userById);
      debugPrint(await SharPreferences.getString(SharPreferences.token));
      debugPrint(request.fields.toString());

      var res = await request.send();
      var responseDone = await http.Response.fromStream(res);
      if (res.statusCode == 200) {
        final responseData = json.decode(responseDone.body);
        log(">>>>sub>>>>>>> ${responseDone.body}");

        dynamic dataField = responseData['data'];
        Map<String, dynamic> parsedProfile = {};
        List<dynamic> parsedProducts = [];

        if (dataField is List) {
          if (dataField.isNotEmpty) {
            var firstItem = dataField[0];
            if (firstItem is Map) {
              if (firstItem.containsKey('product_name') ||
                  firstItem.containsKey('product_status')) {
                parsedProducts = dataField;
              } else {
                parsedProfile = Map<String, dynamic>.from(firstItem);
                if (firstItem.containsKey('products')) {
                  parsedProducts = List.from(firstItem['products'] ?? []);
                } else if (firstItem.containsKey('product_services')) {
                  parsedProducts =
                      List.from(firstItem['product_services'] ?? []);
                }
              }
            }
          }
        } else if (dataField is Map) {
          parsedProfile = Map<String, dynamic>.from(dataField);
          if (dataField.containsKey('products')) {
            parsedProducts = List.from(dataField['products'] ?? []);
          } else if (dataField.containsKey('product_services')) {
            parsedProducts = List.from(dataField['product_services'] ?? []);
          }
        }

        if (responseData['products'] is List) {
          parsedProducts = List.from(responseData['products']);
        } else if (responseData['product_services'] is List) {
          parsedProducts = List.from(responseData['product_services']);
        }

        // Fetch products/services from the dedicated endpoint as the primary source
        final productsList = await postFetchProductServicesApi(userId: userId);
        if (productsList.isNotEmpty) {
          parsedProducts = productsList;
        }

        parsedProfile['products'] = parsedProducts;
        parsedProfile['product_services'] = parsedProducts;

        userDetails = parsedProfile;

        // Ensure products are also in the userDetailsProduct map for compatibility
        final updatedResponseData = Map<String, dynamic>.from(responseData);
        updatedResponseData['products'] = parsedProducts;
        updatedResponseData['product_services'] = parsedProducts;
        userDetailsProduct = updatedResponseData;

        isLoading.value = false;
      } else {
        isLoading.value = false;
        // ShowToast.showToast(responseData['msg'] ?? 'Something went wrong.',showSuccess: false,);
      }
    } catch (e) {
      isLoading.value = false;
      // ShowToast.showToast('Something went wrong.',showSuccess: false,);
      debugPrint(e.toString());
    }
  }

  Future<List<dynamic>> postFetchProductServicesApi({String? userId}) async {
    try {
      final token =
          await SharPreferences.getString(SharPreferences.token) ?? '';
      if (token.trim().isEmpty) {
        return [];
      }
      final request =
          http.MultipartRequest('POST', Uri.parse(API.fetchProductServices));
      request.headers.addAll({
        'Authorization': 'Bearer ${token.trim()}',
        'Accept': 'application/json',
      });
      if (userId == null || userId.isEmpty) {
        userId = await SharPreferences.getString(SharPreferences.userId) ?? '';
      }
      if (userId.isNotEmpty) {
        request.fields.addAll({'user_id': userId});
      }
      var res = await request.send();
      var responseDone = await http.Response.fromStream(res);
      debugPrint(
          'Fetch Product Services UserDetails Response Code: ${res.statusCode}');
      debugPrint(
          'Fetch Product Services UserDetails Response: ${responseDone.body}');
      if (res.statusCode == 200) {
        final responseData = json.decode(responseDone.body);
        if (responseData['data'] is List) {
          return responseData['data'];
        }
      }
    } catch (e) {
      debugPrint('Error in fetch product services: $e');
    }
    return [];
  }
}
