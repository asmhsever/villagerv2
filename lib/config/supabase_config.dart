import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://rehsssptxuhahcfoxubc.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJlaHNzc3B0eHVoYWhjZm94dWJjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDI1OTIwMzcsImV4cCI6MjA1ODE2ODAzN30.M1ueNssOTWHs6nQ3BQGWafIMPIs7kJfSmPDWIJ2VYBk';

  static SupabaseClient? _client;

  static SupabaseClient get client {
    _client ??= SupabaseClient(supabaseUrl, supabaseAnonKey);
    return _client!;
  }
}
