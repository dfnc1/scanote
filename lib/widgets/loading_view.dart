// GetX 4.7 masih memakai widget dari flutter/material.dart.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';

import '../utils/app_theme.dart';

/// Tampilan indikator loading konsisten dengan keterangan konteks aksi.
class LoadingView extends StatelessWidget {
  const LoadingView({
    super.key,
    this.message = 'Memuat data...',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
