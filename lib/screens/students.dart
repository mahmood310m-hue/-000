import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/common.dart';
import '../widgets/table_screen.dart';

Future<List<MapEntry<String, String>>> classLookup() async {
  final r = await sb.from('classes').select('id, name, stage').order('sort').order('name');
  return [for (final c in r) MapEntry(c['id'] as String, '${c['name']} — ${c['stage']}')];
}

Future<List<MapEntry<String, String>>> studentLookup([String? classId]) async {
  var q = sb.from('students').select('id, full_name');
  if (classId != null) q = q.eq('class_id', classId);
  final r = await q.order('full_name');
  return [for (final c in r) MapEntry(c['id'] as String, c['full_name'] as String)];
}

Future<List<MapEntry<String, String>>> profilesLookup(String role) async {
  final r = await sb.from('profiles').select('id, full_name, phone').eq('role', role).order('full_name');
  return [
    for (final c in r)
      MapEntry(c['id'] as String,
          '${(c['full_name'] ?? '').toString().isEmpty ? 'بدون اسم' : c['full_name']} (${c['phone'] ?? ''})')
  ];
}

class StudentsScreen extends StatelessWidget {
  const StudentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TableScreen(
      table: 'students',
      select: 'id, full_name, phone, class_id, guardian_name, guardian_phone, user_id, classes(name, stage)',
      orderBy: 'full_name',
      canEdit: Session.isAdmin,
      addLabel: 'إضافة طالب',
      emptyText: 'لم يُسجَّل أي طالب بعد',
      titleOf: (r) => (r['full_name'] ?? '').toString(),
      subtitleOf: (r) {
        final c = r['classes'];
        final cls = c is Map ? '${c['name']} — ${c['stage']}' : 'بدون صف';
        return '$cls\nالهاتف: ${ar(r['phone'] ?? '-')}\nولي الأمر: ${r['guardian_name'] ?? '-'} (${ar(r['guardian_phone'] ?? '-')})';
      },
      leading: (r, i) => const CircleAvatar(child: Icon(Icons.person_outline)),
      fields: [
        FieldSpec('full_name', 'الاسم الكامل', FType.text, required: true),
        FieldSpec('phone', 'رقم هاتف الطالب', FType.text),
        FieldSpec('class_id', 'الصف والمرحلة', FType.lookup, lookup: classLookup),
        FieldSpec('guardian_name', 'اسم ولي الأمر', FType.text),
        FieldSpec('guardian_phone', 'هاتف ولي الأمر', FType.text),
        FieldSpec('user_id', 'حساب الطالب (اختياري)', FType.lookup,
            lookup: () => profilesLookup('student')),
      ],
    );
  }
}
