import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shimmer/shimmer.dart';

import 'package:get/get.dart';
import 'package:single_clik/controller/home_controller/home_controller.dart';

import '../constants/constant_string.dart';

/// A singleton custom cache manager for app images.
/// Caches up to 200 images, each valid for 30 days.
class AppImageCacheManager extends CacheManager with ImageCacheManager {
  static const key = 'singleClikImageCache';
  static final AppImageCacheManager _instance = AppImageCacheManager._();
  factory AppImageCacheManager() => _instance;

  AppImageCacheManager._()
      : super(
          Config(
            key,
            stalePeriod: const Duration(days: 30),
            maxNrOfCacheObjects: 200,
            repo: JsonCacheInfoRepository(databaseName: key),
            fileService: HttpFileService(),
          ),
        );

  /// Clears the entire image disk cache
  static Future<void> clearImageCache() async {
    await _instance.emptyCache();
    await DefaultCacheManager().emptyCache();
    debugPrint('✅ Image disk cache cleared');
  }
}

class AppImageAsset extends StatelessWidget {
  final String? image;
  final double? height;
  final double? width;
  final Color? color;
  final BoxFit? fit;
  final bool isFile;

  // 'cache' param kept for backward compatibility — always caches network images now
  // ignore: unused_element
  final bool cache;

  const AppImageAsset({
    super.key,
    required this.image,
    this.fit,
    this.height,
    this.width,
    this.color,
    this.isFile = false,
    this.cache = false,
  });

  @override
  Widget build(BuildContext context) {
    final img = image ?? '';

    // ── Network image (http / https) ──────────────────────────────────────────
    if (img.startsWith('http://') || img.startsWith('https://')) {
      String resolvedUrl = img;
      if (Get.isRegistered<HomeController>()) {
        final hc = Get.find<HomeController>();
        final version = hc.photoVersion.value;
        resolvedUrl = img.contains('?') ? '$img&v=$version' : '$img?v=$version';
      }
      return CachedNetworkImage(
        imageUrl: resolvedUrl,
        cacheManager: AppImageCacheManager(),
        height: height,
        width: width,
        fit: fit ?? BoxFit.cover,
        alignment: const Alignment(0, -0.5),
        // Shimmer placeholder while loading
        placeholder: (context, url) => _ShimmerPlaceholder(
          height: height,
          width: width,
        ),
        // Friendly error fallback
        errorWidget: (context, url, error) => _ErrorPlaceholder(
          height: height,
          width: width,
          fit: fit,
          color: color,
          isFile: isFile,
        ),
      );
    }

    // ── File image ────────────────────────────────────────────────────────────
    if (isFile) {
      final imageWidget = Image.file(
        File(img),
        height: height,
        width: width,
        fit: fit,
      );
      return color != null
          ? ColorFiltered(
              colorFilter: ColorFilter.mode(color!, BlendMode.srcIn),
              child: imageWidget,
            )
          : imageWidget;
    }

    // ── Asset image (PNG / JPG) ───────────────────────────────────────────────
    if (img.isEmpty || !img.endsWith('.svg')) {
      final imageWidget = Image.asset(
        img,
        height: height,
        width: width,
        fit: fit,
      );
      return color != null
          ? ColorFiltered(
              colorFilter: ColorFilter.mode(color!, BlendMode.srcIn),
              child: imageWidget,
            )
          : imageWidget;
    }

    // ── SVG asset ─────────────────────────────────────────────────────────────
    return SvgPicture.asset(
      img,
      height: height,
      width: width,
      fit: fit ?? BoxFit.contain,
      colorFilter:
          color != null ? ColorFilter.mode(color!, BlendMode.srcIn) : null,
    );
  }
}

/// Shimmer placeholder shown while the network image is loading
class _ShimmerPlaceholder extends StatelessWidget {
  final double? height;
  final double? width;
  const _ShimmerPlaceholder({this.height, this.width});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      child: Container(
        height: height,
        width: width,
        color: Colors.white,
      ),
    );
  }
}

/// Error fallback: tries the default no-image asset
class _ErrorPlaceholder extends StatelessWidget {
  final double? height;
  final double? width;
  final BoxFit? fit;
  final Color? color;
  final bool isFile;

  const _ErrorPlaceholder({
    this.height,
    this.width,
    this.fit,
    this.color,
    this.isFile = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppImageAsset(
      image: ConstantString.noImgUrlPath,
      width: width,
      height: height,
      color: color,
      fit: fit,
      isFile: isFile,
    );
  }
}
