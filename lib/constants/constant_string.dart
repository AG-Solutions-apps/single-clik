import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

class ConstantString {
  static String dataNotFoundLabel = 'Data Not Found....';
  static String pleaseWaitLabel = 'Please wait...';
  static String loadingLabel = 'Loading...';
  static String naLabel = 'N/A';
  static String notAvailableLabel = 'Not Available';
  static String yesLabel = 'Yes';
  static String noLabel = 'No';
  static String somethingWantWrongMsg =
      'Sorry, Something want wrong\nPlease try again later...';
  static String alreadyJoinAsMsg = 'Your business account is under the review.';
  static String dataUpdatedSuccessfullyMsg = 'Data Updated Successfully';
  static String dataSubmittedSuccessfullyMsg = 'Data Submitted Successfully';
  static String dataDeletedSuccessfullyMsg = 'Data Deleted Successfully';
  static String enquireCloseSuccessfullyMsg = 'Enquire Close Successfully';
  static String businessServiceMembersEmptyMsg =
      "This category is still empty. We'll attempt to add someone shortly.";

  /// IMG PATH'S
  static String imgBaseUrlPath =
      'https://singleclik.com/api/storage/app/public/';

  static String userImgUrlPath = '${imgBaseUrlPath}user_images/';
  static String sliderImgUrlPath = '${imgBaseUrlPath}slider_images/';
  static String categoriesImgUrlPath = '${imgBaseUrlPath}categories_images/';
  static String developerImgUrlPath = '${imgBaseUrlPath}developer_images/';
  static String notificationImgUrlPath =
      '${imgBaseUrlPath}notification_images/';
  static String productImgUrlPath = '${imgBaseUrlPath}product_images/';
  static String noImgUrlPath = '${imgBaseUrlPath}no_image.jpg';
  static String aboutUsBGPath = '${notificationImgUrlPath}background.png';

  static String loginTermsUrl = 'https://singleclik.com/draft/tclogin.html';
  static String businessTermsUrl =
      'https://singleclik.com/draft/tcbusiness.html';

  static Future<bool> checkInternet() async {
    try {
      // Step 1: Check all connectivity types
      final connectivityResults = await Connectivity().checkConnectivity();

      // If none of the connectivity options are active, return false
      if (connectivityResults
          .every((result) => result == ConnectivityResult.none)) {
        return false;
      }

      // Step 2: Check actual internet access
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
