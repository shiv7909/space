import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// ImageCacheService - Centralized image loading with proper caching and memory management
class ImageCacheService {
  static final ImageCacheService _instance = ImageCacheService._internal();

  late CacheManager _cacheManager;

  ImageCacheService._internal() {
    _initializeCacheManager();
  }

  factory ImageCacheService() {
    return _instance;
  }

  void _initializeCacheManager() {
    _cacheManager = CacheManager(
      Config(
        'habitz_image_cache',
        stalePeriod: const Duration(days: 7),
        maxNrOfCacheObjects: 200,
      ),
    );
  }

  CacheManager get cacheManager => _cacheManager;

  /// Load network image with proper error handling and memory optimization
  ImageProvider getNetworkImageProvider(
    String imageUrl, {
    String? cacheKey,
  }) {
    return CachedNetworkImageProvider(
      imageUrl,
      cacheKey: cacheKey ?? imageUrl,
      cacheManager: _cacheManager,
      errorListener: (error) {
        debugPrint('Image load error for $imageUrl: $error');
      },
    );
  }

  /// Clear all cached images
  Future<void> clearAllCache() async {
    await _cacheManager.emptyCache();
  }

  /// Clear specific image from cache
  Future<void> clearImageCache(String imageUrl) async {
    await _cacheManager.removeFile(imageUrl);
  }
}
