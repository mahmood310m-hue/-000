import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/common.dart';
import '../core/theme.dart';

/// ساعة إلكترونية صغيرة تتحدّث كل ثانية. اضغط عليها للتبديل بين نظام ١٢ و٢٤ ساعة.
class SchoolClock extends StatefulWidget {
  const SchoolClock({super.key});
  @override
  State<SchoolClock> createState() => _SchoolClockState();
}

class _SchoolClockState extends State<SchoolClock> {
  Timer? _t;
  DateTime _now = DateTime.now();
  bool _h24 = false;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final time = _h24
        ? DateFormat('HH:mm:ss').format(_now)
        : DateFormat('hh:mm:ss a', 'ar').format(_now);
    final date = DateFormat('EEE d MMM y', 'ar').format(_now);
    return GestureDetector(
      onTap: () => setState(() => _h24 = !_h24),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.mintSoft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(ar(time),
                textDirection: TextDirection.ltr,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.green)),
            Text(ar(date),
                style: const TextStyle(fontSize: 9, color: AppColors.muted)),
          ],
        ),
      ),
    );
  }
}
