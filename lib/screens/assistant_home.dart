import 'package:flutter/material.dart';
import 'package:tarteel/theme/app_theme.dart';
import 'conversation_screen.dart';
import 'voice_screen.dart';

class AssistantHome extends StatelessWidget {
  const AssistantHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF071025), Color(0xFF0B1633)],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Hi, Michael', style: TextStyle(color: Colors.white70, fontSize: 14)),
                          SizedBox(height: 6),
                          Text('How can I assist you today?', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.white12,
                      child: const Icon(Icons.person, color: Colors.white),
                    )
                  ],
                ),
              ),

              // Premium Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('Premium Plan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                            SizedBox(height: 6),
                            Text('Unlock exclusive features and enhanced capabilities', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.assistantBlue,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {},
                        child: const Text('Upgrade Now'),
                      )
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Recent chats list
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ListView.separated(
                    padding: const EdgeInsets.only(bottom: 120, top: 8),
                    itemBuilder: (context, index) {
                      return ListTile(
                        tileColor: Colors.white.withOpacity(0.03),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.chat_bubble_outline, color: Colors.white70),
                        ),
                        title: const Text('Machine learning to improve conversations', style: TextStyle(color: Colors.white)),
                        subtitle: const Text('Tap to continue', style: TextStyle(color: Colors.white70)),
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ConversationScreen())),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemCount: 6,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: FloatingActionButton(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const VoiceScreen())),
          child: const Icon(Icons.mic),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.transparent,
        elevation: 0,
        notchMargin: 8,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Icon(Icons.home, color: Colors.white70),
              Icon(Icons.star_border, color: Colors.white70),
              SizedBox(width: 48),
              Icon(Icons.settings, color: Colors.white70),
              Icon(Icons.person_outline, color: Colors.white70),
            ],
          ),
        ),
      ),
    );
  }
}
