import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'providers/game_provider.dart';
import 'screens/game_screen.dart';

void main() {
  // Parse URL parameters on web
  String? uid;
  String? token;

  if (kIsWeb) {
    // Uri.base contains the current page URL on web
    final uri = Uri.base;
    uid = uri.queryParameters['uid'];
    token = uri.queryParameters['token'];
    debugPrint('URL params: uid=$uid, token=$token');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GameProvider()..setUrlParams(uid, token)),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gift Game',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: GameScreen(),
    );
  }
}
