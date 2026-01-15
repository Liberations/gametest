import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../models/leaderboard_entry.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    var provider = context.read<GameProvider>();
    List<LeaderboardEntry> entries = provider.getLeaderboard();

    return Scaffold(
      appBar: AppBar(
        title: Text('Leaderboard', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.black,
      body: ListView.separated(
        padding: EdgeInsets.all(16),
        itemCount: entries.length,
        separatorBuilder: (_, __) => Divider(color: Colors.white24),
        itemBuilder: (context, index) {
          final e = entries[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: AssetImage(e.avatarAsset),
            ),
            title: Text(e.name, style: TextStyle(color: Colors.white)),
            trailing: Text('${e.score}', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          );
        },
      ),
    );
  }
}

