import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../services/api_config.dart';

class CachedImageWidget extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const CachedImageWidget({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Handle empty or null URLs
    if (imageUrl.isEmpty) {
      return _buildPlaceholder(context);
    }

    String finalUrl = imageUrl;

    // Handle relative URLs (e.g. /uploads/image.png)
    if (finalUrl.startsWith('/')) {
      finalUrl = '${ApiConfig.baseUrl}$finalUrl';
    } else if (finalUrl.startsWith('http')) {
      // If it is an external URL, proxy it through our local server
      // This bypasses Emulator network restrictions for some domains
      // But skip if it's already pointing to our server (localhost or 10.0.2.2)
      if (!finalUrl.contains('localhost') && !finalUrl.contains('10.0.2.2')) {
        final encodedUrl = Uri.encodeComponent(finalUrl);
        finalUrl = '${ApiConfig.baseUrl}/api/proxy/image?url=$encodedUrl';
      }
    }

    // Fix localhost for Android Emulator (fallback if we don't proxy localhost)
    if (finalUrl.contains('localhost')) {
      finalUrl = finalUrl.replaceFirst('localhost', '10.0.2.2');
    }

    // Debug log
    print('Loading image: $finalUrl');

    Widget image = CachedNetworkImage(
      imageUrl: finalUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => Container(
        width: width,
        height: height,
        color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[300],
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      errorWidget: (context, url, error) {
        print('Error loading image $url: $error');
        return _buildPlaceholder(context);
      },
    );

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: image);
    }

    return image;
  }

  Widget _buildPlaceholder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget placeholder = Container(
      width: width,
      height: height,
      color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[300],
      child: Icon(
        Icons.movie_creation_outlined,
        color: isDark ? Colors.grey[600] : Colors.grey[400],
        size: (width != null && width! < 60) ? 20 : 30,
      ),
    );

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: placeholder);
    }

    return placeholder;
  }
}
