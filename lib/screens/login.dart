import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/api.dart';
import '../core/theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phone = TextEditingController();
  final _pass = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  String? _error = Session.notice;

  @override
  void initState() {
    super.initState();
    Session.notice = null;
  }

  Future<void> _login() async {
    if (_phone.text.trim().isEmpty || _pass.text.isEmpty) {
      setState(() => _error = 'أدخل رقم الهاتف وكلمة المرور');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await signInWithPhone(_phone.text, _pass.text);
    } on AuthException catch (e) {
      final m = e.message.toLowerCase();
      setState(() => _error = m.contains('disabled') || m.contains('provider')
          ? 'تسجيل الدخول برقم الهاتف غير مفعّل في الخادم. راجع إعدادات Supabase.'
          : 'رقم الهاتف أو كلمة المرور غير صحيحة');
    } catch (_) {
      setState(() => _error = 'تعذر الاتصال بالخادم. تحقق من الإنترنت.');
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
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppColors.border),
                  boxShadow: const [
                    BoxShadow(
                        color: Color.fromRGBO(30, 90, 70, 0.10),
                        blurRadius: 24,
                        offset: Offset(0, 8)),
                  ],
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                          colors: [AppColors.mint, AppColors.green],
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft),
                    ),
                    child: const Icon(Icons.school_rounded, color: Colors.white, size: 44),
                  ),
                  const SizedBox(height: 14),
                  const Text('مدرسة كوثر الأهلية المختلطة',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  const Text('Kauthar Private Mixed School',
                      style: TextStyle(fontSize: 12, color: AppColors.muted)),
                  const SizedBox(height: 22),
                  TextField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.right,
                    decoration: const InputDecoration(
                        labelText: 'رقم الهاتف', prefixIcon: Icon(Icons.phone_outlined)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _pass,
                    obscureText: _obscure,
                    onSubmitted: (_) => _login(),
                    decoration: InputDecoration(
                      labelText: 'كلمة المرور',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        tooltip: _obscure ? 'إظهار' : 'إخفاء',
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDECEA),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(_error!,
                          style: const TextStyle(color: AppColors.danger, fontSize: 13)),
                    ),
                  ],
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _busy ? null : _login,
                      child: _busy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('تسجيل الدخول'),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
