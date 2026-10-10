import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

/// Redirect URL autentikasi (deep link) untuk flow yang memakai email, mis.
/// reset kata sandi. Wajib terdaftar di dashboard Supabase:
/// Authentication → URL Configuration → Redirect URLs.
/// Sesuaikan dengan intent-filter skema `sampai` di AndroidManifest.xml.
const sampaiAuthRedirectUrl = 'sampai://reset-password';
