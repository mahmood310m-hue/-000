import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/common.dart';
import '../core/theme.dart';
import 'students.dart';

class HomeTab extends StatefulWidget {
  final void Function(String) onGo;
  const HomeTab({super.key, required this.onGo});
  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  Map<String, dynamic> stats = {};
  bool loading = true;
  String? error;

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
      await AppSettings.load();
      if (mounted) {
        setState(() {
          stats = Map<String, dynamic>.from(r as Map);
          loading = false;
          error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = errText(e);
          loading = false;
        });
      }
    }
  }

  Widget _stat(IconData icon, String label, String value, {VoidCallback? onTap}) {
    return SoftCard(
      onTap: onTap,
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(color: AppColors.mintSoft, shape: BoxShape.circle),
          child: Icon(icon, color: AppColors.green, size: 22),
        ),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        Text(label, style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final logo = AppSettings.get('logo_url');
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(padding: const EdgeInsets.all(14), children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: const LinearGradient(
              colors: [Color(0xFFD7F3E8), Color(0xFFEFFAF5)],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(AppSettings.get('welcome_title', 'مدرسة كوثر: بيت العلم والإبداع'),
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.green, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(AppSettings.get('welcome_subtitle', 'مرحباً بكم في مدرسة كوثر'),
                    style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(
                    AppSettings.get('welcome_body',
                        'بيئة تعليمية آمنة ومحفزة، نؤمن أن لكل طالب موهبة تستحق الرعاية.'),
                    style: const TextStyle(fontSize: 13, height: 1.7, color: AppColors.muted)),
              ]),
            ),
            const SizedBox(width: 12),
            ClipOval(
              child: logo.isNotEmpty
                  ? Image.network(logo, width: 64, height: 64, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.school_rounded, size: 52))
                  : Container(
                      width: 64,
                      height: 64,
                      color: Colors.white,
                      child: const Icon(Icons.school_rounded, color: AppColors.green, size: 38)),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        if (loading)
          const Padding(padding: EdgeInsets.all(30), child: Center(child: CircularProgressIndicator()))
        else if (error != null)
          SoftCard(child: Text(error!))
        else
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.35,
            crossAxisSpacing: 10,
            mainAxisSpacing: 0,
            children: [
              _stat(Icons.groups_rounded, 'الطلبة', ar(stats['students'] ?? 0),
                  onTap: Session.isStaff
                      ? () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => Scaffold(
                              appBar: AppBar(title: const Text('الطلبة')),
                              body: const StudentsScreen())))
                      : null),
              _stat(Icons.emoji_events_rounded, 'المتفوقون', ar(stats['honors'] ?? 0),
                  onTap: () => widget.onGo('honors')),
              _stat(Icons.calendar_month_rounded, 'العام الدراسي',
                  ar(AppSettings.get('school_year', '2026–2027'))),
              _stat(Icons.campaign_rounded, 'الإعلانات', ar(stats['announcements'] ?? 0),
                  onTap: () => widget.onGo('announcements')),
            ],
          ),
      ]),
    );
  }
}
