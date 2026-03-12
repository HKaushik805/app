import 'package:flutter/material.dart';
import 'chat/chat_page.dart';
import 'calls/call_page.dart';
import 'contacts/contacts_page.dart';
import 'profile/profile_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const ChatPage(),
    const CallPage(),
    const ContactsPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      // IndexedStack prevents the white screen by keeping pages in memory
      body: IndexedStack(index: _currentIndex, children: _pages),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _buildCustomNavBar(screenWidth),
    );
  }

  Widget _buildCustomNavBar(double width) {
    return Container(
      height: 70,
      width: width * 0.85,
      decoration: BoxDecoration(
        color: const Color(0xFF161616).withOpacity(0.98),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _navIcon(Icons.chat_bubble_outline, _currentIndex == 0, 0),
          _navIcon(Icons.phone_outlined, _currentIndex == 1, 1),
          _navIcon(Icons.people_outline, _currentIndex == 2, 2),
          _navIcon(Icons.person_outline, _currentIndex == 3, 3),
        ],
      ),
    );
  }

  Widget _navIcon(IconData icon, bool isActive, int index) {
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: isActive
            ? const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFFD633FF), Color(0xFF8E2DE2)],
                ),
                boxShadow: [
                  BoxShadow(color: Color(0xFF8E2DE2), blurRadius: 15),
                ],
              )
            : null,
        child: Icon(
          icon,
          color: isActive ? Colors.white : const Color(0xFF555555),
          size: 28,
        ),
      ),
    );
  }
}
