import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:media_kit/media_kit.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:todakmore/provider/album_provider.dart';
import 'package:todakmore/provider/feed_provider.dart';
import 'package:todakmore/provider/todak_provider.dart';
import 'package:todakmore/provider/user_provider.dart';
import 'package:todakmore/screen/album_start_screen.dart';
import 'package:todakmore/screen/login_screen.dart';
import 'package:todakmore/screen/main_screen.dart';
import 'package:todakmore/screen/upload_confirm_screen.dart';
import 'package:todakmore/screen/upload_select_screen.dart';
import 'package:todakmore/screen/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  
  String? bootError;
  
  Future<T> withTimeout<T>(Future<T> f, String label) {
    return f.timeout(
      const Duration(seconds: 8),
      onTimeout: () => throw Exception('BOOT_TIMEOUT: $label'),
    );
  }

  try {
    await withTimeout(dotenv.load(fileName: ".env"), 'dotenv.load(.env)');

    final url = dotenv.env['SUPABASE_URL'];
    final anon = dotenv.env['SUPABASE_ANON_KEY'];

    if (url == null || url.isEmpty) {
      throw Exception('ENV_MISSING: SUPABASE_URL');
    }
    if (anon == null || anon.isEmpty) {
      throw Exception('ENV_MISSING: SUPABASE_ANON_KEY');
    }

    // 2) Supabase
    await withTimeout(
      Supabase.initialize(url: url, anonKey: anon),
      'Supabase.initialize',
    );

    // 3) Firebase
    await withTimeout(Firebase.initializeApp(), 'Firebase.initializeApp');
  } on Exception catch (e) {
    // 실패해도 앱은 띄우고, 원인만 표시
    bootError = e.toString();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => AlbumProvider()),
        ChangeNotifierProvider(create: (_) => FeedProvider()),
        ChangeNotifierProvider(create: (_) => TodakProvider()),
      ],
      child: TodakmoreApp(bootError: bootError),
    ),
  );
}

class TodakmoreApp extends StatelessWidget {
  final String? bootError;
  const TodakmoreApp({super.key, this.bootError});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '토닥모아',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFC6B6FF)),
        useMaterial3: true,
        fontFamily: 'NotoSansKR',
      ),
      initialRoute: bootError == null ? '/' : '/boot-error',
      routes: {
        '/': (_) => const SplashScreen(),
        '/login' : (_) => const LoginScreen(),
        '/album-start' : (_) => const AlbumStartScreen(),
        '/main' : (_) => const MainScreen(),
        '/upload-select' : (_) => const UploadSelectScreen()
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/upload-confirm') {
          final assets = settings.arguments as List<AssetEntity>;

          return MaterialPageRoute(
            builder: (_) => UploadConfirmScreen(assets: assets),
          );
        }
        return null;
      },
    );
  }
}

class BootErrorScreen extends StatelessWidget {
  final String message;
  const BootErrorScreen({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: SelectableText(
              '부팅 중 오류가 발생했어요.\n\n'
                  '$message\n\n'
                  '가장 흔한 원인:\n'
                  '1) .env가 앱 번들에 포함되지 않음 (pubspec.yaml assets)\n'
                  '2) APP_ENV_FILE 시크릿 내용 형식 오류 (KEY=VALUE)\n'
                  '3) iOS Firebase plist 누락 (GoogleService-Info.plist)\n',
            ),
          ),
        ),
      ),
    );
  }
}
