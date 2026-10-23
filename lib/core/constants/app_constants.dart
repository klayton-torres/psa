class AppConstants {
  static const String appName = 'Peladeiros S/A';
  static const String appTagline = 'Garanta o quórum da sua pelada!';

  static const String _defaultSupabaseUrl =
      'https://jrkvwfhgpkmqdhszsktv.supabase.co';
  static const String _defaultSupabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Impya3Z3ZmhncGttcWRoc3pza3R2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODUzNzY1MjksImV4cCI6MjEwMDk1MjUyOX0.O7xuuYt0yxm4xfh9PlK9IkMoTZxuUqWPPbkerjmv2gI';

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: _defaultSupabaseUrl,
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: _defaultSupabaseAnonKey,
  );

  static bool get hasSupabaseConfigured =>
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty &&
      !supabaseUrl.contains('your-project') &&
      !supabaseUrl.contains('demo.supabase.co');

  static const List<String> estadosBrasil = [
    'AC',
    'AL',
    'AP',
    'AM',
    'BA',
    'CE',
    'DF',
    'ES',
    'GO',
    'MA',
    'MT',
    'MS',
    'MG',
    'PA',
    'PB',
    'PR',
    'PE',
    'PI',
    'RJ',
    'RN',
    'RS',
    'RO',
    'RR',
    'SC',
    'SP',
    'SE',
    'TO',
  ];
}
