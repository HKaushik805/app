import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CallRoomPage extends StatefulWidget {
  final String callId;
  final String channelName;
  const CallRoomPage(
      {super.key, required this.callId, required this.channelName});

  @override
  State<CallRoomPage> createState() => _CallRoomPageState();
}

class _CallRoomPageState extends State<CallRoomPage> {
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _launchExternalCall();
  }

  Future<void> _launchExternalCall() async {
    // 1. Fetch user name for Jitsi
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser?.uid)
        .get();
    final String userName = userDoc.data()?['name'] ?? "GrindUser";

    // 2. Build the sanitized secure room name
    final String roomName =
        "GrindChat_${widget.callId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')}";

    // 3. THE FAIL-PROOF URL (Uses an open community node)
    final String jitsiUrl = "https://meet.jit.si/$roomName"
        "#config.prejoinPageEnabled=false"
        "&config.disableDeepLinking=true"
        "&userInfo.displayName=\"$userName\"";

    final Uri url = Uri.parse(jitsiUrl);

    try {
      // 4. LAUNCH IN NEW TAB (Bypasses IFrame 'Refused to Connect' errors)
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint("External Launch Error: $e");
    }

    // 5. REDIRECT BACK: Pop this bridge page immediately
    // This leaves the user on their previous app screen while the call happens in the next tab
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Color(0xFF8E2DE2)),
            const SizedBox(height: 30),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFFD633FF), Color(0xFF00D2FF)])
                  .createShader(bounds),
              child: const Text("HANDSHAKING SECURE LINK...",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      fontSize: 10)),
            ),
            const SizedBox(height: 10),
            const Text("Your video session is opening in a new tab",
                style: TextStyle(color: Colors.white24, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
