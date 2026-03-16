import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'calls/call_history_manager.dart';
import 'calls/call_page.dart';
import 'calls/incoming_call_screen.dart';
import 'chat/chat_page.dart';
import 'contacts/contacts_page.dart';
import 'main.dart'; // To access global messengerKey
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

  // Timer to handle call timeouts
  Timer? _callTimeoutTimer;

  final List<Widget> _pages = [
    const ChatPage(),
    const CallPage(),
    const ContactsPage(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    // 1. Listen for network changes
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      _updateConnectionStatus(results.first);
    });

    // 2. Start listening for incoming calls
    _listenForIncomingCalls();
  }

  // --- LOGIC: GLOBAL CALL LISTENER ---
  void _listenForIncomingCalls() {
    if (currentUser == null) return;

    FirebaseFirestore.instance
        .collection('calls')
        .where('receiverId', isEqualTo: currentUser!.uid)
        .where('status', isEqualTo: 'dialing')
        .snapshots()
        .listen((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            var callDoc = snapshot.docs.first;
            var callData = callDoc.data();

            if (mounted) {
              // Start 30s timeout safety valve
              _startCallTimeout(callDoc.id, callData);

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => IncomingCallScreen(
                    callerName: callData['callerName'] ?? "Unknown",
                    callerPic: callData['callerPic'] ?? "",
                    callId: callDoc.id,
                    type: callData['type'] ?? "audio",
                  ),
                ),
              ).then((_) {
                _callTimeoutTimer?.cancel();
              });
            }
          }
        });
  }

  void _startCallTimeout(String callId, Map<String, dynamic> callData) {
    _callTimeoutTimer?.cancel();
    _callTimeoutTimer = Timer(const Duration(seconds: 30), () async {
      final doc = await FirebaseFirestore.instance
          .collection('calls')
          .doc(callId)
          .get();
      if (doc.exists && doc.data()?['status'] == 'dialing') {
        // Mark as missed in signaling collection
        await FirebaseFirestore.instance.collection('calls').doc(callId).update(
          {'status': 'missed'},
        );

        // Log to Call History
        final mySnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .get();
        final myData = mySnap.data() as Map<String, dynamic>;

        await CallHistoryManager.logCall(
          callerId: callData['callerId'],
          callerName: callData['callerName'],
          callerPic: callData['callerPic'] ?? "",
          receiverId: currentUser!.uid,
          receiverName: myData['name'] ?? "User",
          receiverPic: myData['profilePic'] ?? "",
          type: callData['type'] ?? "audio",
          status: 'missed',
        );
      }
    });
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    _callTimeoutTimer?.cancel();
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
          if (mounted) setState(() => _showBackOnline = false);
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
          _buildConnectivityBar(),
          Expanded(
            child: IndexedStack(index: _currentIndex, children: _pages),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
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
              // --- FIXED: Robust casting to prevent 'num' to 'int' errors ---
              var data = doc.data() as Map<String, dynamic>;
              var unreadVal = data['unreadCount'];
              if (unreadVal != null) {
                totalUnread += (unreadVal as num).toInt();
              }
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
                child: Center(
                  child: Text(
                    badgeCount > 9 ? "9+" : badgeCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
