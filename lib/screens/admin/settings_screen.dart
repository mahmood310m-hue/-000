import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/api.dart';
import '../../core/common.dart';
import '../../core/theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _name = TextEditingController(text: AppSettings.get('school_name', 'مدرسة كوثر الأهلية المختلطة'));
  final _year = TextEditingController(text: AppSettings.get('school_year', '2026–2027'));
  final _wTitle = TextEditingController(text: AppSettings.get('welcome_title', 'مدرسة كوثر: بيت العلم والإبداع'));
  final _wSub = TextEditingController(text: AppSettings.get('welcome_subtitle', 'مرحباً بكم في مدرسة كوثر'));
  final _wBody = TextEditingController(
      text: AppSettings.get('welcome_body', 'بيئة تعليمية آمنة ومحفزة، نؤمن أن لكل طالب موهبة تستحق الرعاية.'));
  String _logo = AppSettings.get('logo_url');
  late Set<String> _hidden = AppSettings.hidden;
  bool _saving = false;
  bool _uploading = false;

  static const _sections = {
    'honors': 'المتفوقون',
    'grades': 'الدرجات',
    'attendance': 'الحضور',
    'announcements': 'الإعلانات',
  };

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await sb.from('school_settings').upsert([
        {'key': 'school_name', 'value': _name.text.trim()},
        {'key': 'school_year', 'value': _year.text.trim()},
        {'key': 'welcome_title', 'value': _wTitle.text.trim()},
        {'key': 'welcome_subtitle', 'value': _wSub.text.trim()},
        {'key': 'welcome_body', 'value': _wBody.text.trim()},
        {'key': 'logo_url', 'value': _logo},
        {'key': 'hidden_sections', 'value': jsonEncode(_hidden.toList())},
      ], onConflict: 'key');
      await AppSettings.load();
      bump();
      if (mounted) toast(context, 'تم حفظ الإعدادات');
    } catch (e) {
      if (mounted) toast(context, errText(e), error: true);
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  void dispose() {
    for (final c in [_name, _year, _wTitle, _wSub, _wBody]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(14), children: [
      SoftCard(
        child: Column(children: [
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'اسم المدرسة')),
          const SizedBox(height: 12),
          TextField(controller: _year, decoration: const InputDecoration(labelText: 'العام الدراسي')),
          const SizedBox(height: 12),
          Row(children: [
            if (_logo.isNotEmpty)
              ClipOval(child: Image.network(_logo, width: 52, height: 52, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image))),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _uploading
                    ? null
                    : () async {
                        setState(() => _uploading = true);
                        try {
                          final u = await pickAndUploadImage();
                          if (u != null) _logo = u;
                        } catch (e) {
                          if (mounted) toast(context, errText(e), error: true);
                        }
                        if (mounted) setState(() => _uploading = false);
                      },
                icon: const Icon(Icons.image_outlined),
                label: const Text('تغيير شعار المدرسة'),
              ),
            ),
          ]),
        ]),
      ),
      SoftCard(
        child: Column(children: [
          TextField(controller: _wTitle, decoration: const InputDecoration(labelText: 'عنوان البطاقة الترحيبية')),
          const SizedBox(height: 12),
          TextField(controller: _wSub, decoration: const InputDecoration(labelText: 'عبارة الترحيب')),
          const SizedBox(height: 12),
          TextField(controller: _wBody, maxLines: 3, decoration: const InputDecoration(labelText: 'النص التعريفي')),
        ]),
      ),
      SoftCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('إظهار الأقسام لغير الإدارة', style: TextStyle(fontWeight: FontWeight.w800)),
          for (final e in _sections.entries)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(e.value),
              value: !_hidden.contains(e.key),
              onChanged: (v) => setState(() => v ? _hidden.remove(e.key) : _hidden.add(e.key)),
            ),
        ]),
      ),
      const SizedBox(height: 8),
      FilledButton(
        onPressed: _saving ? null : _save,
        child: _saving
            ? const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Text('حفظ الإعدادات'),
      ),
      const SizedBox(height: 8),
      const Text('عند تغيير العام الدراسي يظهر في بطاقة الصفحة الرئيسية فوراً.',
          style: TextStyle(fontSize: 12, color: AppColors.muted)),
    ]);
  }
}
