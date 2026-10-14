import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:new_version_plus/new_version_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:single_clik/constants/constant_color.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUpdateController extends GetxController {
  bool _isDialogShowing = false;

  final String appPackageName = "com.singleclick.agsolution";

  /// Set to true only when you want to test the update popup.
  /// Keep this false for production.
  bool forceTestUpdateDialog = false;

  @override
  void onInit() {
    super.onInit();

    debugPrint("🔄 AppUpdateController initialized.");

    // Check for update only ONCE when the app opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkForUpdate();
    });
  }

  @override
  void onClose() {
    super.onClose();
  }

  Future<void> checkForUpdate() async {
    // Prevent multiple dialogs at the same time.
    if (_isDialogShowing) return;

    try {
      debugPrint(
        "🔍 [AppUpdateController] Checking for Play Store app updates...",
      );

      final packageInfo = await PackageInfo.fromPlatform();

      // Current installed app version
      final String localVersion = packageInfo.version;

      // ------------------------------------------------------------
      // TEST MODE
      // ------------------------------------------------------------
      // Keep this false in production.
      if (forceTestUpdateDialog) {
        debugPrint(
          "🧪 [AppUpdateController] Force test mode active.",
        );

        _showUpdateDialog(
          localVersion: localVersion,
          storeVersion: "4.1.0",
          appUrl:
              "https://play.google.com/store/apps/details?id=$appPackageName",
        );

        return;
      }

      // ------------------------------------------------------------
      // REAL PLAY STORE VERSION
      // ------------------------------------------------------------

      String storeVersion = "";

      String storeUrl =
          "https://play.google.com/store/apps/details?id=$appPackageName";

      bool canUpdate = false;

      // ------------------------------------------------------------
      // Strategy 1: NewVersionPlus
      // ------------------------------------------------------------
      try {
        final newVersion = NewVersionPlus(
          androidId: appPackageName,
          androidPlayStoreCountry: 'in',
        );

        final status = await newVersion.getVersionStatus();

        if (status != null && status.storeVersion.isNotEmpty) {
          storeVersion = status.storeVersion;

          if (status.appStoreLink.isNotEmpty) {
            storeUrl = status.appStoreLink;
          }

          canUpdate = status.canUpdate;
        }
      } catch (e) {
        debugPrint(
          "⚠️ NewVersionPlus check failed: $e",
        );
      }

      // ------------------------------------------------------------
      // Strategy 2: Direct Play Store fallback
      // ------------------------------------------------------------
      if (storeVersion.isEmpty) {
        final fallbackResult =
            await _fetchPlayStoreVersion(appPackageName);

        storeVersion = fallbackResult['version'] ?? "";

        if (storeVersion.isNotEmpty) {
          canUpdate =
              _isVersionHigher(storeVersion, localVersion);
        }
      }

      debugPrint(
        "📱 Local Version: $localVersion | "
        "🏪 Store Version: $storeVersion | "
        "Update Available: $canUpdate",
      );

      // ------------------------------------------------------------
      // SHOW UPDATE DIALOG ONLY IF NEW VERSION EXISTS
      // ------------------------------------------------------------
      if (storeVersion.isNotEmpty &&
          (canUpdate ||
              _isVersionHigher(storeVersion, localVersion))) {
        if (!_isDialogShowing) {
          debugPrint(
            "🚀 Triggering Update Dialog: "
            "Store ($storeVersion) > Local ($localVersion)",
          );

          _showUpdateDialog(
            localVersion: localVersion,
            storeVersion: storeVersion,
            appUrl: storeUrl,
          );
        }
      }
    } catch (e) {
      debugPrint(
        "❌ Error checking app update: $e",
      );
    }
  }

  // ------------------------------------------------------------
  // PLAY STORE FALLBACK
  // ------------------------------------------------------------

  Future<Map<String, String>> _fetchPlayStoreVersion(
    String packageName,
  ) async {
    try {
      final url = Uri.parse(
        "https://play.google.com/store/apps/details"
        "?id=$packageName&gl=in&hl=en",
      );

      final response = await http
          .get(url)
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final html = response.body;

        // Play Store version pattern
        final RegExp versionRegex = RegExp(
          r'\[\[\["(\d+\.\d+(?:\.\d+)?)"\]\]',
        );

        final match = versionRegex.firstMatch(html);

        if (match != null && match.groupCount >= 1) {
          final ver = match.group(1)!;

          debugPrint(
            "✅ Scraped Play Store Version: $ver",
          );

          return {
            'version': ver,
          };
        }
      }
    } catch (e) {
      debugPrint(
        "⚠️ Direct PlayStore scrape error: $e",
      );
    }

    return {};
  }

  // ------------------------------------------------------------
  // VERSION COMPARISON
  // ------------------------------------------------------------

  bool _isVersionHigher(
    String storeVersion,
    String localVersion,
  ) {
    try {
      final cleanStore =
          storeVersion.split('+')[0].trim();

      final cleanLocal =
          localVersion.split('+')[0].trim();

      final List<int> storeParts = cleanStore
          .split('.')
          .map((e) => int.tryParse(e) ?? 0)
          .toList();

      final List<int> localParts = cleanLocal
          .split('.')
          .map((e) => int.tryParse(e) ?? 0)
          .toList();

      final int maxLength =
          storeParts.length > localParts.length
              ? storeParts.length
              : localParts.length;

      for (int i = 0; i < maxLength; i++) {
        final int s =
            i < storeParts.length ? storeParts[i] : 0;

        final int l =
            i < localParts.length ? localParts[i] : 0;

        if (s > l) return true;

        if (s < l) return false;
      }
    } catch (e) {
      debugPrint(
        "⚠️ Version comparison error: $e",
      );
    }

    return false;
  }

  // ------------------------------------------------------------
  // UPDATE DIALOG
  // ------------------------------------------------------------

  void _showUpdateDialog({
    required String localVersion,
    required String storeVersion,
    required String appUrl,
  }) {
    _isDialogShowing = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.context != null && _isDialogShowing) {
        Get.dialog(
          PopScope(
            canPop: false,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),

              // ------------------------------------------------
              // TITLE
              // ------------------------------------------------

              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: ConstantColor.primary
                          .withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.system_update_rounded,
                      color: ConstantColor.primary,
                      size: 28,
                    ),
                  ),

                  const SizedBox(width: 12),

                  const Expanded(
                    child: Text(
                      "Update Available!",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              // ------------------------------------------------
              // CONTENT
              // ------------------------------------------------

              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    "A new version of SINGLE CLIk is available on Google Play Store.",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius:
                          BorderRadius.circular(8),
                    ),

                    child: Column(
                      children: [
                        // CURRENT VERSION
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Current Version:",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),

                            Text(
                              localVersion,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),

                        // LATEST VERSION
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Latest Version:",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),

                            Text(
                              storeVersion,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color:
                                    ConstantColor.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    "Please update the app to access the latest features and bug fixes.",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),

              // ------------------------------------------------
              // ACTIONS
              // ------------------------------------------------

              actions: [
                // LATER
                TextButton(
                  onPressed: () {
                    // Close the dialog.
                    //
                    // IMPORTANT:
                    // There is NO periodic timer anymore,
                    // so the dialog will NOT appear again
                    // during this app session.
                    _isDialogShowing = false;

                    Get.back();
                  },
                  child: const Text(
                    "Later",
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ),

                // UPDATE NOW
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        ConstantColor.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(8),
                    ),
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),

                  onPressed: () async {
                    final Uri uri =
                        Uri.parse(appUrl);

                    if (await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode:
                            LaunchMode.externalApplication,
                      );
                    } else {
                      await launchUrl(
                        Uri.parse(
                          "https://play.google.com/store/apps/details?id=$appPackageName",
                        ),
                        mode:
                            LaunchMode.externalApplication,
                      );
                    }
                  },

                  child: const Text(
                    "Update Now",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // User cannot dismiss by tapping outside.
          barrierDismissible: false,
        ).then((_) {
          _isDialogShowing = false;
        });
      }
    });
  }
}