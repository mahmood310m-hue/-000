class Env {
  static const url = String.fromEnvironment('SUPABASE_URL');
  static const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const countryCode = String.fromEnvironment('COUNTRY_CODE', defaultValue: '964');
  // 'phone' = مزود الهاتف في Supabase، 'email' = بريد داخلي مشتق من رقم الهاتف (بدون SMS)
  static const authMode = String.fromEnvironment('AUTH_MODE', defaultValue: 'phone');
  static bool get ok => url.isNotEmpty && anonKey.isNotEmpty;
}
