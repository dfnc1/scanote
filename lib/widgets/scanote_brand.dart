// GetX 4.7 masih memakai widget dari flutter/material.dart.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';

import '../utils/app_theme.dart';

/// Header identitas visual Scanote (ikon pindai lime + wordmark) sesuai desain Figma.
class ScanoteBrand extends StatelessWidget {
  const ScanoteBrand({
    super.key,
    this.showTagline = false,
    this.compact = false,
  });

  final bool showTagline;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final iconBoxSize = compact ? 34.0 : 44.0;
    final iconSize = compact ? 20.0 : 24.0;
    final radius = compact ? 10.0 : 12.0;
    final titleSize = compact ? 20.0 : 26.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: iconBoxSize,
              height: iconBoxSize,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(radius),
              ),
              child: Icon(
                Icons.document_scanner_outlined,
                color: AppColors.onPrimary,
                size: iconSize,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'scanote',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: titleSize,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        if (showTagline) ...[
          const SizedBox(height: 8),
          Text(
            'Pindai cepat. Catat lebih rapi.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ],
    );
  }
}
