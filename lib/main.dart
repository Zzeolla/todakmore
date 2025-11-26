import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:todakmore/provider/user_provider.dart';
import 'package:todakmore/screen/album_start_screen.dart';
import 'package:todakmore/screen/login_screen.dart';
import 'package:todakmore/screen/main_screen.dart';
import 'package:todakmore/screen/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: const TodakmoreApp(),
    ),
  );
}

class TodakmoreApp extends StatelessWidget {
  const TodakmoreApp({super.key});

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
      initialRoute: '/',
      routes: {
        '/': (_) => const SplashScreen(),
        '/login' : (_) => const LoginScreen(),
        '/album-start' : (_) => const AlbumStartScreen(),
        '/main' : (_) => const MainScreen(),
      },
    );
  }
}
