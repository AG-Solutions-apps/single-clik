import 'package:shared_preferences/shared_preferences.dart';

class SharPreferences {
  static const isLogin = "isLogin";
  static const userData = "userData";
  static const token = "token";
  static const fcmToken = "fcmToken";
  static const userId = "userId";
  static const businessRequestSubmitted = "businessRequestSubmitted";

  static Future<bool?> getBoolean(String key) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key);
  }

  static Future<void> setBoolean(String key, bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  static Future<String?>? getString(String key) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  static Future<void> setString(String key, String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  static Future<List<String>?>? getListString(String key) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(key);
  }

  static Future<void> setListString(String key, List<String> value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(key, value);
  }

  static Future<void> clearSharPreference() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.clear();
  }

}
//local storage