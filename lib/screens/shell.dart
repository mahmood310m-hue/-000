import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/common.dart';
import '../core/theme.dart';
import '../widgets/clock.dart';
import '../widgets/ticker.dart';
import 'admin/admin_tab.dart';
import 'announcements.dart';
import 'attendance.dart';
import 'grades.dart';
import 'home_tab.dart';
import 'honors.dart';

class _TabDef {
  final String id, label;
  final IconData icon;
  final Widget Function() build;
  _TabDef(this.id, this.label, this.icon, this.build);
}

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  late final Future<void> _boot = _init();
  String _current = 'home';

  Future<void> _init() async {
    await Session.load();
    await AppSettings.load();
  }

  List<_TabDef> _tabs() {
    final hidden = Session.isAdmin ? <String>{} : AppSettings.hidden;
    final all = <_TabDef>[
      _TabDef('home', 'الرئيسية', Icons.home_rounded, () => HomeTab(onGo: _go)),
      _TabDef('honors', 'المتفوقون', Icons.emoji_events_rounded, () => const HonorsScreen()),
      _TabDef('grades', 'الدرجات', Icons.grading_rounded, () => const GradesScreen()),
      _TabDef('attendance', 'الحضور', Icons.fact_check_rounded, () => const AttendanceScreen()),
      _TabDef('announcements', 'الإعلانات', Icons.campaign_rounded, () => const AnnouncementsScreen()),
      _TabDef('admin', 'الإدارة', Icons.admin_panel_settings_rounded, () => const AdminTab()),
    ];
    return all.where((t) => !hidden.contains(t.id)).toList();
  }

  void _go(String id) => setState(() => _current = id);

  Future<void> _logout() async {
    adminUnlocked.value = false;
    await sb.auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _boot,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snap.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(errText(snap.error!), textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton(onPressed: _logout, child: const Text('تسجيل الخروج')),
                ]),
              ),
            ),
          );
        }
        if (Session.profile == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return ValueListenableBuilder<Map<String, String>>(
          valueListenable: AppSettings.values,
          builder: (context, _, __) {
            final tabs = _tabs();
            var idx = tabs.indexWhere((t) => t.id == _current);
            if (idx < 0) idx = 0;
            final tab = tabs[idx];
            return Scaffold(
              appBar: AppBar(
                title: Text(AppSettings.get('school_name', 'مدرسة كوثر الأهلية المختلطة')),
                // في الواجهة RTL تظهر actions في الجهة اليسرى العليا
                actions: [
                  const SchoolClock(),
                  IconButton(
                    tooltip: 'الإدارة',
                    onPressed: () => _go('admin'),
                    icon: const Icon(Icons.admin_panel_settings_outlined, color: AppColors.green),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'الحساب',
                    icon: const Icon(Icons.account_circle_outlined, color: AppColors.green),
                    onSelected: (v) {
                      if (v == 'logout') _logout();
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        enabled: false,
                        child: Text(
                            '${Session.name.isEmpty ? 'مستخدم' : Session.name} — ${roleLabels[Session.role] ?? ''}'),
                      ),
                      const PopupMenuItem(value: 'logout', child: Text('تسجيل الخروج')),
                    ],
                  ),
                ],
              ),
              body: Column(children: [
                const NewsTicker(),
                if (tab.id != 'home' && tab.id != 'admin')
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(tab.label,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    ),
                  ),
                Expanded(child: KeyedSubtree(key: ValueKey(tab.id), child: tab.build())),
              ]),
              bottomNavigationBar: NavigationBar(
                selectedIndex: idx,
                onDestinationSelected: (i) => _go(tabs[i].id),
                destinations: [
                  for (final t in tabs) NavigationDestination(icon: Icon(t.icon), label: t.label),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
