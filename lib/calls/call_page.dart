import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../widgets/grind_avatar.dart';
import '../widgets/permission_helper.dart';
import 'outgoing_call_screen.dart';

class CallPage extends StatefulWidget {
  const CallPage({super.key});

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  final currentUser = FirebaseAuth.instance.currentUser;
  bool _isInitiating = false;

  // --- LOGIC: ONE-TAP CALLBACK ---
  void _initiateCallFromHistory(Map<String, dynamic> data) async {
    String targetId = data['otherUserId'] ?? "";
    String targetName = data['otherUserName'] ?? "User";
    String targetPic = data['otherUserPic'] ?? "";
    String callType = data['type'] ?? "audio";

    if (targetId.isEmpty || targetId == "unknown") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cannot call this user ID.")),
      );
      return;
    }

    // 1. Permissions Check
    bool hasPermission = await PermissionHelper.checkCallPermissions(
      context,
      callType == "video",
    );
    if (!hasPermission) return;

    // 2. Show "Dialing..." UI state
    setState(() => _isInitiating = true);
    HapticFeedback.mediumImpact();

    try {
      // 3. Get my data for the receiver's screen
      final mySnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get();
      final myData = mySnap.data() as Map<String, dynamic>;

      // 4. Create the call document
      DocumentReference callRef = await FirebaseFirestore.instance
          .collection('calls')
          .add({
            'callerId': currentUser!.uid,
            'callerName': myData['name'] ?? "Someone",
            'callerPic': myData['profilePic'] ?? "",
            'receiverId': targetId,
            'status': 'dialing',
            'type': callType,
            'timestamp': FieldValue.serverTimestamp(),
          });

      // 5. Navigate to Outgoing Screen
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OutgoingCallScreen(
              receiverName: targetName,
              receiverPic: targetPic,
              callId: callRef.id,
              type: callType,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("Call Init Error: $e");
    } finally {
      if (mounted) setState(() => _isInitiating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFF0D0D0D),
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAppBar(),
                _buildNewCallBtn(),
                const Padding(
                  padding: EdgeInsets.only(left: 16, top: 10, bottom: 10),
                  child: Text(
                    "RECENT CALLS",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(currentUser?.uid)
                        .collection('call_history')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF8E2DE2),
                          ),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Text(
                            "No call history yet",
                            style: TextStyle(color: Colors.grey),
                          ),
                        );
                      }

                      return ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          var data =
                              snapshot.data!.docs[index].data()
                                  as Map<String, dynamic>;
                          return _buildCallTile(data);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        // --- DIALING OVERLAY ---
        if (_isInitiating)
          Container(
            color: Colors.black.withOpacity(0.8),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: Color(0xFF00D2FF)),
                  const SizedBox(height: 20),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFFD633FF), Color(0xFF00D2FF)],
                    ).createShader(bounds),
                    child: const Text(
                      "DIALING...",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCallTile(Map<String, dynamic> data) {
    String name = data['otherUserName'] ?? "Unknown";
    String pic = data['otherUserPic'] ?? "";
    String status = data['status'] ?? "";
    String direction = data['direction'] ?? "";
    String type = data['type'] ?? "audio";

    DateTime dt = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
    String time = DateFormat('hh:mm a').format(dt);

    IconData statusIcon;
    Color iconColor;

    if (status == 'accepted') {
      statusIcon = direction == 'outgoing'
          ? Icons.call_made
          : Icons.call_received;
      iconColor = Colors.greenAccent;
    } else {
      statusIcon = Icons.call_missed;
      iconColor = Colors.redAccent;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _initiateCallFromHistory(data), // ONE-TAP TRIGGER
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF161616),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.02)),
          ),
          child: Row(
            children: [
              GrindAvatar(imageUrl: pic, radius: 28, name: name),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        if (type == "video") const SizedBox(width: 5),
                        if (type == "video")
                          const Icon(
                            Icons.videocam_outlined,
                            color: Color(0xFF8E2DE2),
                            size: 16,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(statusIcon, color: iconColor, size: 14),
                        const SizedBox(width: 5),
                        Text(
                          "${status.toUpperCase()}  •  $time",
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.keyboard_arrow_right, color: Colors.white10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() => Padding(
    padding: const EdgeInsets.all(16),
    child: Row(
      children: [
        const Text(
          "Calls",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        const Spacer(),
        const Icon(Icons.search, color: Colors.white),
      ],
    ),
  );

  Widget _buildNewCallBtn() => Padding(
    padding: const EdgeInsets.all(16.0),
    child: Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: const LinearGradient(
          colors: [Color(0xFF8E2DE2), Color(0xFF00D2FF)],
        ),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_call, color: Colors.white),
          SizedBox(width: 10),
          Text(
            "New Call",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    ),
  );
}
