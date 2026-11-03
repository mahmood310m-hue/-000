import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/common.dart';
import '../core/theme.dart';
import '../widgets/table_screen.dart';
import 'students.dart';

class HonorsScreen extends StatelessWidget {
  const HonorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TableScreen(
      table: 'honor_list', // عرض آمن يعرض الاسم والصف والمعدل فقط
      writeTable: 'honors',
      select: '*',
      orderBy: 'average',
      ascending: false,
      canEdit: Session.isAdmin,
      addLabel: 'إضافة متفوق',
      emptyText: 'لا يوجد طلاب متفوقون مسجلون بعد',
      titleOf: (r) => (r['full_name'] ?? '').toString(),
      subtitleOf: (r) =>
          '${r['class_name'] ?? 'بدون صف'} — ${r['stage'] ?? ''}\nالمعدل: ${ar(r['average'])}'
          '${(r['note'] ?? '').toString().isEmpty ? '' : '\n${r['note']}'}',
      leading: (r, i) {
        final url = (r['photo_url'] ?? '').toString();
        return Stack(clipBehavior: Clip.none, children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.mintSoft,
            backgroundImage: url.isNotEmpty ? NetworkImage(url) : null,
            child: url.isEmpty ? const Icon(Icons.person, color: AppColors.green) : null,
          ),
          Positioned(
            bottom: -4,
            right: -4,
            child: CircleAvatar(
              radius: 11,
              backgroundColor: i < 3 ? const Color(0xFFF4C542) : AppColors.green,
              child: Text(ar(i + 1),
                  style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w800)),
            ),
          ),
        ]);
      },
      fields: [
        FieldSpec('student_id', 'الطالب', FType.lookup, required: true, lookup: () => studentLookup()),
        FieldSpec('average', 'المعدل (من ١٠٠)', FType.number, required: true),
        FieldSpec('note', 'ملاحظة', FType.multiline),
        FieldSpec('photo_url', 'صورة الطالب', FType.image),
      ],
    );
  }
}
