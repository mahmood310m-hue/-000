import 'package:flutter/material.dart';
import '../../core/api.dart';
import '../../core/common.dart';
import '../../core/theme.dart';
import 'admin_panel.dart';

class AdminTab extends StatelessWidget {
  const AdminTab({super.key});
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
        valueListenable: adminUnlocked,
        builder: (_, unlocked, __) => unlocked ? const AdminPanel() : const AdminGate(),
      );
}

/// بوابة الإدارة: تعيد التحقق من الحساب عبر Supabase Auth ثم تتأكد من صلاحية admin
/// من الخادم (دالة is_admin) — وليس بمجرد إخفاء الزر.
class AdminGate extends StatefulWidget {
  const AdminGate({super.key});
  @override
  State<AdminGate> createState() => _AdminGateState();
}

class _AdminGateState extends State<AdminGate> {
  late final TextEditingController _phone =
      TextEditingController(text: (Session.profile?['phone'] ?? '').toString());
  final _pass = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  Future<void> _enter() async {
    if (_phone.text.trim().isEmpty || _pass.text.isEmpty) {
      setState(() => _error = 'أدخل رقم الهاتف وكلمة مرور الإدارة');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await signInWithPhone(_phone.text, _pass.text);
      await Session.load();
      final ok = Session.isAdmin && (await sb.rpc('is_admin')) == true;
      if (ok) {
        adminUnlocked.value = true;
      } else if (mounted) {
        setState(() => _error = 'هذا الحساب لا يملك صلاحية الإدارة');
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'بيانات الدخول غير صحيحة');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _phone.dispose();
    _pass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: SoftCard(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.admin_panel_settings_rounded, size: 46, color: AppColors.green),
            const SizedBox(height: 8),
            const Text('الدخول إلى لوحة الإدارة',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                  labelText: 'رقم الهاتف', prefixIcon: Icon(Icons.phone_outlined)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pass,
              obscureText: _obscure,
              onSubmitted: (_) => _enter(),
              decoration: InputDecoration(
                labelText: 'كلمة مرور الإدارة',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: const TextStyle(color: AppColors.danger)),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _busy ? null : _enter,
                child: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('دخول'),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
