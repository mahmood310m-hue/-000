import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/common.dart';
import '../core/theme.dart';
import '../widgets/table_screen.dart';
import 'grades.dart';
import 'students.dart';

const _statusColors = {
  'present': AppColors.green,
  'absent': AppColors.danger,
  'late': Color(0xFFE0A100),
  'excused': Color(0xFF5B7DB1),
};

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});
  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  String? classId;
  String? date; // yyyy-MM-dd

  Widget _report(List<Map<String, dynamic>> rows) {
    final c = {for (final k in statusLabels.keys) k: 0};
    for (final r in rows) {
      c[r['status']] = (c[r['status']] ?? 0) + 1;
    }
    return SoftCard(
      color: AppColors.mintSoft,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('تقرير الحضور والغياب', style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 6, children: [
          for (final e in statusLabels.entries)
            Chip(
              backgroundColor: Colors.white,
              side: BorderSide(color: _statusColors[e.key]!),
              label: Text('${e.value}: ${ar(c[e.key])}',
                  style: TextStyle(color: _statusColors[e.key], fontWeight: FontWeight.w700)),
            ),
        ]),
      ]),
    );
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2020),
        lastDate: DateTime(2100));
    if (d != null) {
      setState(() => date =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = classId != null;
    final filters = <String, Object>{
      if (filtered) 'students.class_id': classId!,
      if (date != null) 'date': date!,
    };
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        child: Row(children: [
          if (Session.isStaff) ...[
            Expanded(child: ClassPicker(value: classId, onChanged: (v) => setState(() => classId = v))),
            const SizedBox(width: 8),
          ] else
            const Spacer(),
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_month_outlined, size: 18),
            label: Text(date == null ? 'كل التواريخ' : ar(date)),
          ),
          if (date != null)
            IconButton(onPressed: () => setState(() => date = null), icon: const Icon(Icons.close)),
        ]),
      ),
      Expanded(
        child: TableScreen(
          key: ValueKey('att-$classId-$date'),
          table: 'attendance',
          select:
              'id, student_id, date, status, note, ${filtered ? 'students!inner' : 'students'}(full_name, class_id, classes(name))',
          filters: filters,
          orderBy: 'date',
          ascending: false,
          canEdit: Session.canAttendance,
          upsertOn: 'student_id,date',
          addLabel: 'تسجيل حضور',
          emptyText: 'لا توجد سجلات حضور',
          header: _report,
          titleOf: (r) => (dig(r, ['students', 'full_name']) ?? '').toString(),
          subtitleOf: (r) =>
              '${dig(r, ['students', 'classes', 'name']) ?? ''} • ${ar(r['date'])}\n${statusLabels[r['status']] ?? ''}'
              '${(r['note'] ?? '').toString().isEmpty ? '' : ' — ${r['note']}'}',
          leading: (r, i) => CircleAvatar(
            backgroundColor: (_statusColors[r['status']] ?? AppColors.muted).withAlpha(40),
            child: Icon(
              r['status'] == 'present'
                  ? Icons.check_circle_outline
                  : r['status'] == 'absent'
                      ? Icons.cancel_outlined
                      : Icons.access_time,
              color: _statusColors[r['status']],
            ),
          ),
          fields: [
            FieldSpec('student_id', 'الطالب', FType.lookup,
                required: true, lookup: () => studentLookup(classId)),
            FieldSpec('date', 'التاريخ', FType.date,
                required: true,
                initial:
                    '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}'),
            FieldSpec('status', 'الحالة', FType.select,
                required: true,
                initial: 'present',
                options: [for (final e in statusLabels.entries) MapEntry(e.key, e.value)]),
            FieldSpec('note', 'ملاحظة', FType.text),
          ],
        ),
      ),
    ]);
  }
}
