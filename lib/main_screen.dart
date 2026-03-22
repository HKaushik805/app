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
import 'main.dart';
import 'profile/profile_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final currentUser = FirebaseAuth.instance.currentUser;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  bool _isOffline = false;
  bool _showBackOnline = false;
  Timer? _callTimeoutTimer;

  final List<Widget> _pages = [
    const ChatPage(),
    const CallPage(),
    const ContactsPage(),
    const ProfilePage()
  ];

  @override
  void initState() {
    super.initState();
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((results) => _updateConnectionStatus(results.first));
    _listenForIncomingCalls();
  }

  void _listenForIncomingCalls() {
    if (currentUser == null) return;
    FirebaseFirestore.instance
        .collection('calls')
        .where('receiverId', isEqualTo: currentUser!.uid)
        .where('status', isEqualTo: 'dialing')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        var doc = snapshot.docs.first;
        var data = doc.data();
        if (mounted) {
          _startCallTimeout(doc.id, data);
          Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (c) => IncomingCallScreen(
                          callerName: data['callerName'] ?? "User",
                          callerPic: data['callerPic'] ?? "",
                          callId: doc.id,
                          type: data['type'] ?? "audio")))
              .then((_) => _callTimeoutTimer?.cancel());
        }
      }
    });
  }

  void _startCallTimeout(String callId, Map<String, dynamic> data) {
    _callTimeoutTimer?.cancel();
    _callTimeoutTimer = Timer(const Duration(seconds: 30), () async {
      final doc = await FirebaseFirestore.instance
          .collection('calls')
          .doc(callId)
          .get();
      if (doc.exists && doc.data()?['status'] == 'dialing') {
        await FirebaseFirestore.instance
            .collection('calls')
            .doc(callId)
            .update({'status': 'missed'});
        final mySnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .get();
        final myData = mySnap.data() as Map<String, dynamic>;
        await CallHistoryManager.logCall(
            callerId: data['callerId'],
            callerName: data['callerName'],
            callerPic: data['callerPic'] ?? "",
            receiverId: currentUser!.uid,
            receiverName: myData['name'],
            receiverPic: myData['profilePic'] ?? "",
            type: data['type'],
            status: 'missed');
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
    } else if (_isOffline) {
      setState(() {
        _isOffline = false;
        _showBackOnline = true;
      });
      Timer(const Duration(seconds: 2), () {
        if (mounted) setState(() => _showBackOnline = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Column(children: [
        _buildConnectivityBar(),
        Expanded(child: IndexedStack(index: _currentIndex, children: _pages)),
      ]),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser?.uid)
            .collection('recent_chats')
            .snapshots(),
        builder: (context, snapshot) {
          int total = 0;
          if (snapshot.hasData) {
            for (var doc in snapshot.data!.docs) {
              var d = doc.data() as Map<String, dynamic>;
              // --- FIXED: NUM TO INT CASTING ---
              total += (d['unreadCount'] as num? ?? 0).toInt();
            }
          }
          return _buildNavBar(screenWidth, total);
        },
      ),
    );
  }

  Widget _buildConnectivityBar() {
    bool show = _isOffline || _showBackOnline;
    return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: show ? 30 : 0,
        width: double.infinity,
        color: _isOffline ? Colors.redAccent : Colors.green,
        child: Center(
            child: Text(_isOffline ? "Waiting for network..." : "Back Online",
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold))));
  }

  Widget _buildNavBar(double w, int u) => Container(
      height: 70,
      width: w * 0.85,
      decoration: BoxDecoration(
          color: const Color(0xFF161616).withOpacity(0.98),
          borderRadius: BorderRadius.circular(40)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        _nav(Icons.chat_bubble_outline, _currentIndex == 0, 0, u),
        _nav(Icons.phone_outlined, _currentIndex == 1, 1, 0),
        _nav(Icons.people_outline, _currentIndex == 2, 2, 0),
        _nav(Icons.person_outline, _currentIndex == 3, 3, 0)
      ]));
  Widget _nav(IconData i, bool a, int idx, int b) => GestureDetector(
      onTap: () {
        messengerKey.currentState?.clearSnackBars();
        setState(() => _currentIndex = idx);
      },
      child: Stack(clipBehavior: Clip.none, children: [
        Container(
            padding: const EdgeInsets.all(12),
            decoration: a
                ? const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                        colors: [Color(0xFFD633FF), Color(0xFF8E2DE2)]),
                    boxShadow: [
                        BoxShadow(color: Color(0xFF8E2DE2), blurRadius: 15)
                      ])
                : null,
            child: Icon(i,
                color: a ? Colors.white : const Color(0xFF555555), size: 28)),
        if (b > 0 && !a)
          Positioned(
              right: -2,
              top: -2,
              child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                      color: const Color(0xFFD633FF),
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: const Color(0xFF0D0D0D), width: 2)),
                  constraints:
                      const BoxConstraints(minWidth: 18, minHeight: 18),
                  child: Center(
                      child: Text(b > 9 ? "9+" : b.toString(),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold)))))
      ]));
}
