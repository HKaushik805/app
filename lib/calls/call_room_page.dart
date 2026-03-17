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
  // --- CONFIG: ENSURE THIS IS YOUR AGORA APP ID ---
  final String appId = "PASTE_YOUR_AGORA_APP_ID_HERE";

  RtcEngine? _engine; // Nullable to prevent calling before init
  bool _localUserJoined = false;
  int? _remoteUid;
  bool _isMuted = false;
  bool _isSpeaker = true;
  String _debugStatus = "Connecting...";

  Timer? _timer;
  int _startSeconds = 0;
  String _timerText = "00:00";

  @override
  void initState() {
    super.initState();
    // Wait for the UI to settle before starting the heavy engine
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initAgora();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stopAgora();
    super.dispose();
  }

  Future<void> _stopAgora() async {
    if (_engine != null) {
      await _engine!.leaveChannel();
      await _engine!.release();
    }
  }

  // --- LOGIC: SAFE INITIALIZATION ---
  Future<void> initAgora() async {
    // 1. Safety check to prevent crashing if the user navigates back quickly
    if (!mounted) return;

    try {
      _engine = createAgoraRtcEngine();

      await _engine!.initialize(
        RtcEngineContext(
          appId: appId,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );

      _engine!.registerEventHandler(
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
            debugPrint("AGORA ERROR: $err - $msg");
            if (mounted) setState(() => _debugStatus = "Error: $err");
          },
        ),
      );

      if (widget.isVideo) {
        await _engine!.enableVideo();
        await _engine!.startPreview();
      } else {
        await _engine!.enableAudio();
      }

      await _engine!.joinChannel(
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
      debugPrint("AGORA SETUP EXCEPTION: $e");

      // If error is "Iris" related (JS not ready), retry once after a delay
      if (e.toString().contains("undefined") ||
          e.toString().contains("createIris")) {
        if (mounted) setState(() => _debugStatus = "Retrying engine...");
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) initAgora();
      } else {
        if (mounted) setState(() => _debugStatus = "Setup Failed");
      }
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
          if (widget.isVideo && _localUserJoined && _engine != null)
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
                      rtcEngine: _engine!,
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
                    _engine?.muteLocalAudioStream(_isMuted);
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
                    _engine?.setEnableSpeakerphone(_isSpeaker);
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
    if (_remoteUid != null && widget.isVideo && _engine != null) {
      return AgoraVideoView(
        controller: VideoViewController(
          rtcEngine: _engine!,
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
      child: Text("Connecting...", style: TextStyle(color: Colors.white24)),
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
