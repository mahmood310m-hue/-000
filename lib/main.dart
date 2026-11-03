import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/api.dart';
import 'core/env.dart';
import 'core/theme.dart';
import 'screens/login.dart';
import 'screens/shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ar');
  if (Env.ok) {
    await Supabase.initialize(url: Env.url, anonKey: Env.anonKey);
  }
  runApp(const KautharApp());
}

class KautharApp extends StatelessWidget {
  const KautharApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'مدرسة كوثر الأهلية المختلطة',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Env.ok ? const AuthGate() : const ConfigMissing(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: sb.auth.onAuthStateChange,
      builder: (context, _) {
        final s = sb.auth.currentSession;
        if (s == null) return const LoginScreen();
        return Shell(key: ValueKey(s.user.id));
      },
    );
  }
}

class ConfigMissing extends StatelessWidget {
  const ConfigMissing({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'لم تُضبط إعدادات الاتصال (SUPABASE_URL / SUPABASE_ANON_KEY).\n'
              'أضفهما كـ GitHub Secrets ثم أعد بناء التطبيق.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
}
