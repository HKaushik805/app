import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CallRoomPage extends StatefulWidget {
  final String callId;
  final String channelName; // The unique room name (we'll use callId)
  final bool isVideo;

  const CallRoomPage({
    super.key,
    required this.callId,
    required this.channelName,
    required this.isVideo,
  });

  @override
  State<CallRoomPage> createState() => _CallRoomPageState();
}

class _CallRoomPageState extends State<CallRoomPage> {
  // --- CONFIG ---
  final String appId = "YOUR_AGORA_APP_ID"; // <--- PASTE YOUR APP ID HERE

  late RtcEngine _engine;
  bool _localUserJoined = false;
  int? _remoteUid;
  bool _isMuted = false;
  bool _isSpeaker = true;

  // Timer Variables
  Timer? _timer;
  int _startSeconds = 0;
  String _timerText = "00:00";

  @override
  void initState() {
    super.initState();
    initAgora();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _engine.leaveChannel();
    _engine.release();
    super.dispose();
  }

  // --- LOGIC: AGORA INITIALIZATION ---
  Future<void> initAgora() async {
    // 1. Create the engine
    _engine = createAgoraRtcEngine();
    await _engine.initialize(RtcEngineContext(appId: appId));

    // 2. Setup Handlers
    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint("Local user joined");
          setState(() => _localUserJoined = true);
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint("Remote user joined");
          setState(() => _remoteUid = remoteUid);
          _startTimer(); // Start timer when second person joins
        },
        onUserOffline:
            (
              RtcConnection connection,
              int remoteUid,
              UserOfflineReasonType reason,
            ) {
              debugPrint("Remote user left");
              _endCall();
            },
      ),
    );

    if (widget.isVideo) {
      await _engine.enableVideo();
      await _engine.startPreview();
    } else {
      await _engine.enableAudio();
    }

    // 3. Join the Channel (Token is NULL because we are in Testing Mode)
    await _engine.joinChannel(
      token: "",
      channelId: widget.channelName,
      uid: 0,
      options: const ChannelMediaOptions(),
    );
  }

  // --- LOGIC: CALL TIMER ---
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _startSeconds++;
        int min = _startSeconds ~/ 60;
        int sec = _startSeconds % 60;
        _timerText =
            "${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}";
      });
    });
  }

  Future<void> _endCall() async {
    HapticFeedback.heavyImpact();
    await FirebaseFirestore.instance
        .collection('calls')
        .doc(widget.callId)
        .update({'status': 'ended'});
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. VIDEO VIEW (Full Screen for Remote, Small for Local)
          Center(child: _remoteVideo()),
          if (widget.isVideo)
            Positioned(
              right: 20,
              top: 50,
              child: SizedBox(width: 120, height: 180, child: _localVideo()),
            ),

          // 2. TOP INFO (Timer)
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  _timerText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  "SECURE CONNECTION",
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 8,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),

          // 3. CONTROL PANEL
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _circleBtn(
                  icon: _isMuted ? Icons.mic_off : Icons.mic,
                  onTap: () {
                    setState(() => _isMuted = !_isMuted);
                    _engine.muteLocalAudioStream(_isMuted);
                  },
                  active: _isMuted,
                ),
                _circleBtn(
                  icon: Icons.call_end,
                  color: Colors.redAccent,
                  onTap: _endCall,
                  isLarge: true,
                ),
                _circleBtn(
                  icon: _isSpeaker ? Icons.volume_up : Icons.volume_down,
                  onTap: () {
                    setState(() => _isSpeaker = !_isSpeaker);
                    _engine.setEnableSpeakerphone(_isSpeaker);
                  },
                  active: _isSpeaker,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _localVideo() {
    if (_localUserJoined && widget.isVideo) {
      return AgoraVideoView(
        controller: VideoViewController(
          rtcEngine: _engine,
          canvas: const VideoCanvas(uid: 0),
        ),
      );
    }
    return Container(color: Colors.black45);
  }

  Widget _remoteVideo() {
    if (_remoteUid != null && widget.isVideo) {
      return AgoraVideoView(
        controller: VideoViewController(
          rtcEngine: _engine,
          canvas: VideoCanvas(uid: _remoteUid),
        ),
      );
    } else if (!widget.isVideo) {
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: Colors.white10,
            child: Icon(Icons.person, size: 60, color: Colors.white),
          ),
          SizedBox(height: 20),
          Text("Audio Call Active", style: TextStyle(color: Colors.white70)),
        ],
      );
    }
    return const Center(
      child: Text(
        "Waiting for partner...",
        style: TextStyle(color: Colors.grey),
      ),
    );
  }

  Widget _circleBtn({
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
    bool active = false,
    bool isLarge = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: isLarge ? 80 : 60,
        width: isLarge ? 80 : 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color ?? (active ? Colors.white : Colors.white10),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Icon(
          icon,
          color: active
              ? Colors.black
              : (color != null ? Colors.white : Colors.white),
          size: isLarge ? 35 : 25,
        ),
      ),
    );
  }
}
