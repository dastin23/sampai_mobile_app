import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/sampai_app.dart';
import 'core/config/supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load konfigurasi dari file .env
  await dotenv.load(fileName: '.env');

  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabasePublishableKey = dotenv.env['SUPABASE_PUBLISHABLE_KEY'];

  if (supabaseUrl == null ||
      supabaseUrl.isEmpty ||
      supabasePublishableKey == null ||
      supabasePublishableKey.isEmpty) {
    throw StateError('SUPABASE_URL dan SUPABASE_PUBLISHABLE_KEY wajib diisi.');
  }

  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabasePublishableKey,
  );

  // Status autentikasi Supabase rutin.
  debugPrint(
    supabase.auth.currentSession == null
        ? 'Supabase terinisialisasi, belum login'
        : 'Supabase terinisialisasi, user sudah login',
  );

  runApp(const ProviderScope(child: SampaiApp()));
}