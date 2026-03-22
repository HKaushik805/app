import 'dart:convert';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../widgets/grind_avatar.dart';
import '../widgets/permission_helper.dart';
import 'call_history_manager.dart';
import 'call_room_page.dart';

class IncomingCallScreen extends StatefulWidget {
  final String callerName, callerPic, callId, type;
  const IncomingCallScreen(
      {super.key,
      required this.callerName,
      required this.callerPic,
      required this.callId,
      required this.type});

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> {
  final myId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _listenToStatus();
  }

  void _listenToStatus() {
    FirebaseFirestore.instance
        .collection('calls')
        .doc(widget.callId)
        .snapshots()
        .listen((snap) {
      if (!snap.exists ||
          snap.data()?['status'] == 'cancelled' ||
          snap.data()?['status'] == 'missed') {
        if (mounted) Navigator.pop(context);
      }
    });
  }

  Future<void> _handleAction(String action) async {
    final mySnap =
        await FirebaseFirestore.instance.collection('users').doc(myId).get();
    final myData = mySnap.data() as Map<String, dynamic>;

    if (action == 'accepted') {
      await FirebaseFirestore.instance
          .collection('calls')
          .doc(widget.callId)
          .update({'status': 'accepted'});
      if (mounted) {
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (c) => CallRoomPage(
                    callId: widget.callId, channelName: widget.callId)));
      }
    } else {
      await FirebaseFirestore.instance
          .collection('calls')
          .doc(widget.callId)
          .update({'status': action});
      await CallHistoryManager.logCall(
        callerId: widget.callId.split('_')[0],
        callerName: widget.callerName,
        callerPic: widget.callerPic,
        receiverId: myId,
        receiverName: myData['name'],
        receiverPic: myData['profilePic'] ?? "",
        type: widget.type,
        status: action,
      );
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        Container(
            decoration: BoxDecoration(
                image: widget.callerPic.startsWith('http')
                    ? DecorationImage(
                        image: NetworkImage(widget.callerPic),
                        fit: BoxFit.cover)
                    : (widget.callerPic.isNotEmpty
                        ? DecorationImage(
                            image: MemoryImage(base64Decode(widget.callerPic)),
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
                const Text("INCOMING CALL",
                    style: TextStyle(
                        color: Color(0xFF00D2FF),
                        letterSpacing: 4,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
                const SizedBox(height: 40),
                GrindAvatar(
                    imageUrl: widget.callerPic,
                    radius: 70,
                    name: widget.callerName),
                const SizedBox(height: 20),
                Text(widget.callerName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold)),
                Text("GrindChat ${widget.type.toUpperCase()}...",
                    style: const TextStyle(color: Colors.grey, fontSize: 14)),
              ]),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                _btn(Icons.call_end, Colors.redAccent, "Decline",
                    () => _handleAction('declined')),
                _btn(widget.type == "video" ? Icons.videocam : Icons.call,
                    Colors.greenAccent, "Accept", () async {
                  if (await PermissionHelper.checkCallPermissions(
                      context, widget.type == "video"))
                    _handleAction('accepted');
                }, glow: true),
              ]),
            ])),
      ]),
    );
  }

  Widget _btn(IconData i, Color c, String l, VoidCallback t,
          {bool glow = false}) =>
      Column(children: [
        GestureDetector(
            onTap: t,
            child: Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF161616),
                    border: Border.all(color: c.withOpacity(0.5), width: 2),
                    boxShadow: glow
                        ? [BoxShadow(color: c.withOpacity(0.4), blurRadius: 30)]
                        : []),
                child: Icon(i, color: c, size: 32))),
        const SizedBox(height: 12),
        Text(l, style: const TextStyle(color: Colors.white70, fontSize: 12))
      ]);
}
