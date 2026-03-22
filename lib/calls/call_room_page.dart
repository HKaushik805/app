import 'dart:ui_web' as ui; // Modern 2026 Flutter Web API

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web; // Required for HTML IFrame elements

class CallRoomPage extends StatefulWidget {
  final String callId;
  final String channelName;
  const CallRoomPage(
      {super.key, required this.callId, required this.channelName});

  @override
  State<CallRoomPage> createState() => _CallRoomPageState();
}

class _CallRoomPageState extends State<CallRoomPage> {
  final String viewID = "grind-chat-iframe";
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _registerIFrame();
  }

  void _registerIFrame() {
    final String roomName =
        "GrindChat_${widget.callId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')}";
    final String userName = currentUser?.displayName ?? "GrindUser";

    // --- THE FAIL-PROOF PROFESSIONAL URL (Bypasses Login) ---
    final String jitsiUrl =
        "https://8x8.vc/vpaas-magic-cookie-3075064bd76a9dc625b76963d41fc289de44242a2634f53cbb8307420301a71b/$roomName"
        "#config.prejoinPageEnabled=false"
        "&config.disableDeepLinking=true"
        "&config.hideLogo=true"
        "&userInfo.displayName=\"$userName\"";

    // Registering the view for Flutter Web
    ui.platformViewRegistry.registerViewFactory(viewID, (int viewId) {
      final iframe = web.HTMLIFrameElement()
        ..src = jitsiUrl
        ..style.border = 'none'
        ..width = '100%'
        ..height = '100%'
        ..allow =
            "camera; microphone; display-capture; autoplay; clipboard-write";
      return iframe;
    });
  }

  Future<void> _terminateCall() async {
    // 1. Update database status
    await FirebaseFirestore.instance
        .collection('calls')
        .doc(widget.callId)
        .update({'status': 'ended'});

    // 2. Return to the previous page (Chat or Contacts)
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF161616),
        elevation: 0,
        centerTitle: true,
        title: const Text("SECURE ENCRYPTED LINE",
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
                letterSpacing: 2)),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.redAccent),
          onPressed: _terminateCall, // Standard "Cut Call" logic
        ),
      ),
      body: HtmlElementView(viewType: viewID),
    );
  }
}
