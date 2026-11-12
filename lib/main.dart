import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:hive_flutter/hive_flutter.dart';
import 'login_page.dart';
import 'dashboard_page.dart';
import 'home_page.dart';
import 'seller_page.dart';
import 'admin_page.dart';
import 'landing.dart';

// URL Default (Ganti dengan URL server Pterodactyl kamu yang benar)
String baseUrl = "http://public.zhaher.my.id:4384"; 

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await Hive.initFlutter();
  await Hive.openBox('finance_box');
  
  // Panggil loadConfig (hanya sekali jalan, tidak di-looping)
  await loadConfig();

  runApp(const MyApp());
}

Future<void> loadConfig() async {
  // 1. Coba ambil dari GitHub
  try {
    final githubRes = await http
        .get(
          Uri.parse(
            "https://raw.githubusercontent.com/gajelas0196-lgtm/Zijii/main/Config.json",
          ),
        )
        .timeout(const Duration(seconds: 5)); // Waktu tunggu dipersingkat jadi 5 detik

    if (githubRes.statusCode == 200) {
      final data = jsonDecode(githubRes.body);
      if (data["base_url"] != null &&
          data["base_url"].toString().isNotEmpty) {
        baseUrl = data["base_url"];
        print("Config berhasil dimuat dari GitHub: $baseUrl");
        return; // Keluar dari fungsi jika berhasil
      }
    }
  } catch (e) {
    print("Gagal ambil config dari GitHub: $e");
  }

  // 2. Jika GitHub gagal, coba ambil dari URL Default (Server)
  try {
    final serverRes = await http
        .get(Uri.parse("$baseUrl/config.json"))
        .timeout(const Duration(seconds: 5));

    if (serverRes.statusCode == 200) {
      final data = jsonDecode(serverRes.body);
      if (data["base_url"] != null &&
          data["base_url"].toString().isNotEmpty) {
        baseUrl = data["base_url"];
        print("Config berhasil dimuat dari Server: $baseUrl");
        return; // Keluar dari fungsi jika berhasil
      }
    }
  } catch (e) {
    print("Gagal ambil config dari Server: $e");
  }

  // 3. Jika dua-duanya gagal, aplikasi tetap lanjut pakai URL default di atas
  print("Menggunakan URL Default: $baseUrl");
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AVERA',
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'ShareTechMono',
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark().copyWith(
          secondary: Colors.purple,
        ),
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
  return MaterialPageRoute(
    builder: (_) => const Scaffold(
      backgroundColor: Colors.red, // Warna merah biar kelihatan jelas
      body: Center(
        child: Text(
          "TES BERHASIL",
          style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
        ),
      ),
    ),
  );

          case '/login':
            return MaterialPageRoute(builder: (_) => const LoginPage());

          case '/dashboard':
            final args = settings.arguments as Map<String, dynamic>? ?? {};
            return MaterialPageRoute(
              builder: (_) => DashboardPage(
                username: args['username'] ?? '',
                password: args['password'] ?? '',
                role: args['role'] ?? '',
                sessionKey: args['key'] ?? '',
                expiredDate: args['expiredDate'] ?? '',
                listBug: List<Map<String, dynamic>>.from(args['listBug'] ?? []),
                listDoos: List<Map<String, dynamic>>.from(
                  args['listDoos'] ?? [],
                ),
                news: List<Map<String, dynamic>>.from(args['news'] ?? []),
              ),
            );

          case '/home':
            final args = settings.arguments as Map<String, dynamic>? ?? {};
            return MaterialPageRoute(
              builder: (_) => HomePage(
                username: args['username'] ?? '',
                password: args['password'] ?? '',
                listBug: List<Map<String, dynamic>>.from(args['listBug'] ?? []),
                role: args['role'] ?? '',
                expiredDate: args['expiredDate'] ?? '',
                sessionKey: args['sessionKey'] ?? '',
              ),
            );

          case '/seller':
            final args = settings.arguments as Map<String, dynamic>? ?? {};
            return MaterialPageRoute(
              builder: (_) => SellerPage(keyToken: args['keyToken'] ?? ''),
            );

          case '/admin':
            final args = settings.arguments as Map<String, dynamic>? ?? {};
            return MaterialPageRoute(
              builder: (_) => AdminPage(sessionKey: args['sessionKey'] ?? ''),
            );

          default:
            return MaterialPageRoute(
              builder: (_) =>
                  const Scaffold(body: Center(child: Text("404 - Not Found"))),
            );
        }
      },
    );
  }
}
