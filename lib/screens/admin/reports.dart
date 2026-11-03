import 'package:flutter/material.dart';
import '../../core/api.dart';
import '../../core/common.dart';
import '../../core/theme.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  Map<String, dynamic>? s;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await sb.rpc('get_stats');
      if (mounted) setState(() => s = Map<String, dynamic>.from(r as Map));
    } catch (e) {
      if (mounted) setState(() => error = errText(e));
    }
  }

  Widget _row(String k, Object? v) => SoftCard(
        child: Row(children: [
          Expanded(child: Text(k)),
          Text(ar(v ?? '-'),
              style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.green, fontSize: 17)),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    if (error != null) return Center(child: Text(error!));
    if (s == null) return const Center(child: CircularProgressIndicator());
    final present = (s!['present'] ?? 0) as num;
    final absent = (s!['absent'] ?? 0) as num;
    final lateCount = (s!['late'] ?? 0) as num;
    final excused = (s!['excused'] ?? 0) as num;
    final total = present + absent + lateCount + excused;
    final rate = total == 0 ? '-' : '${((present + lateCount) / total * 100).toStringAsFixed(1)}٪';
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(padding: const EdgeInsets.all(14), children: [
        _row('عدد الطلبة', s!['students']),
        _row('عدد المتفوقين', s!['honors']),
        _row('عدد الإعلانات', s!['announcements']),
        _row('عدد الحسابات', s!['users']),
        _row('عدد الدرجات المسجلة', s!['grades']),
        const SizedBox(height: 8),
        const Text('ملخص الحضور (كل السجلات)', style: TextStyle(fontWeight: FontWeight.w800)),
        _row('حاضر', present),
        _row('غائب', absent),
        _row('متأخر', lateCount),
        _row('غياب بعذر', excused),
        _row('نسبة الحضور (حاضر + متأخر)', rate),
      ]),
    );
  }
}
