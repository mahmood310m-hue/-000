import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'common.dart';
import 'env.dart';

SupabaseClient get sb => Supabase.instance.client;

/// يُزاد عند أي تعديل ليحدّث الشاشات المعتمدة على البيانات (الإحصائيات، الشريط…)
final ValueNotifier<int> dataVersion = ValueNotifier<int>(0);
void bump() => dataVersion.value++;

/// هل فُتحت لوحة الإدارة بعد إعادة التحقق؟
final ValueNotifier<bool> adminUnlocked = ValueNotifier<bool>(false);

String normalizePhone(String raw) {
  var p = toLatin(raw).replaceAll(RegExp(r'[\s\-()]'), '');
  if (p.startsWith('+')) return p;
  if (p.startsWith('00')) return '+${p.substring(2)}';
  if (p.startsWith('0')) return '+${Env.countryCode}${p.substring(1)}';
  return '+$p';
}

String _pseudoEmail(String phone) =>
    '${phone.replaceAll('+', '')}@phone.kauthar.school';

/// تسجيل دخول حقيقي عبر Supabase Auth برقم الهاتف وكلمة المرور.
Future<void> signInWithPhone(String rawPhone, String password) async {
  final phone = normalizePhone(rawPhone);
  if (Env.authMode == 'email') {
    await sb.auth.signInWithPassword(email: _pseudoEmail(phone), password: password);
  } else {
    await sb.auth.signInWithPassword(phone: phone, password: password);
  }
}

class Session {
  static Map<String, dynamic>? profile;
  static bool canGrades = false;
  static bool canAttendance = false;
  static String? notice;

  static String get role => (profile?['role'] ?? '') as String;
  static bool get isSuper => role == 'super_admin';
  static bool get isAdmin => role == 'admin' || role == 'super_admin';
  static bool get isStaff => isAdmin || role == 'teacher';
  static String get name => (profile?['full_name'] ?? '') as String;

  static Future<void> load() async {
    final u = sb.auth.currentUser;
    if (u == null) {
      profile = null;
      return;
    }
    final p = await sb.from('profiles').select().eq('id', u.id).maybeSingle();
    if (p == null) {
      notice = 'لا يوجد ملف شخصي لهذا الحساب. تواصل مع إدارة المدرسة.';
      profile = null;
      await sb.auth.signOut();
      return;
    }
    if (p['active'] == false) {
      notice = 'هذا الحساب موقوف. تواصل مع إدارة المدرسة.';
      profile = null;
      await sb.auth.signOut();
      return;
    }
    profile = p;
    canGrades = canAttendance = isAdmin;
    if (role == 'teacher') {
      final pr = await sb.from('permissions').select().eq('user_id', u.id).maybeSingle();
      canGrades = pr?['can_manage_grades'] == true;
      canAttendance = pr?['can_manage_attendance'] == true;
    }
  }
}

class AppSettings {
  static final ValueNotifier<Map<String, String>> values = ValueNotifier({});

  static Future<void> load() async {
    final r = await sb.from('school_settings').select();
    values.value = {
      for (final e in r) e['key'] as String: ((e['value'] ?? '') as String),
    };
  }

  static String get(String k, [String d = '']) {
    final v = values.value[k];
    return (v == null || v.isEmpty) ? d : v;
  }

  static Set<String> get hidden {
    try {
      final l = jsonDecode(get('hidden_sections', '[]')) as List;
      return l.map((e) => e.toString()).toSet();
    } catch (_) {
      return {};
    }
  }
}

Future<String?> pickAndUploadImage() async {
  final x = await ImagePicker().pickImage(
      source: ImageSource.gallery, maxWidth: 1280, imageQuality: 80);
  if (x == null) return null;
  final bytes = await x.readAsBytes();
  final path = 'uploads/${DateTime.now().millisecondsSinceEpoch}.jpg';
  await sb.storage.from('media').uploadBinary(path, bytes,
      fileOptions: const FileOptions(contentType: 'image/jpeg'));
  return sb.storage.from('media').getPublicUrl(path);
}
