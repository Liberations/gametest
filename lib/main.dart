import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:giftgame/providers/TestJsProvider.dart';
import 'package:giftgame/screens/TestJsonDart.dart';
import 'package:provider/provider.dart';

void main() async {
  String? uid;
  String? token;
  String? lang;

  if (kIsWeb) {
    // Uri.base contains the current page URL on web
    final uri = Uri.base;
    uid = uri.queryParameters['uid'];
    token = uri.queryParameters['token'];
    lang = uri.queryParameters['lang'];
    //uid=9009294&token=a3a7644b7310e7253d504cf1fde00d15&lang=en
    debugPrint('URL params: uid=$uid, token=$token lang=$lang');
  }
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
        Locale('es'),
        Locale('pt'),
        Locale('tr'),
        Locale('zh'), // Chinese (Simplified) locale added
      ],
      path: 'assets/lang',
      fallbackLocale: const Locale('en'),
      child: ChangeNotifierProvider(
        create: (_) => TestJsProvider()..setUrlParams(lang,uid, token),
        child: MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TestJsCall',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.black,
        textTheme: Theme.of(
          context,
        ).textTheme.apply(bodyColor: Colors.white, displayColor: Colors.white),
      ),
      home: const TestJsCallPage(),
      locale: context.locale,
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationDelegates,
    );
  }
}
