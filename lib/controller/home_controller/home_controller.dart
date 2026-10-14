// lib/controllers/home_controller.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:single_clik/constants/constant_string.dart';
import 'package:single_clik/constants/show_toast.dart';
import 'package:single_clik/services/api.dart';
import 'package:single_clik/utils/shar_preferences.dart';
import 'package:single_clik/utils/cache_manager.dart';
import 'package:single_clik/widget/app_image_assets.dart';
import '../../Model/on_board_model.dart';

class HomeController extends GetxController
    with GetSingleTickerProviderStateMixin {
  final isLoading = false.obs;
  final isAddLoading = false.obs;
  final isOnBoardingLoading = false.obs;
  final isButtonLoading = false.obs;
  final isRefreshing = false.obs;
  /// True while a full app refresh (cache bust + re-fetch) is running
  final isFullRefreshing = false.obs;
  /// Incremented each time the profile photo is force-refreshed.
  /// Used as a ValueKey on image widgets so Flutter recreates them after refresh.
  final photoVersion = 0.obs;

  final searchController = TextEditingController().obs;
  FocusNode searchFocusNode = FocusNode();

  late TabController tabController;
  RxInt tabIndex = 0.obs;
  RxInt selectTab = 0.obs;
  RxBool isSearchOpen = false.obs;

  // Cache keys
  static const String CACHE_DASHBOARD = 'dashboard_data';
  static const String CACHE_BUSINESS = 'business_data';
  static const String CACHE_SERVICES = 'services_data';
  static const String CACHE_SLIDER = 'slider_data';
  static const String CACHE_ADV_SLIDER = 'adv_slider_data';
  static const String CACHE_ONBOARD = 'onboard_data';
  static const String CACHE_CATEGORIES = 'categories_data';
  static const String CACHE_USER_PROFILE = 'user_profile';
  static const String CACHE_ENQUIRY_COUNTS = 'enquiry_counts';
  
  static const Duration CACHE_DURATION = Duration(minutes: 30);

  final allList = <dynamic>[].obs;
  final searchAllList = <dynamic>[].obs;
  final allSliderList = <dynamic>[].obs;
  final searchAllSliderList = <dynamic>[].obs;
  final allAdvSliderList = <dynamic>[].obs;
  final searchAllAdvSliderList = <dynamic>[].obs;
  final businessList = <dynamic>[].obs;
  final servicesList = <dynamic>[].obs;
  final allAdvPopUpSliderList = <dynamic>[].obs;

  final categoryList = <dynamic>[].obs;
  final categorySelect = {}.obs;

  final subCategoryList = <dynamic>[].obs;
  final subCategorySelect = {}.obs;

  final priorityTypeSelect = 'Urgent'.obs;

  final inquiryController = TextEditingController().obs;
  RxInt pendingOpenInquiriesCount = 0.obs;
  RxInt receivedUnreadCount = 0.obs;
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  RxBool isInitialLoadComplete = false.obs;
  final _requestLocks = <String, bool>{};
  
  late Timer timer;
  late Timer countTimer;
  bool _isDisposed = false;

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 3, vsync: this, initialIndex: 0);
    _initializeData();
  }

  Future<void> _initializeData() async {
    final isLogin = await SharPreferences.getBoolean(SharPreferences.isLogin) ?? false;
    final token = await SharPreferences.getString(SharPreferences.token) ?? '';
    if (!isLogin || token.trim().isEmpty) {
      debugPrint('User not logged in or token empty, skipping home data initialization.');
      return;
    }
    await _loadAllCachedData();
    await refreshAllData();
    isInitialLoadComplete.value = true;
    getDashboardTimer();
  }

  Future<void> checkAndInitializeData() async {
    if (!isInitialLoadComplete.value) {
      await _initializeData();
    }
  }

  void getDashboardTimer() {
    countTimer = Timer.periodic(
      const Duration(seconds: 2),
      (Timer timer) async {
        if (!_isDisposed) {
          final token = await SharPreferences.getString(SharPreferences.token) ?? '';
          if (token.trim().isNotEmpty) {
            getSentEnquiriesUnreadCount('1', forceRefresh: true);
          }
        }
      },
    );

    timer = Timer.periodic(
      const Duration(seconds: 25),
      (Timer timer) async {
        if (!_isDisposed) {
          final token = await SharPreferences.getString(SharPreferences.token) ?? '';
          if (token.trim().isNotEmpty) {
            refreshDashboardAndProfile();
          }
        }
      },
    );
  }

  Future<void> refreshDashboardAndProfile() async {
    if (_isDisposed) return;
    if (isSearchOpen.value || searchController.value.text.trim().isNotEmpty) {
      debugPrint('Skipping background auto-refresh because search is active.');
      return;
    }
    try {
      final token = await SharPreferences.getString(SharPreferences.token) ?? '';
      if (token.trim().isEmpty) return;
      final userId = await SharPreferences.getString(SharPreferences.userId) ?? '';
      if (userId.isNotEmpty) {
        await Future.wait([
          postFetchProfileApi(forceRefresh: true),
          postDashboardApi(userId, forceRefresh: true),
        ]);
      }
    } catch (e) {
      debugPrint('Background dashboard sync error: $e');
    }
  }

  Future<void> _loadAllCachedData() async {
    await Future.wait([
      _loadCachedDashboard(),
      _loadCachedBusinessData(),
      _loadCachedServicesData(),
      _loadCachedSliderData(),
      _loadCachedOnboardData(),
      _loadCachedProfileData(),
      _loadCachedEnquiryCounts(),
    ]);
  }

  Future<void> _loadCachedDashboard() async {
    try {
      final cachedData = await CacheManager.get(CACHE_DASHBOARD);
      if (cachedData != null) {
        allList.value = cachedData['data'] ?? [];
        searchAllList.value = cachedData['data'] ?? [];
        debugPrint('✅ Loaded dashboard from cache: ${allList.length} items');
      }
    } catch (e) {
      debugPrint('Error loading cached dashboard: $e');
    }
  }

  Future<void> _loadCachedBusinessData() async {
    try {
      final cachedData = await CacheManager.get(CACHE_BUSINESS);
      if (cachedData != null) {
        businessList.value = cachedData['data'] ?? [];
        debugPrint('✅ Loaded business data from cache: ${businessList.length} items');
      }
    } catch (e) {
      debugPrint('Error loading cached business data: $e');
    }
  }

  Future<void> _loadCachedServicesData() async {
    try {
      final cachedData = await CacheManager.get(CACHE_SERVICES);
      if (cachedData != null) {
        servicesList.value = cachedData['data'] ?? [];
        debugPrint('✅ Loaded services data from cache: ${servicesList.length} items');
      }
    } catch (e) {
      debugPrint('Error loading cached services data: $e');
    }
  }

  Future<void> _loadCachedSliderData() async {
    try {
      final cachedData = await CacheManager.get(CACHE_SLIDER);
      if (cachedData != null) {
        allSliderList.value = cachedData['data'] ?? [];
        searchAllSliderList.value = cachedData['data'] ?? [];
        debugPrint('✅ Loaded slider from cache: ${allSliderList.length} items');
      }
    } catch (e) {
      debugPrint('Error loading cached slider: $e');
    }
  }

  Future<void> _loadCachedOnboardData() async {
    try {
      final cachedData = await CacheManager.get(CACHE_ONBOARD);
      if (cachedData != null) {
        onBoardList.value = OnBoardModel.fromJson(cachedData['data']);
        debugPrint('✅ Loaded onboard data from cache');
      }
    } catch (e) {
      debugPrint('Error loading cached onboard data: $e');
    }
  }

  Future<void> _loadCachedProfileData() async {
    try {
      final cachedData = await CacheManager.get(CACHE_USER_PROFILE);
      if (cachedData != null) {
        userData.value = cachedData['data'];
        debugPrint('✅ Loaded profile from cache');
      }
    } catch (e) {
      debugPrint('Error loading cached profile: $e');
    }
  }

  Future<void> _loadCachedEnquiryCounts() async {
    try {
      final cachedData = await CacheManager.get(CACHE_ENQUIRY_COUNTS);
      if (cachedData != null) {
        pendingOpenInquiriesCount.value = cachedData['pending'] ?? 0;
        receivedUnreadCount.value = cachedData['received'] ?? 0;
        debugPrint('✅ Loaded enquiry counts from cache');
      }
    } catch (e) {
      debugPrint('Error loading cached enquiry counts: $e');
    }
  }

  Future<void> refreshAllData() async {
    if (isRefreshing.value) return;
    
    isRefreshing.value = true;
    
    try {
      final userId = await SharPreferences.getString(SharPreferences.userId) ?? '';
      
      await Future.wait([
        postDashboardApi(userId, forceRefresh: true),
        postBusinessDashboardApi("0", forceRefresh: true),
        postBusinessDashboardApi("1", forceRefresh: true),
        postDashboardSliderApi("", forceRefresh: true),
        postFetchProfileApi(forceRefresh: true),
        getSentEnquiriesUnreadCount('1', forceRefresh: true),
      ]);
      
      debugPrint('✅ All data refreshed successfully');
    } catch (e) {
      debugPrint('❌ Error refreshing data: $e');
    } finally {
      isRefreshing.value = false;
    }
  }

  void searchProduct(String query) {
    if (searchAllList.isEmpty) return;
    
    isLoading(true);
    try {
      if (query.isEmpty) {
        allList.value = searchAllList;
      } else {
        allList.value = searchAllList
            .where((item) =>
                (item['name']?.toString().trim().toLowerCase().contains(query.toString().trim().toLowerCase()) ?? false) ||
                (item['company_name']?.toString().trim().toLowerCase().contains(query.toString().trim().toLowerCase()) ?? false) ||
                (item['category']?.toString().trim().toLowerCase().contains(query.toString().trim().toLowerCase()) ?? false) ||
                (item['subcategory']?.toString().trim().toLowerCase().contains(query.toString().trim().toLowerCase()) ?? false))
            .toList();
      }
      debugPrint('Search results: ${allList.length}');
    } catch (e) {
      debugPrint('Search error: $e');
    } finally {
      isLoading(false);
    }
  }

  Future<void> postDashboardApi(String userId, {bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cachedData = await CacheManager.get(CACHE_DASHBOARD);
      if (cachedData != null && cachedData['timestamp'] != null) {
        final age = DateTime.now().difference(DateTime.parse(cachedData['timestamp']));
        if (age < CACHE_DURATION) {
          allList.value = cachedData['data'] ?? [];
          searchAllList.value = cachedData['data'] ?? [];
          debugPrint('✅ Using cached dashboard data (age: ${age.inMinutes} min)');
          return;
        }
      }
    }
    
    if (_requestLocks['dashboard'] == true) return;
    _requestLocks['dashboard'] = true;
    
    try {
      if (!forceRefresh) isLoading.value = true;
      
      final token = await SharPreferences.getString(SharPreferences.token) ?? '';
      if (token.trim().isEmpty) {
        debugPrint('Dashboard API Error: Token is empty');
        return;
      }
      if (userId.isEmpty) {
        userId = await SharPreferences.getString(SharPreferences.userId) ?? '';
      }
      
      final response = await http.post(
        Uri.parse(API.dashboard),
        headers: {
          'Authorization': 'Bearer ${token.trim()}',
          'Accept': 'application/json',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {"user_id": userId},
      ).timeout(const Duration(seconds: 30));
      
      if (response.body.trim().startsWith('<!DOCTYPE') || 
          response.body.trim().startsWith('<html')) {
        debugPrint('❌ ERROR: Server returned HTML instead of JSON');
        return;
      }
      
      final data = json.decode(response.body);
      
      if (data['code'] == 200) {
        final dashboardData = data['data'] ?? [];
        allList.value = dashboardData;
        searchAllList.value = dashboardData;
        
        await CacheManager.set(CACHE_DASHBOARD, {
          'data': dashboardData,
          'timestamp': DateTime.now().toIso8601String(),
        });
        debugPrint('✅ Dashboard data cached: ${dashboardData.length} items');
      }
    } catch (e) {
      debugPrint('❌ Dashboard API Error: $e');
    } finally {
      if (!forceRefresh) isLoading.value = false;
      _requestLocks['dashboard'] = false;
    }
  }

  Future<void> postBusinessDashboardApi(String? profileType, {bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cacheKey = profileType == "0" ? CACHE_BUSINESS : CACHE_SERVICES;
      final cachedData = await CacheManager.get(cacheKey);
      if (cachedData != null && cachedData['timestamp'] != null) {
        final age = DateTime.now().difference(DateTime.parse(cachedData['timestamp']));
        if (age < CACHE_DURATION) {
          if (profileType == "0") {
            businessList.value = cachedData['data'];
          } else if (profileType == "1") {
            servicesList.value = cachedData['data'];
          }
          debugPrint('✅ Using cached ${profileType == "0" ? "business" : "services"} data');
          return;
        }
      }
    }
    
    final lockKey = 'business_${profileType}';
    if (_requestLocks[lockKey] == true) return;
    _requestLocks[lockKey] = true;
    
    try {
      if (!forceRefresh) isLoading.value = true;
      
      final token = await SharPreferences.getString(SharPreferences.token) ?? '';
      if (token.trim().isEmpty) {
        debugPrint('Business Dashboard API Error: Token is empty');
        return;
      }
      
      final response = await http.post(
        Uri.parse(API.dashboardCategories),
        headers: {
          'Authorization': 'Bearer ${token.trim()}',
          'Accept': 'application/json',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {'categories_type': profileType!},
      ).timeout(const Duration(seconds: 30));
      
      if (response.body.trim().startsWith('<!DOCTYPE') || 
          response.body.trim().startsWith('<html')) {
        debugPrint('❌ ERROR: Server returned HTML instead of JSON');
        return;
      }
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData['code'] == 200 && responseData['data'] != null) {
          List dataList = List.from(responseData['data']);
          List finalDataList = [];
          
          dataList.removeWhere((element) => 
            element['member_count'] == null || 
            element['member_count'] == 0
          );
          
          finalDataList.addAll(dataList);
          
          if (profileType == "0") {
            businessList.value = finalDataList;
            await CacheManager.set(CACHE_BUSINESS, {
              'data': finalDataList,
              'timestamp': DateTime.now().toIso8601String(),
            });
          } else if (profileType == "1") {
            servicesList.value = finalDataList;
            await CacheManager.set(CACHE_SERVICES, {
              'data': finalDataList,
              'timestamp': DateTime.now().toIso8601String(),
            });
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Exception in postBusinessDashboardApi: $e');
    } finally {
      if (!forceRefresh) isLoading.value = false;
      _requestLocks[lockKey] = false;
    }
  }

  Future<void> postDashboardSliderApi(String? profileType, {bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cachedData = await CacheManager.get(CACHE_SLIDER);
      if (cachedData != null && cachedData['timestamp'] != null) {
        final age = DateTime.now().difference(DateTime.parse(cachedData['timestamp']));
        if (age < CACHE_DURATION) {
          allSliderList.value = cachedData['data'];
          searchAllSliderList.value = cachedData['data'];
          return;
        }
      }
    }
    
    if (_requestLocks['slider'] == true) return;
    _requestLocks['slider'] = true;
    
    try {
      final token = await SharPreferences.getString(SharPreferences.token) ?? '';
      if (token.trim().isEmpty) {
        debugPrint('Slider API: Token is empty');
        return;
      }
      final request = http.MultipartRequest('POST', Uri.parse(API.slider));
      request.headers.addAll({
        'Authorization': 'Bearer ${token.trim()}',
        'Accept': 'application/json',
      });
      request.fields.addAll({'profile_type': profileType!});

      var res = await request.send().timeout(const Duration(seconds: 30));
      var responseDone = await http.Response.fromStream(res);

      if (res.statusCode == 200) {
        final responseData = json.decode(responseDone.body);
        if (responseData['code'] == 200) {
          final sliderData = responseData['data'] ?? [];
          allSliderList.value = sliderData;
          searchAllSliderList.value = sliderData;
          
          await CacheManager.set(CACHE_SLIDER, {
            'data': sliderData,
            'timestamp': DateTime.now().toIso8601String(),
          });
        }
      }
    } catch (e) {
      debugPrint('Slider API Error: $e');
    } finally {
      _requestLocks['slider'] = false;
    }
  }

  Future<void> postDashboardAdvSliderApi() async {
    if (_requestLocks['advSlider'] == true) return;
    _requestLocks['advSlider'] = true;
    
    try {
      final token = await SharPreferences.getString(SharPreferences.token) ?? '';
      if (token.trim().isEmpty) {
        debugPrint('AdvSlider API: Token is empty');
        return;
      }
      final request = http.MultipartRequest('POST', Uri.parse(API.advSlider));
      request.headers.addAll({
        'Authorization': 'Bearer ${token.trim()}',
        'Accept': 'application/json',
      });

      var res = await request.send().timeout(const Duration(seconds: 30));
      var responseDone = await http.Response.fromStream(res);

      if (res.statusCode == 200) {
        final responseData = json.decode(responseDone.body);
        if (responseData['code'] == 200) {
          allAdvSliderList.value = responseData['data'] ?? [];
          searchAllAdvSliderList.value = responseData['data'] ?? [];
        }
      }
    } catch (e) {
      debugPrint('AdvSlider API Error: $e');
    } finally {
      _requestLocks['advSlider'] = false;
    }
  }

  Future<void> postDashboardAdvPopUpSliderApi() async {
    if (_requestLocks['advPopUp'] == true) return;
    _requestLocks['advPopUp'] = true;
    
    try {
      final token = await SharPreferences.getString(SharPreferences.token) ?? '';
      if (token.trim().isEmpty) {
        debugPrint('AdvPopUpSlider API: Token is empty');
        return;
      }
      final request = http.MultipartRequest('POST', Uri.parse(API.advPopUpSlider));
      request.headers.addAll({
        'Authorization': 'Bearer ${token.trim()}',
        'Accept': 'application/json',
      });

      var res = await request.send().timeout(const Duration(seconds: 30));
      var responseDone = await http.Response.fromStream(res);

      if (res.statusCode == 200) {
        final responseData = json.decode(responseDone.body);
        if (responseData['code'] == 200) {
          allAdvPopUpSliderList.value = responseData['data'] ?? [];
        }
      }
    } catch (e) {
      debugPrint('AdvPopUpSlider API Error: $e');
    } finally {
      _requestLocks['advPopUp'] = false;
    }
  }

  Rx<OnBoardModel> onBoardList = OnBoardModel().obs;
  
  Future<void> fetchOnboardApi({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cachedData = await CacheManager.get(CACHE_ONBOARD);
      if (cachedData != null && cachedData['timestamp'] != null) {
        final age = DateTime.now().difference(DateTime.parse(cachedData['timestamp']));
        if (age < CACHE_DURATION) {
          onBoardList.value = OnBoardModel.fromJson(cachedData['data']);
          return;
        }
      }
    }
    
    if (_requestLocks['onboard'] == true) return;
    _requestLocks['onboard'] = true;
    
    try {
      isOnBoardingLoading.value = true;
      
      final request = http.MultipartRequest('POST', Uri.parse(API.onboard));
      request.headers['Accept'] = 'application/json';
      var res = await request.send().timeout(const Duration(seconds: 30));
      var responseDone = await http.Response.fromStream(res);

      if (res.statusCode == 200) {
        final responseData = json.decode(responseDone.body);
        onBoardList.value = OnBoardModel.fromJson(responseData);
        
        await CacheManager.set(CACHE_ONBOARD, {
          'data': responseData,
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('Onboard API Error: $e');
    } finally {
      isOnBoardingLoading.value = false;
      _requestLocks['onboard'] = false;
    }
  }

  Future<void> postCategoriesApi() async {
    final cachedData = await CacheManager.get(CACHE_CATEGORIES);
    if (cachedData != null && cachedData['timestamp'] != null) {
      final age = DateTime.now().difference(DateTime.parse(cachedData['timestamp']));
      if (age < CACHE_DURATION) {
        categoryList.value = cachedData['data'];
        return;
      }
    }
    
    if (_requestLocks['categories'] == true) return;
    _requestLocks['categories'] = true;
    
    try {
      isAddLoading.value = true;
      final token = await SharPreferences.getString(SharPreferences.token) ?? '';
      if (token.trim().isEmpty) {
        debugPrint('Categories API: Token is empty');
        return;
      }
      final request = http.MultipartRequest('POST', Uri.parse(API.categories));
      request.headers.addAll({
        'Authorization': 'Bearer ${token.trim()}',
        'Accept': 'application/json',
      });

      var res = await request.send().timeout(const Duration(seconds: 30));
      var responseDone = await http.Response.fromStream(res);
      
      if (res.statusCode == 200) {
        final responseData = json.decode(responseDone.body);
        categoryList.value = responseData['data'];
        
        await CacheManager.set(CACHE_CATEGORIES, {
          'data': responseData['data'],
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('Categories API Error: $e');
    } finally {
      isAddLoading.value = false;
      _requestLocks['categories'] = false;
    }
  }

  Future<void> postSubCategoriesApi(String? categoryId) async {
    try {
      isAddLoading.value = true;
      final token = await SharPreferences.getString(SharPreferences.token) ?? '';
      if (token.trim().isEmpty) {
        debugPrint('Subcategories API: Token is empty');
        return;
      }
      final request = http.MultipartRequest('POST', Uri.parse(API.subcategories));
      request.headers.addAll({
        'Authorization': 'Bearer ${token.trim()}',
        'Accept': 'application/json',
      });
      request.fields.addAll({'category_id': categoryId!});

      var res = await request.send().timeout(const Duration(seconds: 30));
      var responseDone = await http.Response.fromStream(res);
      
      if (res.statusCode == 200) {
        final responseData = json.decode(responseDone.body);
        subCategoryList.value = responseData['data'];
      }
    } catch (e) {
      debugPrint('Subcategories API Error: $e');
    } finally {
      isAddLoading.value = false;
    }
  }

  Future<List> postSubCategoriesListApiLis(String? categoryId) async {
    List subCategoryDataList = [];
    try {
      final token = await SharPreferences.getString(SharPreferences.token) ?? '';
      if (token.trim().isEmpty) {
        return [];
      }
      final request = http.MultipartRequest('POST', Uri.parse(API.subcategories));
      request.headers.addAll({
        'Authorization': 'Bearer ${token.trim()}',
        'Accept': 'application/json',
      });
      request.fields.addAll({'category_id': categoryId!});

      var res = await request.send().timeout(const Duration(seconds: 30));
      var responseDone = await http.Response.fromStream(res);
      
      if (res.statusCode == 200) {
        final responseData = json.decode(responseDone.body);
        subCategoryDataList = responseData['data'];
      }
    } catch (e) {
      debugPrint('Subcategories API Error: $e');
    }
    return subCategoryDataList;
  }

  Future<bool> postCreateEnquiryApi(Map<String, String> bodyParams) async {
    try {
      isButtonLoading.value = true;
      
      final token = await SharPreferences.getString(SharPreferences.token) ?? '';
      if (token.isEmpty) {
        ShowToast.showToast('Authentication error. Please login again.', showSuccess: false);
        isButtonLoading.value = false;
        return false;
      }
      
      final request = http.MultipartRequest('POST', Uri.parse(API.createEnquiry));
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/x-www-form-urlencoded',
      });
      request.fields.addAll(bodyParams);

      final response = await request.send().timeout(const Duration(seconds: 30));
      final responseBody = await response.stream.bytesToString();
      
      if (responseBody.trim().isEmpty) {
        ShowToast.showToast('Server returned empty response', showSuccess: false);
        isButtonLoading.value = false;
        return false;
      }
      
      if (responseBody.trim().startsWith('<!DOCTYPE') || 
          responseBody.trim().startsWith('<html')) {
        ShowToast.showToast('Server error. Please try again later.', showSuccess: false);
        isButtonLoading.value = false;
        return false;
      }
      
      try {
        final responseData = json.decode(responseBody);
        
        bool enquiryCreated = false;
        String successMessage = '';
        
        if (responseData['enquiry_id'] != null || 
            responseData['id'] != null || 
            responseData['data'] != null ||
            (responseData['message'] != null && responseData['message'].toString().contains('Connection could not be established'))) {
          enquiryCreated = true;
          successMessage = 'Enquiry created successfully';
        }
        
        if (responseData['code'] != null) {
          if (responseData['code'] is int) {
            enquiryCreated = enquiryCreated || (responseData['code'] == 200 || responseData['code'] == 201);
          } else if (responseData['code'] is String) {
            enquiryCreated = enquiryCreated || (responseData['code'] == '200' || responseData['code'] == '201');
          }
          if (responseData['msg'] != null) successMessage = responseData['msg'];
        }
        
        if (response.statusCode == 500 && responseBody.contains('mail.singleclik.in')) {
          enquiryCreated = true;
          successMessage = 'Enquiry created successfully';
        }
        
        if (enquiryCreated) {
          await getSentEnquiriesUnreadCount('1', forceRefresh: true);
          ShowToast.showToast(
            successMessage.isNotEmpty ? successMessage : ConstantString.dataSubmittedSuccessfullyMsg,
            showSuccess: true,
          );
          isButtonLoading.value = false;
          return true;
        } else {
          ShowToast.showToast(
            successMessage.isNotEmpty ? successMessage : 'Failed to create enquiry',
            showSuccess: false,
          );
          isButtonLoading.value = false;
          return false;
        }
      } catch (e) {
        if (responseBody.contains('success') || 
            responseBody.contains('created') || 
            responseBody.contains('mail.singleclik.in') ||
            response.statusCode == 500) {
          await getSentEnquiriesUnreadCount('1', forceRefresh: true);
          ShowToast.showToast('Enquiry created successfully', showSuccess: true);
          isButtonLoading.value = false;
          return true;
        }
        
        ShowToast.showToast('Server response error. Please check if enquiry was created.', showSuccess: false);
        isButtonLoading.value = false;
        return false;
      }
    } on TimeoutException catch (e) {
      ShowToast.showToast('Connection timeout. Please check if enquiry was created.', showSuccess: false);
      isButtonLoading.value = false;
      return false;
    } on SocketException catch (e) {
      ShowToast.showToast('No internet connection', showSuccess: false);
      isButtonLoading.value = false;
      return false;
    } catch (e) {
      ShowToast.showToast('Something went wrong. Please check if enquiry was created.', showSuccess: false);
      isButtonLoading.value = false;
      return false;
    }
  }

  Future<void> getSentEnquiriesUnreadCount(String? enquiriesType, {bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cachedData = await CacheManager.get(CACHE_ENQUIRY_COUNTS);
      if (cachedData != null && cachedData['timestamp'] != null) {
        final age = DateTime.now().difference(DateTime.parse(cachedData['timestamp']));
        if (age < const Duration(minutes: 5)) {
          pendingOpenInquiriesCount.value = cachedData['pending'] ?? 0;
          receivedUnreadCount.value = cachedData['received'] ?? 0;
          return;
        }
      }
    }
    
    try {
      final token = await SharPreferences.getString(SharPreferences.token) ?? '';
      if (token.trim().isEmpty) {
        return;
      }
      final request = http.MultipartRequest('POST', Uri.parse(API.enquirySentCount));
      request.headers.addAll({
        'Authorization': 'Bearer ${token.trim()}',
        'Accept': 'application/json',
      });

      var res = await request.send().timeout(const Duration(seconds: 15));
      var responseDone = await http.Response.fromStream(res);

      if (res.statusCode == 200) {
        final responseData = json.decode(responseDone.body);
        pendingOpenInquiriesCount.value = ((responseData['data'] ?? 0) as int);
      }
    } catch (e) {
      debugPrint("Sent Enquiries Count Error: $e");
    }

    await getReceivedEnquiriesUnreadCount();
    
    await CacheManager.set(CACHE_ENQUIRY_COUNTS, {
      'pending': pendingOpenInquiriesCount.value,
      'received': receivedUnreadCount.value,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> getReceivedEnquiriesUnreadCount() async {
    try {
      final token = await SharPreferences.getString(SharPreferences.token) ?? '';
      if (token.trim().isEmpty) {
        return;
      }
      final request = http.MultipartRequest('POST', Uri.parse(API.enquiryReceivedCount));
      request.headers.addAll({
        'Authorization': 'Bearer ${token.trim()}',
        'Accept': 'application/json',
      });
      request.fields.addAll({'enquiries_type': '1'});

      var res = await request.send().timeout(const Duration(seconds: 15));
      var responseDone = await http.Response.fromStream(res);
      
      if (res.statusCode == 200) {
        final responseData = json.decode(responseDone.body);
        receivedUnreadCount.value = ((responseData['data'] ?? 0) as int);
      }
    } catch (e) {
      debugPrint("Received Enquiries Count Error: $e");
    }
  }

  RxMap userData = {}.obs;

  Future<void> postFetchProfileApi({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cachedData = await CacheManager.get(CACHE_USER_PROFILE);
      if (cachedData != null && cachedData['timestamp'] != null) {
        final age = DateTime.now().difference(DateTime.parse(cachedData['timestamp']));
        if (age < CACHE_DURATION) {
          userData.value = cachedData['data'];
          debugPrint('✅ Using cached profile data (age: ${age.inMinutes} min)');
          return;
        }
      }
    }
    
    if (_requestLocks['profile'] == true) return;
    _requestLocks['profile'] = true;
    
    try {
      final token = await SharPreferences.getString(SharPreferences.token) ?? '';
      if (token.trim().isEmpty) {
        debugPrint('FetchProfile API: Token is empty');
        userData.value = {};
        return;
      }
      final request = http.MultipartRequest('POST', Uri.parse(API.fetchProfile));
      request.headers.addAll({
        'Authorization': 'Bearer ${token.trim()}',
        'Accept': 'application/json',
      });
      
      var res = await request.send().timeout(const Duration(seconds: 30));
      var responseDone = await http.Response.fromStream(res);

      if (res.statusCode == 200) {
        final responseBody = jsonDecode(responseDone.body);
        dynamic dataField = responseBody["data"];
        Map<String, dynamic> parsedProfile = {};
        List<dynamic> parsedProducts = [];

        if (dataField is List) {
          if (dataField.isNotEmpty) {
            var firstItem = dataField[0];
            if (firstItem is Map) {
              if (firstItem.containsKey('product_name') || firstItem.containsKey('product_status')) {
                parsedProducts = dataField;
              } else {
                parsedProfile = Map<String, dynamic>.from(firstItem);
                if (firstItem.containsKey('products')) {
                  parsedProducts = List.from(firstItem['products'] ?? []);
                } else if (firstItem.containsKey('product_services')) {
                  parsedProducts = List.from(firstItem['product_services'] ?? []);
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

        if (responseBody['products'] is List) {
          parsedProducts = List.from(responseBody['products']);
        } else if (responseBody['product_services'] is List) {
          parsedProducts = List.from(responseBody['product_services']);
        }

        // Fetch products/services from the dedicated endpoint as the primary source
        final productsList = await postFetchProductServicesApi();
        if (productsList.isNotEmpty) {
          parsedProducts = productsList;
        }

        parsedProfile['products'] = parsedProducts;
        parsedProfile['product_services'] = parsedProducts;

        userData.value = parsedProfile;
        
        await CacheManager.set(CACHE_USER_PROFILE, {
          'data': parsedProfile,
          'timestamp': DateTime.now().toIso8601String(),
        });
        debugPrint('✅ Profile data cached');
      } else {
        userData.value = {};
      }
    } catch (e) {
      debugPrint("Profile API Error: $e");
      userData.value = {};
    } finally {
      _requestLocks['profile'] = false;
    }
  }

  Future<List<dynamic>> postFetchProductServicesApi({String? userId}) async {
    try {
      final token = await SharPreferences.getString(SharPreferences.token) ?? '';
      if (token.trim().isEmpty) {
        return [];
      }
      final request = http.MultipartRequest('POST', Uri.parse(API.fetchProductServices));
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
      debugPrint('Fetch Product Services Response Code: ${res.statusCode}');
      debugPrint('Fetch Product Services Response: ${responseDone.body}');
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

  /// Clears ONLY the SharedPreferences API-response cache.
  Future<void> clearAllCache() async {
    await CacheManager.clearAll();
    debugPrint('✅ All API cache cleared');
  }

  /// Full app refresh:
  ///  1. Clears all SharedPrefs API cache
  ///  2. Clears the network-image disk cache (so updated profile photos load fresh)
  ///  3. Re-fetches profile + dashboard + counts
  Future<void> fullAppRefresh() async {
    if (isFullRefreshing.value) return;
    isFullRefreshing.value = true;
    try {
      // 1. Clear API response cache (SharedPreferences)
      await CacheManager.clearAll();

      // 2. Clear image disk cache so updated profile photos are re-downloaded
      await AppImageCacheManager.clearImageCache();

      // 3. Bump photo version — forces all image widgets with this key to rebuild
      photoVersion.value++;

      // 4. Re-fetch all data fresh from server
      final userId = await SharPreferences.getString(SharPreferences.userId) ?? '';
      await Future.wait([
        postFetchProfileApi(forceRefresh: true),
        postDashboardApi(userId, forceRefresh: true),
        postDashboardSliderApi('', forceRefresh: true),
        postDashboardAdvSliderApi(),
        postBusinessDashboardApi('0', forceRefresh: true),
        postBusinessDashboardApi('1', forceRefresh: true),
        getSentEnquiriesUnreadCount('1', forceRefresh: true),
      ]);

      debugPrint('✅ Full app refresh complete (photo v${photoVersion.value})');
      ShowToast.showToast('App refreshed!', showSuccess: true);
    } catch (e) {
      debugPrint('❌ Full refresh error: $e');
      ShowToast.showToast('Refresh failed. Please try again.', showSuccess: false);
    } finally {
      isFullRefreshing.value = false;
    }
  }

  @override
  void onClose() {
    _isDisposed = true;
    timer.cancel();
    countTimer.cancel();
    tabController.dispose();
    searchFocusNode.dispose();
    searchController.value.dispose();
    inquiryController.value.dispose();
    super.onClose();
  }
}