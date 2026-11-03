import 'package:flutter/material.dart';
import '../../core/api.dart';
import '../../core/common.dart';
import '../../core/theme.dart';
import '../../widgets/table_screen.dart';
import '../announcements.dart';
import '../attendance.dart';
import '../grades.dart';
import '../honors.dart';
import '../students.dart';
import 'reports.dart';
import 'settings_screen.dart';

class _Item {
  final String label;
  final IconData icon;
  final Widget Function() build;
  const _Item(this.label, this.icon, this.build);
}

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});
  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  Map<String, dynamic> stats = {};

  @override
  void initState() {
    super.initState();
    _load();
    dataVersion.addListener(_load);
  }

  @override
  void dispose() {
    dataVersion.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final r = await sb.rpc('get_stats');
      if (mounted) setState(() => stats = Map<String, dynamic>.from(r as Map));
    } catch (_) {}
  }

  List<_Item> get _items => [
        _Item('الطلبة', Icons.groups_rounded, () => const StudentsScreen()),
        _Item('المتفوقون', Icons.emoji_events_rounded, () => const HonorsScreen()),
        _Item('الدرجات', Icons.grading_rounded, () => const GradesScreen()),
        _Item('الحضور والغياب', Icons.fact_check_rounded, () => const AttendanceScreen()),
        _Item('الإعلانات', Icons.campaign_rounded, () => const AnnouncementsScreen()),
        _Item('الشريط الإخباري', Icons.newspaper_rounded, () => const _NewsAdmin()),
        _Item('الصفوف والمراحل', Icons.class_rounded, () => const _ClassesAdmin()),
        _Item('المواد الدراسية', Icons.menu_book_rounded, () => const _SubjectsAdmin()),
        _Item('حسابات المستخدمين', Icons.manage_accounts_rounded, () => const _UsersAdmin()),
        _Item('صلاحيات المعلمين', Icons.key_rounded, () => const _PermissionsAdmin()),
        _Item('ربط أولياء الأمور', Icons.family_restroom_rounded, () => const _ParentLinksAdmin()),
        _Item('إعدادات التطبيق', Icons.settings_rounded, () => const SettingsScreen()),
        _Item('الإحصائيات والتقارير', Icons.bar_chart_rounded, () => const ReportsScreen()),
      ];

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(14), children: [
      Row(children: [
        const Expanded(
          child: Text('لوحة الإدارة',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        ),
        TextButton.icon(
          onPressed: () => adminUnlocked.value = false,
          icon: const Icon(Icons.lock_outline, size: 18),
          label: const Text('قفل اللوحة'),
        ),
      ]),
      const SizedBox(height: 6),
      Row(children: [
        for (final e in [
          ['الطلبة', stats['students']],
          ['المتفوقون', stats['honors']],
          ['الإعلانات', stats['announcements']],
          ['المستخدمون', stats['users']],
        ])
          Expanded(
            child: SoftCard(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              child: Column(children: [
                Text(ar(e[1] ?? '-'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.green)),
                Text(e[0] as String, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
              ]),
            ),
          ),
      ]),
      const SizedBox(height: 6),
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.9,
        crossAxisSpacing: 10,
        children: [
          for (final it in _items)
            SoftCard(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(title: Text(it.label)),
                    body: it.build(),
                  ),
                ),
              ),
              child: Row(children: [
                Icon(it.icon, color: AppColors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(it.label,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                ),
              ]),
            ),
        ],
      ),
    ]);
  }
}

class _NewsAdmin extends StatelessWidget {
  const _NewsAdmin();
  @override
  Widget build(BuildContext context) => TableScreen(
        table: 'news',
        select: '*',
        orderBy: 'sort',
        canEdit: true,
        addLabel: 'إضافة خبر',
        emptyText: 'لا توجد أخبار في الشريط',
        titleOf: (r) => (r['text'] ?? '').toString(),
        subtitleOf: (r) => r['active'] == true ? 'ظاهر في الشريط' : 'مخفي',
        fields: [
          FieldSpec('text', 'نص الخبر', FType.multiline, required: true),
          FieldSpec('sort', 'الترتيب', FType.number, initial: 0),
          FieldSpec('active', 'ظاهر في الشريط', FType.boolean, initial: true),
        ],
      );
}

