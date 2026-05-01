import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../services/image_cache_service.dart';

/// OptimizedNetworkImage - Widget for loading network images with proper error handling
class OptimizedNetworkImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Duration fadeInDuration;
  final String? cacheKey;

  const OptimizedNetworkImage({
    Key? key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.fadeInDuration = const Duration(milliseconds: 500),
    this.cacheKey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cacheService = ImageCacheService();

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        cacheKey: cacheKey ?? imageUrl,
        cacheManager: cacheService.cacheManager,
        fadeInDuration: fadeInDuration,
        placeholder: (context, url) =>
            placeholder ??
            Container(
              width: width,
              height: height,
              color: Colors.grey[300],
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        errorWidget: (context, url, error) =>
            errorWidget ??
            Container(
              width: width,
              height: height,
              color: Colors.grey[200],
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_not_supported,
                      color: Colors.grey[400], size: 32),
                  const SizedBox(height: 8),
                  Text(
                    'Failed to load',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
        httpHeaders: {
          'Accept': 'image/*',
          'Connection': 'keep-alive',
        },
      ),
    );
  }
}
