import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

class CallRoomPage extends StatelessWidget {
  final String callId;
  final String channelName;
  final bool isVideo;

  const CallRoomPage({
    super.key,
    required this.callId,
    required this.channelName,
    required this.isVideo,
  });

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    // --- CONFIG: YOUR ZEGO APP ID & SIGN ---
    const int appId = 2049444418;
    const String appSign =
        "3075064bd76a9dc625b76963d41fc289de44242a2634f53cbb8307420301a71b";

    // Generate safe IDs for the Zego Engine
    String userId =
        currentUser?.uid ?? "user_${DateTime.now().millisecondsSinceEpoch}";
    String userName =
        currentUser?.displayName ?? "User_${userId.substring(0, 4)}";

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: ZegoUIKitPrebuiltCall(
          appID: appId,
          appSign: appSign,
          userID: userId,
          userName: userName,
          callID: channelName,

          // --- CONFIG FOR UI ---
          config: isVideo
              ? ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
              : ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall(),

          // --- EVENT HANDLING (Fixed for Version 4.17.13) ---
          events: ZegoUIKitPrebuiltCallEvents(
            onCallEnd: (ZegoCallEndEvent event, defaultAction) {
              // This triggers when the call is ended by either user
              Navigator.pop(context);
            },
          ),
        ),
      ),
    );
  }
}
