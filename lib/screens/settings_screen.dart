import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/gestures.dart';
import '../providers/game_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: DefaultTextStyle(
            style: TextStyle(color: Colors.white),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Horizontal threshold (touch)', style: TextStyle(fontWeight: FontWeight.bold)),
                Slider(
                  value: provider.hThresholdTouch,
                  min: 0.5,
                  max: 30,
                  divisions: 59,
                  label: provider.hThresholdTouch.toStringAsFixed(1),
                  onChanged: (v) => provider.updateHThresholdTouch(v),
                  onChangeEnd: (_) => provider.saveSettings(),
                ),
                SizedBox(height: 8),
                Text('Horizontal threshold (trackpad/mouse)', style: TextStyle(fontWeight: FontWeight.bold)),
                Slider(
                  value: provider.hThresholdTrackpad,
                  min: 0.5,
                  max: 30,
                  divisions: 59,
                  label: provider.hThresholdTrackpad.toStringAsFixed(1),
                  onChanged: (v) => provider.updateHThresholdTrackpad(v),
                  onChangeEnd: (_) => provider.saveSettings(),
                ),
                SizedBox(height: 8),
                Text('Horizontal threshold (desktop)', style: TextStyle(fontWeight: FontWeight.bold)),
                Slider(
                  value: provider.hThresholdDesktop,
                  min: 0.5,
                  max: 50,
                  divisions: 99,
                  label: provider.hThresholdDesktop.toStringAsFixed(1),
                  onChanged: (v) => provider.updateHThresholdDesktop(v),
                  onChangeEnd: (_) => provider.saveSettings(),
                ),
                Divider(color: Colors.grey),
                Text('Vertical threshold (touch)', style: TextStyle(fontWeight: FontWeight.bold)),
                Slider(
                  value: provider.vThresholdTouch,
                  min: 4,
                  max: 100,
                  divisions: 96,
                  label: provider.vThresholdTouch.toStringAsFixed(0),
                  onChanged: (v) => provider.updateVThresholdTouch(v),
                  onChangeEnd: (_) => provider.saveSettings(),
                ),
                SizedBox(height: 8),
                Text('Vertical threshold (trackpad/mouse)', style: TextStyle(fontWeight: FontWeight.bold)),
                Slider(
                  value: provider.vThresholdTrackpad,
                  min: 4,
                  max: 100,
                  divisions: 96,
                  label: provider.vThresholdTrackpad.toStringAsFixed(0),
                  onChanged: (v) => provider.updateVThresholdTrackpad(v),
                  onChangeEnd: (_) => provider.saveSettings(),
                ),
                SizedBox(height: 8),
                Text('Vertical threshold (desktop)', style: TextStyle(fontWeight: FontWeight.bold)),
                Slider(
                  value: provider.vThresholdDesktop,
                  min: 4,
                  max: 150,
                  divisions: 146,
                  label: provider.vThresholdDesktop.toStringAsFixed(0),
                  onChanged: (v) => provider.updateVThresholdDesktop(v),
                  onChangeEnd: (_) => provider.saveSettings(),
                ),
                Divider(color: Colors.grey),
                Text('Fling velocity threshold (px/s)', style: TextStyle(fontWeight: FontWeight.bold)),
                Slider(
                  value: provider.flingThreshold,
                  min: 100,
                  max: 1500,
                  divisions: 140,
                  label: provider.flingThreshold.toStringAsFixed(0),
                  onChanged: (v) => provider.updateFlingThreshold(v),
                  onChangeEnd: (_) => provider.saveSettings(),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    provider.hThresholdTouch = 3.0;
                    provider.hThresholdTrackpad = 2.0;
                    provider.hThresholdDesktop = 5.0;
                    provider.vThresholdTouch = 16.0;
                    provider.vThresholdTrackpad = 12.0;
                    provider.vThresholdDesktop = 20.0;
                    provider.flingThreshold = 600.0;
                    provider.saveSettings();
                  },
                  child: Text('Restore defaults'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
