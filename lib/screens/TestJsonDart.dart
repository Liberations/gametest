import 'dart:async';
import 'dart:js' as js_util;



import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'dart:ui' show ImageFilter;
import 'package:easy_localization/easy_localization.dart';
import 'package:giftgame/providers/TestJsProvider.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;

class TestJsCallPage extends StatefulWidget {
  const TestJsCallPage({super.key});

  @override
  State<TestJsCallPage> createState() => _TestJsCallPageState();
}

class _TestJsCallPageState extends State<TestJsCallPage> with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _rotateController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    // heartbeat pulse: repeat with reverse
    // After first frame, sync app locale from provider.lang (default 'en')
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final provider = Provider.of<TestJsProvider>(context, listen: false);
        final initialLang = provider.lang ?? 'en';
        final locale = Locale(initialLang);
        // Only set if different to avoid unnecessary reloads
        if (context.locale != locale) {
          context.setLocale(locale);
          debugPrint('Synced initial locale from provider: $initialLang');
        }
      } catch (e) {
        debugPrint('Failed to sync initial locale from provider: $e');
      }
    });
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnimation = Tween<double>(begin: 0.96, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);

    // continuous rotation
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_rotateController);
    _rotateController.repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  void _callAndroidJs(String msg) {
    if (!kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('not_running_on_web'.tr())),
      );
      return;
    }

    try {
      js_util.context["AndroidNative"].callMethod("h5Call"  ,[msg] );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'failed_call_android'.tr(namedArgs: {'error': e.toString()}),
          ),
        ),
      );
    }
  }

  Future<void> _loadAndPlaySvga(String url) async {
    if (!kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('not_running_on_web'.tr())));
      return;
    }

    try {
      js_util.context["AndroidNative"].callMethod("playVap"  ,[url] );
    } catch (e) {
      debugPrint('Error calling AndroidNative.playVap: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('failed_call_android'.tr(namedArgs: {'error': e.toString()}))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('js_call_title'.tr())),
      body: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // background image
            Image.network(
              'https://979c-commentimg-1252317822.image.myqcloud.com/4eb9127b8d68b2bdad27a45fcafdfd19.jpeg',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
            // gaussian blur
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                child: Container(
                  color: const Color.fromRGBO(0, 0, 0, 0.25), // dim to improve contrast
                ),
              ),
            ),
            // content
            Consumer<TestJsProvider>(
              builder: (context, provider, child) {
                final avatar = provider.userAvatar;
                final nickname = provider.userNickname ?? 'Guest';
                final lang = provider.lang ?? 'en';

                Widget avatarWidget;
                if (provider.isLoadingUserInfo) {
                  avatarWidget = const CircularProgressIndicator();
                } else if (avatar != null && avatar.startsWith('http')) {
                  avatarWidget = CircleAvatar(
                    radius: 36,
                    backgroundImage: NetworkImage(avatar),
                  );
                } else {
                  avatarWidget = const CircleAvatar(
                    radius: 36,
                    backgroundImage: AssetImage('lib/assets/ic_mine.webp'),
                  );
                }

                final displayName = (nickname.isEmpty) ? 'guest'.tr() : nickname;
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('${'lang_label'.tr()}: ${lang.toUpperCase()}'),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: () async {
                                final supported = [
                                  const Locale('zh'),
                                  const Locale('en'),
                                  const Locale('ar'),
                                  const Locale('es'),
                                  const Locale('pt'),
                                  const Locale('tr'),
                                ];
                                final names = [
                                  '中文',
                                  'English',
                                  'العربية',
                                  'Español',
                                  'Português',
                                  'Türkçe',
                                ];
                                final currentCode = provider.lang ?? 'en';
                    
                                String? pickedCode = await showDialog<String>(
                                  context: context,
                                  builder: (ctx) {
                                    String? tempCode = currentCode;
                                    return AlertDialog(
                                      title: Text('switch_language'.tr()),
                                      content: StatefulBuilder(
                                        builder: (c, setState) {
                                          return Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: List.generate(
                                              supported.length,
                                              (i) {
                                                final code =
                                                    supported[i].languageCode;
                                                return RadioListTile<String>(
                                                  value: code,
                                                  groupValue: tempCode,
                                                  title: Text(names[i]),
                                                  onChanged: (String? v) =>
                                                      setState(() => tempCode = v),
                                                );
                                              },
                                            ),
                                          );
                                        },
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx, null),
                                          child: Text('cancel'.tr()),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, tempCode),
                                          child: Text('ok'.tr()),
                                        ),
                                      ],
                                    );
                                  },
                                );
                    
                                if (pickedCode != null) {
                                  final pickedLocale = Locale(pickedCode);
                                  await context.setLocale(pickedLocale);
                                  provider.setLang(pickedCode);
                                }
                              },
                              child: Text('switch_language'.tr()),
                            ),
                          ],
                        ),
                        // animated avatar: heartbeat scale + continuous rotation
                        Center(
                          child: AnimatedBuilder(
                            animation: Listenable.merge([_pulseController, _rotateController]),
                            child: avatarWidget,
                            builder: (context, child) {
                              final scale = _scaleAnimation.value;
                              final angle = _rotationAnimation.value * 2 * math.pi;
                              return Transform.rotate(
                                angle: angle,
                                child: Transform.scale(
                                  scale: scale,
                                  child: child,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Center(child: Text(displayName,style: TextStyle(color: Colors.black),)),
                        const SizedBox(height: 12),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () {
                            // example actions to call on Android side
                            _callAndroidJs('recharge');
                          },
                          child: Text('recharge'.tr()),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => _callAndroidJs('cpRank'),
                          child: Text('cp_rank'.tr()),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () =>
                              _callAndroidJs('invite:https://example.com/invite'),
                          child: Text('invite_page'.tr()),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => _callAndroidJs('jumpHome:9009118'),
                          child: Text('visit_home'.tr() + '9009118'),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => _loadAndPlaySvga('https://horochat-1327595181.cos.accelerate.myqcloud.com/admin/69a3d144b52a053ed80d4b7b7713f29e.svga'),
                          child: Text('Play SVGA'),
                        ),
                        const SizedBox(height: 24),
                        //https://horochat-1327595181.cos.accelerate.myqcloud.com/admin/f9b0f06fcf8f79c870117ab7ed634133.mp4
                        ElevatedButton(
                          onPressed: () => _loadAndPlaySvga('https://horochat-1327595181.cos.accelerate.myqcloud.com/admin/f9b0f06fcf8f79c870117ab7ed634133.mp4'),
                          child: Text('Play VAP'),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
