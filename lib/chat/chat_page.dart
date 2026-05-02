import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../widgets/grind_avatar.dart';
import 'chat_detail_page.dart';

class ChatPage extends StatefulWidget {
  final int activeTabIndex;
  const ChatPage({super.key, required this.activeTabIndex});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final currentUser = FirebaseAuth.instance.currentUser;

  // --- SEARCH STATE ---
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void didUpdateWidget(covariant ChatPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the tab index changed and it's no longer THIS page (index 0), reset search UI
    if (widget.activeTabIndex != 0 && _isSearching) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- DYNAMIC APP BAR ---
            _buildAppBar(),

            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 20, bottom: 10),
              child: Text(_isSearching ? "SEARCH RESULTS" : "RECENT CHATS",
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
                    .collection('recent_chats')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFF8E2DE2)));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                        child: Text("No messages yet",
                            style:
                                TextStyle(color: Colors.grey, fontSize: 12)));
                  }

                  // Defensive local filtering for Web stability
                  var docs = snapshot.data!.docs;

                  if (_searchQuery.isNotEmpty) {
                    docs = docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final String name =
                          (data['name'] ?? "").toString().toLowerCase();
                      return name.contains(_searchQuery.toLowerCase());
                    }).toList();
                  }

                  if (docs.isEmpty && _isSearching) {
                    return const Center(
                        child: Text("No matches found",
                            style: TextStyle(color: Colors.grey)));
                  }

                  return ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final chatData =
                          docs[index].data() as Map<String, dynamic>;
                      final String partnerId = docs[index].id;

                      // Safely handle timestamp for Web
                      String time = "";
                      if (chatData['timestamp'] != null) {
                        try {
                          final dt =
                              (chatData['timestamp'] as Timestamp).toDate();
                          time = DateFormat('hh:mm a').format(dt);
                        } catch (e) {
                          time = "Just now";
                        }
                      }

                      return ChatTile(
                        name: (chatData['name'] ?? "User").toString(),
                        msg: (chatData['lastMessage'] ?? "").toString(),
                        time: time,
                        receiverId: partnerId,
                        profilePic: (chatData['profilePic'] ?? "").toString(),
                        unreadCount:
                            (chatData['unreadCount'] as num? ?? 0).toInt(),
                        status: (chatData['status'] ?? "OFFLINE").toString(),
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

  Widget _buildAppBar() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        String myPic = "";
        String myName = "User";
        if (snapshot.hasData && snapshot.data!.exists) {
          final d = snapshot.data!.data() as Map<String, dynamic>;
          myPic = (d['profilePic'] ?? "").toString();
          myName = (d['name'] ?? "User").toString();
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
          child: Row(
            children: [
              if (!_isSearching) ...[
                GrindAvatar(imageUrl: myPic, radius: 20, name: myName),
                const SizedBox(width: 12),
                const Text("Messages",
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
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: TextField(
                      controller: _searchController,
                      autofocus: true, // Fixed lowercase naming
                      style: const TextStyle(color: Colors.white),
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: "Search conversations...",
                        hintStyle: const TextStyle(color: Colors.white10),
                        prefixIcon: const Icon(Icons.search,
                            color: Color(0xFF00D2FF), size: 20),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.close,
                              color: Colors.grey, size: 20),
                          onPressed: _closeSearch,
                        ),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class ChatTile extends StatefulWidget {
  final String name, msg, time, receiverId, profilePic, status;
  final int unreadCount;
  const ChatTile(
      {super.key,
      required this.name,
      required this.msg,
      required this.time,
      required this.receiverId,
      required this.profilePic,
      required this.unreadCount,
      required this.status});

  @override
  State<ChatTile> createState() => _ChatTileState();
}

class _ChatTileState extends State<ChatTile> {
  bool _isHovered = false;

  Color _getStatusColor(String s) {
    if (s == "ONLINE") return Colors.green;
    if (s == "AWAY") return Colors.yellow;
    if (s == "GRINDING") return Colors.orange;
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
                      : Colors.transparent)),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                // FIXED: Clean step-by-step logic for Chat ID to prevent 'void' and 'List' errors
                final String myUid = FirebaseAuth.instance.currentUser!.uid;
                final List<String> ids = [myUid, widget.receiverId];
                ids.sort();
                final String chatId = ids.join("_");

                // Pre-loading Cache logic
                FirebaseFirestore.instance
                    .collection('chats')
                    .doc(chatId)
                    .collection('messages')
                    .orderBy('timestamp', descending: true)
                    .limit(20)
                    .get();

                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (c) => ChatDetailPage(
                            receiverName: widget.name,
                            receiverId: widget.receiverId)));
              },
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        GrindAvatar(
                            imageUrl: widget.profilePic,
                            radius: 28,
                            name: widget.name),
                        Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                    color: _getStatusColor(widget.status),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.black, width: 2)))),
                      ],
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(widget.name,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15)),
                          const SizedBox(height: 4),
                          Text(widget.msg,
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ])),
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(widget.time,
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 11)),
                          const SizedBox(height: 5),
                          if (widget.unreadCount > 0)
                            Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(colors: [
                                      Color(0xFFD633FF),
                                      Color(0xFF8E2DE2)
                                    ]),
                                    boxShadow: [
                                      BoxShadow(
                                          color: const Color(0xFF8E2DE2)
                                              .withOpacity(0.5),
                                          blurRadius: 8)
                                    ]),
                                child: Text(widget.unreadCount.toString(),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold))),
                        ]),
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
