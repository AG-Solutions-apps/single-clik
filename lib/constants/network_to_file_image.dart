import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class NetworkToFileImage {
  NetworkToFileImage._();

  static NetworkToFileImage networkToFileImage = NetworkToFileImage._();

  Future<String> getNetworkToFileImage({required String url}) async {
    try {
      return (await DefaultCacheManager().getSingleFile(url)).path;
    } catch (error) {
      return url;
    }
  }
}
