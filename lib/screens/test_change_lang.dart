import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';

class TestChangeLang extends StatefulWidget {
  const TestChangeLang({super.key});

  @override
  State<TestChangeLang> createState() => _TestChangeLangState();
}

class _TestChangeLangState extends State<TestChangeLang> {
  void _showLanguageMenu() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: Text('English'), onTap: () => Navigator.pop(context, 'en')),
            ListTile(title: Text('العربية'), onTap: () => Navigator.pop(context, 'ar')),
            ListTile(title: Text('Español'), onTap: () => Navigator.pop(context, 'es')),
            ListTile(title: Text('Português'), onTap: () => Navigator.pop(context, 'pt')),
            ListTile(title: Text('Türkçe'), onTap: () => Navigator.pop(context, 'tr')),
          ],
        ),
      ),
    );
    if (choice != null) {
      await context.setLocale(Locale(choice));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    final entries = provider.getLeaderboard();

    return Scaffold(
      appBar: AppBar(
        title: Text('leaderboard_title'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: _showLanguageMenu,
            tooltip: 'switch_language'.tr(),
          )
        ],
      ),
      body: entries.isEmpty
          ? Center(child: Text('no_data'.tr()))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: entries.length,
              separatorBuilder: (_, __) => const Divider(color: Colors.white24),
              itemBuilder: (context, index) {
                final e = entries[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  leading: CircleAvatar(
                    backgroundImage: AssetImage(e.avatarAsset),
                    radius: 24,
                  ),
                  title: Text(e.name),
                  subtitle: Text('${'score'.tr()}: ${e.score}'),
                  trailing: ElevatedButton(
                    onPressed: () {
                      final msg = 'supported_msg'.tr(namedArgs: {'name': e.name});
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                    },
                    child: Text('support'.tr()),
                  ),
                );
              },
            ),
    );
  }
}