class _ClassesAdmin extends StatelessWidget {
  const _ClassesAdmin();
  @override
  Widget build(BuildContext context) => TableScreen(
        table: 'classes',
        select: '*',
        orderBy: 'sort',
        canEdit: true,
        addLabel: 'إضافة صف',
        emptyText: 'أضف الصفوف أولاً لتتمكن من تسجيل الطلبة',
        titleOf: (r) => (r['name'] ?? '').toString(),
        subtitleOf: (r) => 'المرحلة: ${r['stage']}',
        fields: [
          FieldSpec('name', 'اسم الصف (مثال: الأول – شعبة أ)', FType.text, required: true),
          FieldSpec('stage', 'المرحلة', FType.select,
              required: true, options: [for (final s in stageOptions) MapEntry(s, s)]),
          FieldSpec('sort', 'الترتيب', FType.number, initial: 0),
        ],
      );
}

class _SubjectsAdmin extends StatelessWidget {
  const _SubjectsAdmin();
  @override
  Widget build(BuildContext context) => TableScreen(
        table: 'subjects',
        select: '*',
        orderBy: 'name',
        canEdit: true,
        addLabel: 'إضافة مادة',
        emptyText: 'أضف المواد الدراسية لتتمكن من إدخال الدرجات',
        titleOf: (r) => (r['name'] ?? '').toString(),
        subtitleOf: (r) => '',
        fields: [FieldSpec('name', 'اسم المادة', FType.text, required: true)],
      );
}

class _UsersAdmin extends StatelessWidget {
  const _UsersAdmin();
  @override
  Widget build(BuildContext context) => TableScreen(
        table: 'profiles',
        select: 'id, full_name, phone, role, active',
        orderBy: 'full_name',
        canEdit: true,
        canAdd: false, // إنشاء الحسابات من لوحة Supabase (انظر README)
        canDelete: false,
        emptyText: 'لا توجد حسابات',
        titleOf: (r) => (r['full_name'] ?? '').toString().isEmpty
            ? 'بدون اسم'
            : r['full_name'].toString(),
        subtitleOf: (r) =>
            '${roleLabels[r['role']] ?? r['role']} • ${ar(r['phone'] ?? '-')} • ${r['active'] == true ? 'نشط' : 'موقوف'}',
        fields: [
          FieldSpec('full_name', 'الاسم', FType.text, required: true),
          // الخادم يرفض تغيير الدور لغير المدير الأعلى (trigger + RLS)
          if (Session.isSuper)
            FieldSpec('role', 'الدور', FType.select,
                required: true,
                options: [for (final e in roleLabels.entries) MapEntry(e.key, e.value)]),
          FieldSpec('active', 'الحساب نشط', FType.boolean),
        ],
      );
}

class _PermissionsAdmin extends StatelessWidget {
  const _PermissionsAdmin();
  @override
  Widget build(BuildContext context) => TableScreen(
        table: 'permissions',
        select: 'id, user_id, can_manage_grades, can_manage_attendance, profiles:user_id(full_name, phone)',
        orderBy: 'id',
        canEdit: true,
        upsertOn: 'user_id',
        addLabel: 'منح صلاحيات لمعلم',
        emptyText: 'لم تُمنح صلاحيات لأي معلم بعد',
        titleOf: (r) => (dig(r, ['profiles', 'full_name']) ?? 'معلم').toString(),
        subtitleOf: (r) =>
            'الدرجات: ${r['can_manage_grades'] == true ? 'نعم' : 'لا'} • الحضور: ${r['can_manage_attendance'] == true ? 'نعم' : 'لا'}',
        fields: [
          FieldSpec('user_id', 'المعلم', FType.lookup,
              required: true, lookup: () => profilesLookup('teacher')),
          FieldSpec('can_manage_grades', 'إدارة الدرجات', FType.boolean),
          FieldSpec('can_manage_attendance', 'إدارة الحضور', FType.boolean),
        ],
      );
}

class _ParentLinksAdmin extends StatelessWidget {
  const _ParentLinksAdmin();
  @override
  Widget build(BuildContext context) => TableScreen(
        table: 'parent_students',
        select: 'id, parent_id, student_id, profiles:parent_id(full_name, phone), students(full_name)',
        orderBy: 'id',
        canEdit: true,
        addLabel: 'ربط ولي أمر بطالب',
        emptyText: 'لا توجد روابط بين أولياء الأمور والطلبة',
        titleOf: (r) => (dig(r, ['profiles', 'full_name']) ?? 'ولي أمر').toString(),
        subtitleOf: (r) => 'الابن/الابنة: ${dig(r, ['students', 'full_name']) ?? ''}',
        fields: [
          FieldSpec('parent_id', 'ولي الأمر', FType.lookup,
              required: true, lookup: () => profilesLookup('parent')),
          FieldSpec('student_id', 'الطالب', FType.lookup,
              required: true, lookup: () => studentLookup()),
        ],
      );
}
