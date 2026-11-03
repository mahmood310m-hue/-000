import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme.dart';

/// يحوّل الأرقام اللاتينية إلى هندية-عربية (٠١٢٣٤٥٦٧٨٩) للعرض.
String ar(Object? v) {
  const l = '0123456789';
  const a = '٠١٢٣٤٥٦٧٨٩';
  final b = StringBuffer();
  for (final r in (v ?? '').toString().runes) {
    final c = String.fromCharCode(r);
    final i = l.indexOf(c);
    b.write(i >= 0 ? a[i] : c);
  }
  return b.toString();
}

/// يحوّل الأرقام الهندية-العربية إلى لاتينية قبل الإرسال إلى قاعدة البيانات.
String toLatin(String s) {
  const a = '٠١٢٣٤٥٦٧٨٩';
  const p = '۰۱۲۳۴۵۶۷۸۹';
  final b = StringBuffer();
  for (final r in s.runes) {
    final c = String.fromCharCode(r);
    var i = a.indexOf(c);
    if (i < 0) i = p.indexOf(c);
    b.write(i >= 0 ? '$i' : c);
  }
  return b.toString();
}

dynamic dig(Map<String, dynamic> r, List<String> path) {
  dynamic c = r;
  for (final k in path) {
    if (c is Map) {
      c = c[k];
    } else {
      return null;
    }
  }
  return c;
}

String errText(Object e) {
  if (e is PostgrestException) {
    switch (e.code) {
      case '23505':
        return 'السجل موجود مسبقاً (تكرار).';
      case '42501':
        return 'لا تملك صلاحية لتنفيذ هذا الإجراء.';
      case '23503':
        return 'لا يمكن تنفيذ العملية لارتباط السجل ببيانات أخرى.';
      case '23514':
        return 'قيمة غير صالحة (تحقق من الدرجة أو المعدل).';
    }
    return e.message;
  }
  if (e is StorageException) return 'تعذر رفع الملف: ${e.message}';
  return 'حدث خطأ غير متوقع. تحقق من الاتصال بالإنترنت.';
}

void toast(BuildContext context, String msg, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppColors.danger : AppColors.green,
      behavior: SnackBarBehavior.floating,
    ));
}

Future<bool> confirmDelete(BuildContext context, String what) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: const Text('تأكيد الحذف'),
      content: Text('هل أنت متأكد من حذف "$what"؟ لا يمكن التراجع عن هذا الإجراء.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
        TextButton(
          onPressed: () => Navigator.pop(c, true),
          child: const Text('حذف', style: TextStyle(color: AppColors.danger)),
        ),
      ],
    ),
  );
  return r == true;
}

class SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color? color;
  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(22);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: r,
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(color: Color.fromRGBO(30, 90, 70, 0.07), blurRadius: 14, offset: Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: r,
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

const roleLabels = {
  'super_admin': 'مدير أعلى',
  'admin': 'مدير',
  'teacher': 'معلم',
  'student': 'طالب',
  'parent': 'ولي أمر',
};

const statusLabels = {
  'present': 'حاضر',
  'absent': 'غائب',
  'late': 'متأخر',
  'excused': 'غياب بعذر',
};

const categoryLabels = {
  'announcement': 'إعلان',
  'news': 'خبر',
  'exam': 'موعد امتحان',
  'holiday': 'عطلة رسمية',
  'activity': 'نشاط مدرسي',
};

const stageOptions = ['ابتدائي', 'متوسط', 'إعدادي'];
