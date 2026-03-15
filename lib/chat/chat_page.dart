import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../widgets/grind_avatar.dart';
import 'chat_detail_page.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAppBar(currentUser),
            const Padding(
              padding: EdgeInsets.only(left: 16, top: 20, bottom: 10),
              child: Text(
                "RECENT CHATS",
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
                    .collection('recent_chats')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting)
                    return const Center(child: CircularProgressIndicator());
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                    return const Center(
                      child: Text(
                        "No messages yet",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    );

                  return ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var chatData =
                          snapshot.data!.docs[index].data()
                              as Map<String, dynamic>;
                      String partnerId = snapshot.data!.docs[index].id;
                      String time = chatData['timestamp'] != null
                          ? DateFormat('hh:mm a').format(
                              (chatData['timestamp'] as Timestamp).toDate(),
                            )
                          : "";

                      return ChatTile(
                        name: chatData['name'] ?? 'User',
                        msg: chatData['lastMessage'] ?? '',
                        time: time,
                        receiverId: partnerId,
                        profilePic: chatData['profilePic'] ?? '',
                        unreadCount: chatData['unreadCount'] ?? 0,
                        status: chatData['status'] ?? "OFFLINE",
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(User? user) => StreamBuilder<DocumentSnapshot>(
    stream: FirebaseFirestore.instance
        .collection('users')
        .doc(user?.uid)
        .snapshots(),
    builder: (context, snapshot) {
      String myPic = "";
      String myName = "User";
      String status = "GRINDING";
      if (snapshot.hasData && snapshot.data!.exists) {
        var d = snapshot.data!.data() as Map<String, dynamic>;
        myPic = d['profilePic'] ?? "";
        myName = d['name'] ?? "User";
        status = d['status'] ?? "GRINDING";
      }
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            GrindAvatar(imageUrl: myPic, radius: 20, name: myName),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Messages",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                  Text(
                    "● $status",
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const Icon(Icons.search, color: Colors.white),
          ],
        ),
      );
    },
  );
}

class ChatTile extends StatefulWidget {
  final String name, msg, time, receiverId, profilePic, status;
  final int unreadCount;
  const ChatTile({
    super.key,
    required this.name,
    required this.msg,
    required this.time,
    required this.receiverId,
    required this.profilePic,
    required this.unreadCount,
    required this.status,
  });
  @override
  State<ChatTile> createState() => _ChatTileState();
}

class _ChatTileState extends State<ChatTile> {
  bool _isHovered = false;
  Color _getStatusColor(String s) {
    if (s == "ONLINE") return Colors.green;
    if (s == "AWAY") return Colors.yellow;
    if (s == "GRINDING") return Colors.orange;
    if (s == "BUSY") return Colors.redAccent;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: _isHovered
                ? const Color(0xFF222222)
                : const Color(0xFF161616),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isHovered
                  ? const Color(0xFF8E2DE2).withOpacity(0.5)
                  : Colors.transparent,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (c) => ChatDetailPage(
                    receiverName: widget.name,
                    receiverId: widget.receiverId,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        GrindAvatar(
                          imageUrl: widget.profilePic,
                          radius: 28,
                          name: widget.name,
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _getStatusColor(widget.status),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.black, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            widget.msg,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          widget.time,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 5),
                        if (widget.unreadCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFFD633FF), Color(0xFF8E2DE2)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF8E2DE2,
                                  ).withOpacity(0.5),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Text(
                              widget.unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
