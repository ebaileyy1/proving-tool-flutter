/// Central Supabase project configuration, shared by app bootstrap
/// ([main.dart]), the PDF exporter (which builds public storage URLs) and
/// the offline connectivity probe (which needs a host to reach).
class SupabaseConfig {
  static const url = 'https://wcviqsddmurfohpbmomj.supabase.co';
  static const anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Indjdmlxc2RkbXVyZm9ocGJtb21qIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgwNjI1MjMsImV4cCI6MjA5MzYzODUyM30.PKgfGRfG4ftiVFMuIC96OToDjCogq1qIPxUw_fGQAJ0';
  static const host = 'wcviqsddmurfohpbmomj.supabase.co';
}
