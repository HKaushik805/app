import 'dart:convert';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../widgets/grind_avatar.dart';
import 'call_history_manager.dart';
import 'call_room_page.dart';

class OutgoingCallScreen extends StatefulWidget {
  final String receiverName, receiverPic, callId, type;
  const OutgoingCallScreen(
      {super.key,
      required this.receiverName,
      required this.receiverPic,
      required this.callId,
      required this.type});

  @override
  State<OutgoingCallScreen> createState() => _OutgoingCallScreenState();
}

class _OutgoingCallScreenState extends State<OutgoingCallScreen> {
  final myId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _listenToCallStatus();
  }

  void _listenToCallStatus() {
    FirebaseFirestore.instance
        .collection('calls')
        .doc(widget.callId)
        .snapshots()
        .listen((snap) {
      if (snap.exists) {
        String s = snap.data()?['status'] ?? "";
        if (s == 'accepted') {
          if (mounted) {
            // SWAP for the Jitsi Bridge
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (c) => CallRoomPage(
                        callId: widget.callId, channelName: widget.callId)));
          }
        } else if (s == 'declined' || s == 'missed' || s == 'ended') {
          if (mounted) Navigator.pop(context);
        }
      }
    });
  }

  Future<void> _cancelCall() async {
    final mySnap =
        await FirebaseFirestore.instance.collection('users').doc(myId).get();
    final myData = mySnap.data() as Map<String, dynamic>;

    await FirebaseFirestore.instance
        .collection('calls')
        .doc(widget.callId)
        .update({'status': 'cancelled'});

    await CallHistoryManager.logCall(
      callerId: myId,
      callerName: myData['name'],
      callerPic: myData['profilePic'] ?? "",
      receiverId: "unknown",
      receiverName: widget.receiverName,
      receiverPic: widget.receiverPic,
      type: widget.type,
      status: 'cancelled',
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        Container(
            decoration: BoxDecoration(
                image: widget.receiverPic.startsWith('http')
                    ? DecorationImage(
                        image: NetworkImage(widget.receiverPic),
                        fit: BoxFit.cover)
                    : (widget.receiverPic.isNotEmpty
                        ? DecorationImage(
                            image:
                                MemoryImage(base64Decode(widget.receiverPic)),
                            fit: BoxFit.cover)
                        : null),
                color: Colors.black),
            child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(color: Colors.black.withOpacity(0.8)))),
        SafeArea(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
              Column(children: [
                const Text("CALLING...",
                    style: TextStyle(
                        color: Color(0xFF8E2DE2),
                        letterSpacing: 4,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
                const SizedBox(height: 40),
                GrindAvatar(
                    imageUrl: widget.receiverPic,
                    radius: 70,
                    name: widget.receiverName),
                const SizedBox(height: 20),
                Text(widget.receiverName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold)),
                const Text("Establishing secure link...",
                    style: TextStyle(color: Colors.grey, fontSize: 14)),
              ]),
              GestureDetector(
                  onTap: _cancelCall,
                  child: Container(
                      height: 85,
                      width: 85,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.redAccent.withOpacity(0.2),
                          border:
                              Border.all(color: Colors.redAccent, width: 2)),
                      child: const Icon(Icons.call_end,
                          color: Colors.redAccent, size: 36))),
            ])),
      ]),
    );
  }
}
