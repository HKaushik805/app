import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../widgets/grind_avatar.dart';
import '../widgets/permission_helper.dart';
import 'outgoing_call_screen.dart';

class CallPage extends StatefulWidget {
  final int activeTabIndex;
  const CallPage({super.key, required this.activeTabIndex});

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  final currentUser = FirebaseAuth.instance.currentUser;

  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  bool _isInitiating = false;

  @override
  void didUpdateWidget(covariant CallPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset search if user navigates away from the Call tab (Index 1)
    if (widget.activeTabIndex != 1 && _isSearching) {
      _closeSearch();
    }
  }

  void _closeSearch() {
    if (mounted) {
      setState(() {
        _isSearching = false;
        _searchController.clear();
        _searchQuery = "";
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _initiateCallFromHistory(Map<String, dynamic> data) async {
    // Defensive data extraction
    final String targetId = (data['otherUserId'] ?? "").toString();
    final String targetName = (data['otherUserName'] ?? "User").toString();
    final String targetPic = (data['otherUserPic'] ?? "").toString();
    final String callType = (data['type'] ?? "audio").toString();

    if (targetId.isEmpty || targetId == "unknown") return;

    bool hasPermission = await PermissionHelper.checkCallPermissions(
        context, callType == "video");
    if (!hasPermission) return;

    setState(() => _isInitiating = true);
    HapticFeedback.mediumImpact();

    try {
      final mySnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get();
      final myData = mySnap.data() as Map<String, dynamic>;

      DocumentReference callRef =
          await FirebaseFirestore.instance.collection('calls').add({
        'callerId': currentUser!.uid,
        'callerName': myData['name'] ?? "Someone",
        'callerPic': myData['profilePic'] ?? "",
        'receiverId': targetId,
        'status': 'dialing',
        'type': callType,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (c) => OutgoingCallScreen(
                    receiverName: targetName,
                    receiverPic: targetPic,
                    callId: callRef.id,
                    type: callType)));
      }
    } catch (e) {
      debugPrint("Call Error: $e");
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
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAppBar(),
                    if (!_isSearching) _buildNewCallBtn(),
                    Padding(
                      padding:
                          const EdgeInsets.only(left: 16, top: 10, bottom: 10),
                      child: Text(
                          _isSearching ? "SEARCH RESULTS" : "RECENT CALLS",
                          style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5)),
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
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator(
                                    color: Color(0xFF8E2DE2)));
                          }
                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return const Center(
                                child: Text("No call history yet",
                                    style: TextStyle(color: Colors.grey)));
                          }

                          // Filter logic with extra safety for Web
                          var docs = snapshot.data!.docs.where((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final name = (data['otherUserName'] ?? "")
                                .toString()
                                .toLowerCase();
                            if (_searchQuery.isEmpty) return true;
                            return name.contains(_searchQuery.toLowerCase());
                          }).toList();

                          if (docs.isEmpty && _isSearching) {
                            return const Center(
                                child: Text("No matches found",
                                    style: TextStyle(color: Colors.grey)));
                          }

                          return ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            itemCount: docs.length,
                            itemBuilder: (context, index) {
                              final data =
                                  docs[index].data() as Map<String, dynamic>;
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
          ),
        ),
        if (_isInitiating) _buildDialingOverlay(),
      ],
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
      child: Row(children: [
        if (!_isSearching) ...[
          const Text("Calls",
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 22)),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () => setState(() => _isSearching = true),
          ),
        ] else ...[
          Expanded(
              child: Container(
            height: 45,
            decoration: BoxDecoration(
                color: const Color(0xFF161616),
                borderRadius: BorderRadius.circular(15)),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                  hintText: "Search calls...",
                  hintStyle: const TextStyle(color: Colors.white10),
                  prefixIcon: const Icon(Icons.search,
                      color: Color(0xFF00D2FF), size: 20),
                  suffixIcon: IconButton(
                      icon:
                          const Icon(Icons.close, color: Colors.grey, size: 20),
                      onPressed: _closeSearch),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10)),
            ),
          )),
        ],
      ]),
    );
  }

  Widget _buildCallTile(Map<String, dynamic> data) {
    // Robust null-checking to prevent 'isNotEmpty' JS errors
    final String name = (data['otherUserName'] ?? "Unknown").toString();
    final String pic = (data['otherUserPic'] ?? "").toString();
    final String status = (data['status'] ?? "ended").toString();
    final String direction = (data['direction'] ?? "incoming").toString();
    final String type = (data['type'] ?? "audio").toString();

    DateTime dt = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
    String time = DateFormat('hh:mm a').format(dt);

    IconData statusIcon = status == 'accepted'
        ? (direction == 'outgoing' ? Icons.call_made : Icons.call_received)
        : Icons.call_missed;
    Color iconColor =
        status == 'accepted' ? Colors.greenAccent : Colors.redAccent;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _initiateCallFromHistory(data),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: const Color(0xFF161616),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.02))),
          child: Row(children: [
            GrindAvatar(imageUrl: pic, radius: 28, name: name),
            const SizedBox(width: 15),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Row(children: [
                    Text(name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                    if (type == "video") ...[
                      const SizedBox(width: 5),
                      const Icon(Icons.videocam_outlined,
                          color: Color(0xFF8E2DE2), size: 16)
                    ]
                  ]),
                  Row(children: [
                    Icon(statusIcon, color: iconColor, size: 14),
                    const SizedBox(width: 5),
                    Text("${status.toUpperCase()}  •  $time",
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 11))
                  ]),
                ])),
            const Icon(Icons.keyboard_arrow_right, color: Colors.white10),
          ]),
        ),
      ),
    );
  }

  Widget _buildDialingOverlay() => Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        const CircularProgressIndicator(color: Color(0xFF00D2FF)),
        const SizedBox(height: 20),
        ShaderMask(
            shaderCallback: (b) => const LinearGradient(
                colors: [Color(0xFFD633FF), Color(0xFF8E2DE2)]).createShader(b),
            child: const Text("DIALING...",
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2)))
      ])));

  Widget _buildNewCallBtn() => Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
          width: double.infinity,
          height: 55,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              gradient: const LinearGradient(
                  colors: [Color(0xFF8E2DE2), Color(0xFF00D2FF)])),
          child:
              const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.add_call, color: Colors.white),
            SizedBox(width: 10),
            Text("New Call",
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
          ])));
}
