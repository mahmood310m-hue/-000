import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/common.dart';
import '../core/theme.dart';
import '../widgets/table_screen.dart';
import 'students.dart';

Future<List<MapEntry<String, String>>> subjectLookup() async {
  final r = await sb.from('subjects').select('id, name').order('name');
  return [for (final c in r) MapEntry(c['id'] as String, c['name'] as String)];
}

/// شريط اختيار الصف (للمعلمين والإدارة فقط)
class ClassPicker extends StatefulWidget {
  final String? value;
  final ValueChanged<String?> onChanged;
  const ClassPicker({super.key, required this.value, required this.onChanged});
  @override
  State<ClassPicker> createState() => _ClassPickerState();
}

class _ClassPickerState extends State<ClassPicker> {
  List<MapEntry<String, String>> items = [];
  @override
  void initState() {
    super.initState();
    classLookup().then((l) {
      if (mounted) setState(() => items = l);
    }).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String?>(
      value: items.any((e) => e.key == widget.value) ? widget.value : null,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'المرحلة والصف', isDense: true),
      items: [
        const DropdownMenuItem<String?>(value: null, child: Text('كل الصفوف')),
        for (final e in items) DropdownMenuItem<String?>(value: e.key, child: Text(e.value)),
      ],
      onChanged: widget.onChanged,
    );
  }
}

class GradesScreen extends StatefulWidget {
  const GradesScreen({super.key});
  @override
  State<GradesScreen> createState() => _GradesScreenState();
}

class _GradesScreenState extends State<GradesScreen> {
  String? classId;

  Widget _averages(List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) return const SizedBox.shrink();
    final sums = <String, List<double>>{};
    final names = <String, String>{};
    for (final r in rows) {
      final sid = r['student_id'].toString();
      final max = (r['max_score'] as num).toDouble();
      if (max <= 0) continue;
      sums.putIfAbsent(sid, () => []).add((r['score'] as num).toDouble() / max * 100);
      names[sid] = (dig(r, ['students', 'full_name']) ?? '').toString();
    }
    return SoftCard(
      color: AppColors.mintSoft,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('المعدل النهائي', style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        for (final e in sums.entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(children: [
              Expanded(child: Text(names[e.key] ?? '')),
              Text('${ar((e.value.reduce((a, b) => a + b) / e.value.length).toStringAsFixed(1))}٪',
                  style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.green)),
            ]),
          ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = classId != null;
    return Column(children: [
      if (Session.isStaff)
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: ClassPicker(value: classId, onChanged: (v) => setState(() => classId = v)),
        ),
      Expanded(
        child: TableScreen(
          key: ValueKey('grades-$classId'),
          table: 'grades',
          select:
              'id, student_id, subject_id, exam_name, term, score, max_score, ${filtered ? 'students!inner' : 'students'}(full_name, class_id), subjects(name)',
          filters: filtered ? {'students.class_id': classId!} : {},
          orderBy: 'created_at',
          ascending: false,
          canEdit: Session.canGrades,
          addLabel: 'إضافة درجة',
          emptyText: 'لا توجد درجات مسجلة',
          header: _averages,
          titleOf: (r) => '${dig(r, ['subjects', 'name']) ?? ''} — ${r['exam_name']}',
          subtitleOf: (r) =>
              '${dig(r, ['students', 'full_name']) ?? ''}\nالدرجة: ${ar(r['score'])} من ${ar(r['max_score'])}'
              '${(r['term'] ?? '').toString().isEmpty ? '' : ' • ${r['term']}'}',
          leading: (r, i) => const CircleAvatar(
              backgroundColor: AppColors.mintSoft,
              child: Icon(Icons.grading_rounded, color: AppColors.green)),
          fields: [
            FieldSpec('student_id', 'الطالب', FType.lookup,
                required: true, lookup: () => studentLookup(classId)),
            FieldSpec('subject_id', 'المادة', FType.lookup, required: true, lookup: subjectLookup),
            FieldSpec('exam_name', 'الامتحان (شهري/نصف السنة/…)', FType.text, required: true),
            FieldSpec('term', 'الفصل', FType.text),
            FieldSpec('score', 'الدرجة', FType.number, required: true),
            FieldSpec('max_score', 'الدرجة العظمى', FType.number, required: true, initial: 100),
          ],
        ),
      ),
    ]);
  }
}
