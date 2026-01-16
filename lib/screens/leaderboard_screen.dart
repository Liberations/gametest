import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../models/leaderboard_entry.dart';
import 'package:easy_localization/easy_localization.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    var provider = context.read<GameProvider>();
    List<LeaderboardEntry> entries = provider.getLeaderboard();

    return Scaffold(
      appBar: AppBar(
        title: Text('leaderboard_title'.tr(), style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.black,
      body: entries.isEmpty
          ? Center(child: Text('no_data'.tr(), style: const TextStyle(color: Colors.white)))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: entries.length,
              separatorBuilder: (_, __) => const Divider(color: Colors.white24),
              itemBuilder: (context, index) {
                final e = entries[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: AssetImage(e.avatarAsset),
                  ),
                  title: Text(e.name, style: const TextStyle(color: Colors.white)),
                  trailing: Text('${e.score}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                );
              },
            ),
    );
  }
}
