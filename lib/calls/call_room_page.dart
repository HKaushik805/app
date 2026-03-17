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
  // --- CONFIG: ENSURE THIS IS YOUR LONG AGORA APP ID ---
  final String appId = "d73cadd00815435b96fbb42d9e7fdaed";

  late RtcEngine _engine;
  bool _localUserJoined = false;
  int? _remoteUid;
  bool _isMuted = false;
  bool _isSpeaker = true;
  String _debugStatus = "Waiting for Engine...";

  Timer? _timer;
  int _startSeconds = 0;
  String _timerText = "00:00";

  @override
  void initState() {
    super.initState();
    // Start with a small delay to allow the Page transition to finish
    Future.delayed(const Duration(seconds: 1), () {
      initAgora();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _engine.leaveChannel();
    _engine.release();
    super.dispose();
  }

  // --- LOGIC: INITIALIZE AGORA SAFELY ---
  Future<void> initAgora() async {
    try {
      _engine = createAgoraRtcEngine();

      // Initialize with Communication profile for better Web stability
      await _engine.initialize(
        RtcEngineContext(
          appId: appId,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );

      _engine.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            if (mounted) {
              setState(() {
                _localUserJoined = true;
                _debugStatus = "Joined Room";
              });
              _startTimer();
            }
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            if (mounted) {
              setState(() {
                _remoteUid = remoteUid;
                _debugStatus = "Partner Connected";
              });
            }
          },
          onUserOffline:
              (
                RtcConnection connection,
                int remoteUid,
                UserOfflineReasonType reason,
              ) {
                _endCall();
              },
          onError: (err, msg) {
            if (mounted) setState(() => _debugStatus = "Engine Error: $err");
            debugPrint("AGORA ERROR: $err - $msg");
          },
        ),
      );

      if (widget.isVideo) {
        await _engine.enableVideo();
        await _engine.startPreview();
      } else {
        await _engine.enableAudio();
      }

      // Join Channel (Token "" works only if App Certificate is DISABLED)
      await _engine.joinChannel(
        token: "",
        channelId: widget.channelName,
        uid: 0,
        options: const ChannelMediaOptions(
          publishCameraTrack: true,
          publishMicrophoneTrack: true,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          autoSubscribeAudio: true,
          autoSubscribeVideo: true,
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _debugStatus = "Retry: JS Not Ready");
      debugPrint("AGORA SETUP EXCEPTION: $e");

      // If JS is not ready, try again in 2 seconds (common on Web)
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && !_localUserJoined) initAgora();
      });
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
          // 1. REMOTE STREAM
          Center(child: _remoteVideo()),

          // 2. LOCAL PREVIEW
          if (widget.isVideo && _localUserJoined)
            Positioned(
              right: 20,
              top: 50,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  width: 120,
                  height: 180,
                  color: Colors.black,
                  child: AgoraVideoView(
                    controller: VideoViewController(
                      rtcEngine: _engine,
                      canvas: const VideoCanvas(uid: 0),
                    ),
                  ),
                ),
              ),
            ),

          // 3. TOP UI (Timer & Status)
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
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.circle,
                        size: 8,
                        color: _remoteUid == null
                            ? Colors.orange
                            : Colors.greenAccent,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _debugStatus,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 4. CALL CONTROLS
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
            "Audio Connection Active",
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      );
    }
    return const Center(
      child: Text(
        "Connecting to secure server...",
        style: TextStyle(color: Colors.white24),
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
        height: isLarge ? 85 : 65,
        width: isLarge ? 85 : 65,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color ?? (active ? Colors.white : Colors.white10),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Icon(
          icon,
          color: active ? Colors.black : Colors.white,
          size: isLarge ? 38 : 28,
        ),
      ),
    );
  }
}
