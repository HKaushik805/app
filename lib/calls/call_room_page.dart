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
    // Start the launch process
    _launchJitsiCall();
  }

  String _sanitizeId(String id) {
    return id.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
  }

  Future<void> _launchJitsiCall() async {
    final String cleanId = _sanitizeId(widget.callId);
    final String userName = currentUser?.displayName ?? "GrindUser";

    // --- THE ULTIMATE BYPASS & REDIRECT URL ---
    // #config.prejoinPageEnabled=false -> Skips the 'Check Camera' screen
    // &userInfo.displayName -> Sets name automatically
    // &config.disableDeepLinking=true -> Prevents "Open in App" popups on mobile browsers
    final String jitsiUrl = "https://meet.jit.si/GrindChat_$cleanId"
        "#config.prejoinPageEnabled=false"
        "&config.disableDeepLinking=true"
        "&userInfo.displayName=\"$userName\"";

    final Uri url = Uri.parse(jitsiUrl);

    try {
      if (await canLaunchUrl(url)) {
        // --- ARCHITECTURAL DECISION: Use _blank for Web State Persistence ---
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      debugPrint("Call Launch Error: $e");
    }

    // IMMEDIATELY pop this page so the user is back on their previous screen
    // (Chat or Calls) in the background while the call happens in the new tab.
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFF00D2FF)),
            SizedBox(height: 25),
            Text("LAUNCHING SECURE CALL...",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2)),
          ],
        ),
      ),
    );
  }
}
