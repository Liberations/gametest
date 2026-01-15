import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('About', style: TextStyle(color: Colors.white)),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: DefaultTextStyle(
            style: TextStyle(color: Colors.white, fontSize: 16, height: 1.5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Replace the content below with your app/about text
                Text('Hi there 👋', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 12),
                Text('- 🔭 I\'m currently working on flutter'),
                SizedBox(height: 8),
                Text('- 🌱 I\'m currently learning python'),
                SizedBox(height: 8),
                Text('- 😄 Pronouns: 问题不大'),
                SizedBox(height: 8),
                Text('- ⚡ Fun fact: 王者荣耀，启动'),
                SizedBox(height: 24),
                Text('H5测试小游戏完全免费', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 12),
                Text('Version: 1.0.0'),
                SizedBox(height: 40),
                Center(child: Text('power by 王思聪', style: TextStyle(color: Colors.grey))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

