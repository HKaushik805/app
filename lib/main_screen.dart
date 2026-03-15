import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'calls/call_page.dart';
import 'chat/chat_page.dart';
import 'contacts/contacts_page.dart';
import 'main.dart'; // To access messengerKey
import 'profile/profile_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final currentUser = FirebaseAuth.instance.currentUser;

  // Connectivity Variables
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  bool _isOffline = false;
  bool _showBackOnline = false;

  final List<Widget> _pages = [
    const ChatPage(),
    const CallPage(),
    const ContactsPage(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    // Start listening for network changes
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      _updateConnectionStatus(results.first);
    });
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    if (result == ConnectivityResult.none) {
      setState(() {
        _isOffline = true;
        _showBackOnline = false;
      });
    } else {
      if (_isOffline) {
        setState(() {
          _isOffline = false;
          _showBackOnline = true;
        });
        Timer(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() => _showBackOnline = false);
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Column(
        children: [
          // --- THE CONNECTIVITY BAR ---
          _buildConnectivityBar(),

          Expanded(
            child: IndexedStack(index: _currentIndex, children: _pages),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      // --- WRAPPING NAV BAR IN STREAM TO CALCULATE GLOBAL UNREAD ---
      floatingActionButton: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser?.uid)
            .collection('recent_chats')
            .snapshots(),
        builder: (context, snapshot) {
          int totalUnread = 0;
          if (snapshot.hasData) {
            for (var doc in snapshot.data!.docs) {
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
              totalUnread += (data['unreadCount'] ?? 0) as int;
            }
          }
          return _buildCustomNavBar(screenWidth, totalUnread);
        },
      ),
    );
  }

  Widget _buildConnectivityBar() {
    bool showBar = _isOffline || _showBackOnline;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: showBar ? 30 : 0,
      width: double.infinity,
      color: _isOffline ? Colors.redAccent : Colors.green,
      child: Center(
        child: Text(
          _isOffline ? "Waiting for network..." : "Back Online",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildCustomNavBar(double width, int unreadCount) {
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
          _navIcon(
            Icons.chat_bubble_outline,
            _currentIndex == 0,
            0,
            badgeCount: unreadCount,
          ),
          _navIcon(Icons.phone_outlined, _currentIndex == 1, 1),
          _navIcon(Icons.people_outline, _currentIndex == 2, 2),
          _navIcon(Icons.person_outline, _currentIndex == 3, 3),
        ],
      ),
    );
  }

  Widget _navIcon(
    IconData icon,
    bool isActive,
    int index, {
    int badgeCount = 0,
  }) {
    return GestureDetector(
      onTap: () {
        messengerKey.currentState?.clearSnackBars();
        setState(() => _currentIndex = index);
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
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
          // --- THE NEON GLOBAL BADGE ---
          if (badgeCount > 0 && !isActive)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: const Color(0xFFD633FF),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF0D0D0D), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD633FF).withOpacity(0.5),
                      blurRadius: 5,
                    ),
                  ],
                ),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                child: Text(
                  badgeCount > 9 ? "9+" : badgeCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign:
                      TextAlign.center, // FIXED: Now using TextAlign.center
                ),
              ),
            ),
        ],
      ),
    );
  }
}
