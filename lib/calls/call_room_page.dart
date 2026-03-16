import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CallRoomPage extends StatefulWidget {
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
  State<CallRoomPage> createState() => _CallRoomPageState();
}

class _CallRoomPageState extends State<CallRoomPage> {
  // --- CONFIG: ENSURE THIS MATCHES YOUR AGORA CONSOLE ---
  final String appId =
      "d73cadd00815435b96fbb42d9e7fdaed"; // <--- DOUBLE CHECK THIS APP ID

  late RtcEngine _engine;
  bool _localUserJoined = false;
  int? _remoteUid;
  bool _isMuted = false;
  bool _isSpeaker = true;

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

  Future<void> initAgora() async {
    try {
      _engine = createAgoraRtcEngine();
      await _engine.initialize(
        RtcEngineContext(
          appId: appId,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );

      _engine.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            debugPrint("LOG: Local user ${connection.localUid} joined");
            setState(() {
              _localUserJoined = true;
            });
            _startTimer(); // Start timer as soon as YOU join
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            debugPrint("LOG: Remote user $remoteUid joined");
            setState(() => _remoteUid = remoteUid);
          },
          onUserOffline:
              (
                RtcConnection connection,
                int remoteUid,
                UserOfflineReasonType reason,
              ) {
                debugPrint("LOG: Remote user $remoteUid left");
                _endCall();
              },
          onError: (err, msg) {
            debugPrint("LOG: Agora Error: $err - $msg");
          },
        ),
      );

      if (widget.isVideo) {
        await _engine.enableVideo();
        await _engine.startPreview();
      } else {
        await _engine.enableAudio();
      }

      // Join with empty token (Only works if project is in "Testing Mode" in Agora Console)
      await _engine.joinChannel(
        token: "",
        channelId: widget.channelName,
        uid: 0,
        options: const ChannelMediaOptions(
          publishCameraTrack: true,
          publishMicrophoneTrack: true,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
        ),
      );
    } catch (e) {
      debugPrint("LOG: Initialization Error: $e");
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _startSeconds++;
          int min = _startSeconds ~/ 60;
          int sec = _startSeconds % 60;
          _timerText =
              "${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}";
        });
      }
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
          // 1. MAIN VIEW
          Center(child: _remoteVideo()),

          // 2. LOCAL PREVIEW (Floating)
          if (widget.isVideo)
            Positioned(
              right: 20,
              top: 50,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: SizedBox(width: 120, height: 180, child: _localVideo()),
              ),
            ),

          // 3. TIMER & STATUS
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
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock, color: Colors.greenAccent, size: 10),
                    const SizedBox(width: 5),
                    Text(
                      _remoteUid == null ? "WAITING..." : "CONNECTED",
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 4. CONTROLS
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
    return Container(
      color: Colors.white10,
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
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
          Text(
            "Audio Call Active",
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      );
    }
    return const Center(
      child: Text(
        "Connecting to room...",
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
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Icon(
          icon,
          color: active ? Colors.black : Colors.white,
          size: isLarge ? 35 : 25,
        ),
      ),
    );
  }
}
