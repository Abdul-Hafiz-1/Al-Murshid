import 'package:flutter/material.dart';

class VoiceScreen extends StatelessWidget {
  const VoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF071025),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text('Speaking to MindBot')),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Center(
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0xFF4EA1FF), Color(0xFF0B3B76)],
                    center: Alignment(-0.2, -0.2),
                    radius: 0.9,
                  ),
                  boxShadow: [
                    BoxShadow(color: Colors.blue.withOpacity(0.25), blurRadius: 40, spreadRadius: 8),
                  ],
                ),
                child: Center(
                  child: Text('I\'m listening... 9', style: TextStyle(color: Colors.white70, fontSize: 16)),
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text("What's your mind today?", style: TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(20),
                backgroundColor: const Color(0xFF2D6BFF),
              ),
              onPressed: () {},
              child: const Icon(Icons.mic, size: 28, color: Colors.white),
            )
          ],
        ),
      ),
    );
  }
}
