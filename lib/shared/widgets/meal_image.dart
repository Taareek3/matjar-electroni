import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class MealImage extends StatelessWidget {
  const MealImage({
    super.key,
    required this.url,
    this.icon = Icons.restaurant_rounded,
    this.width,
    this.height,
    this.borderRadius,
  });

  final String url;
  final IconData icon;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: borderRadius,
      ),
      child: Image.network(
        url,
        width: width,
        height: height,
        fit: BoxFit.cover,
        loadingBuilder: (
          BuildContext context,
          Widget child,
          ImageChunkEvent? progress,
        ) {
          if (progress == null) {
            return child;
          }
          return Center(
            child: Icon(icon, size: 40, color: Colors.white24),
          );
        },
        errorBuilder: (
          BuildContext context,
          Object error,
          StackTrace? stackTrace,
        ) {
          return Center(
            child: Icon(icon, size: 40, color: Colors.white70),
          );
        },
      ),
    );
  }
}
