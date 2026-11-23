// GetX 4.7 masih memakai widget dari flutter/material.dart.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';

import '../models/note_model.dart';
import '../utils/app_theme.dart';
import '../utils/date_formatter.dart';

/// Kartu ringkasan catatan sesuai desain Figma (Catatanku.png).
class NoteCard extends StatelessWidget {
  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
  });

  final NoteModel note;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final previewText = note.content.replaceAll(RegExp(r'\s+'), ' ').trim();
    final charCount = note.content.trim().length;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail kertas mini yang merepresentasikan dokumen catatan.
              _PaperThumbnail(
                title: note.title,
                content: note.content,
              ),
              const SizedBox(width: 14),

              // Isi ringkasan catatan di sisi kanan.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            note.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.titleMedium,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.north_east_rounded,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      previewText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${DateFormatter.formatShortDate(note.createdAt)} · $charCount karakter',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pratinjau mini berbentuk lembar kertas krem khas Scanote.
class _PaperThumbnail extends StatelessWidget {
  const _PaperThumbnail({
    required this.title,
    required this.content,
  });

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 76,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.paperSurface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.paperInk,
              fontSize: 5.5,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Text(
              content,
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.paperInk,
                fontSize: 4.5,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
