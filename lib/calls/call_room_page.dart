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
  @override
  void initState() {
    super.initState();
    _launchJitsiCall();
  }

  // --- ARCHITECTURAL FIX: URL SANITATION ---
  String _sanitizeId(String id) {
    // Removes underscores and special characters to prevent URL breaking in browsers
    return id.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
  }

  Future<void> _launchJitsiCall() async {
    final String cleanId = _sanitizeId(widget.callId);
    final String jitsiUrl = "https://meet.jit.si/GrindChat_$cleanId";
    final Uri url = Uri.parse(jitsiUrl);

    try {
      if (await canLaunchUrl(url)) {
        // Launches in a separate browser process for stability
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint("System Error: Could not launch video process - $e");
    }

    // Return to app home instantly
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
            CircularProgressIndicator(color: Color(0xFF8E2DE2)),
            SizedBox(height: 25),
            Text("HANDSHAKING SECURE LINK...",
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
