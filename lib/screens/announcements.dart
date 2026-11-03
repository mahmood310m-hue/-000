import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/common.dart';
import '../core/theme.dart';
import '../widgets/table_screen.dart';

List<MapEntry<String, String>> categoryOptions() =>
    [for (final e in categoryLabels.entries) MapEntry(e.key, e.value)];

class AnnouncementsScreen extends StatelessWidget {
  const AnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TableScreen(
      table: 'announcements',
      select: '*',
      orderBy: 'published_at',
      ascending: false,
      canEdit: Session.isAdmin,
      addLabel: 'إضافة إعلان',
      emptyText: 'لا توجد إعلانات منشورة',
      titleOf: (r) => (r['title'] ?? '').toString(),
      subtitleOf: (r) {
        final d = (r['published_at'] ?? '').toString();
        final date = d.length >= 10 ? d.substring(0, 10) : d;
        return '${categoryLabels[r['category']] ?? ''} • ${ar(date)}\n${r['body'] ?? ''}';
      },
      leading: (r, i) {
        final url = (r['image_url'] ?? '').toString();
        return ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: url.isNotEmpty
              ? Image.network(url, width: 58, height: 58, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image))
              : Container(
                  width: 58,
                  height: 58,
                  color: AppColors.mintSoft,
                  child: const Icon(Icons.campaign_rounded, color: AppColors.green)),
        );
      },
      fields: [
        FieldSpec('title', 'العنوان', FType.text, required: true),
        FieldSpec('body', 'النص', FType.multiline),
        FieldSpec('category', 'التصنيف', FType.select,
            required: true, options: categoryOptions(), initial: 'announcement'),
        FieldSpec('image_url', 'صورة الإعلان', FType.image),
      ],
    );
  }
}
