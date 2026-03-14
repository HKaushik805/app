import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

// Ensure this import matches your folder path
import '../contacts/contact_profile_page.dart';

class ChatDetailPage extends StatefulWidget {
  final String receiverName;
  final String receiverId;

  const ChatDetailPage({
    super.key,
    required this.receiverName,
    required this.receiverId,
  });

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  // --- LOGIC: UNIQUE CHAT ID ---
  String getChatId() {
    List<String> ids = [currentUserId, widget.receiverId];
    ids.sort();
    return ids.join("_");
  }

  // --- LOGIC: PICK MEDIA (PHOTO OR VIDEO) ---
  Future<void> _pickMedia(ImageSource source, bool isVideo) async {
    final picker = ImagePicker();
    XFile? file;

    if (isVideo) {
      file = await picker.pickVideo(
        source: source,
        maxDuration: const Duration(seconds: 10),
      );
    } else {
      file = await picker.pickImage(
        source: source,
        maxWidth: 400,
        imageQuality: 70,
      );
    }

    if (file == null) return;

    Uint8List bytes = await file.readAsBytes();

    // Safety Check for Firestore 1MB Limit
    if (bytes.lengthInBytes > 900000) {
      _showError(
        "File too large! Must be under 1MB for this card-free version.",
      );
      return;
    }

    String base64File = base64Encode(bytes);
    _saveMessageToFirestore(msg: base64File, type: isVideo ? 'video' : 'image');
  }

  // --- LOGIC: SAVE MESSAGE & UPDATE RECENT CHATS ---
  void _saveMessageToFirestore({
    required String msg,
    required String type,
  }) async {
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(getChatId())
        .collection('messages')
        .add({
          'senderId': currentUserId,
          'receiverId': widget.receiverId,
          'message': msg,
          'type': type,
          'timestamp': FieldValue.serverTimestamp(),
        });

    var summary = {
      'lastMessage': type == 'image'
          ? "📷 Photo"
          : (type == 'video' ? "🎥 Video" : msg),
      'timestamp': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('recent_chats')
        .doc(widget.receiverId)
        .set(summary);
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.receiverId)
        .collection('recent_chats')
        .doc(currentUserId)
        .set(summary);

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),

      // --- APP BAR (With Profile Navigation & Status Dot) ---
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(widget.receiverId)
              .snapshots(),
          builder: (context, snapshot) {
            String pPic = "";
            String status = "OFFLINE";
            if (snapshot.hasData && snapshot.data!.exists) {
              var data = snapshot.data!.data() as Map<String, dynamic>;
              pPic = data['profilePic'] ?? "";
              status = data['status'] ?? "OFFLINE";
            }

            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ContactProfilePage(
                      receiverId: widget.receiverId,
                      receiverName: widget.receiverName,
                    ),
                  ),
                );
              },
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.white12,
                        backgroundImage: pPic.isNotEmpty
                            ? MemoryImage(base64Decode(pPic))
                            : null,
                        child: pPic.isEmpty
                            ? const Icon(Icons.person, color: Colors.white)
                            : null,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _getStatusColor(status),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.receiverName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          status,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.phone_outlined, color: Colors.white),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert, color: Colors.white),
          ),
        ],
      ),

      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(getChatId())
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                var docs = snapshot.data!.docs;
                return ListView.builder(
                  reverse: true,
                  controller: _scrollController,
                  padding: const EdgeInsets.all(20),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    bool isMe = data['senderId'] == currentUserId;
                    String type = data['type'] ?? 'text';
                    String time = data['timestamp'] != null
                        ? DateFormat(
                            'hh:mm a',
                          ).format((data['timestamp'] as Timestamp).toDate())
                        : "";
                    return _buildMessageBubble(
                      data['message'],
                      isMe,
                      type,
                      time,
                    );
                  },
                );
              },
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
    String content,
    bool isMe,
    String type,
    String time,
  ) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: (type == 'image' || type == 'video')
                ? const EdgeInsets.all(5)
                : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            decoration: BoxDecoration(
              color: isMe ? null : const Color(0xFF1A1A1A),
              gradient: isMe
                  ? const LinearGradient(
                      colors: [Color(0xFF8E2DE2), Color(0xFF00D2FF)],
                    )
                  : null,
              borderRadius: BorderRadius.circular(20),
            ),
            child: type == 'image'
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.memory(
                      base64Decode(content),
                      fit: BoxFit.cover,
                    ),
                  )
                : type == 'video'
                ? _buildVideoPlaceholder()
                : Text(content, style: const TextStyle(color: Colors.white)),
          ),
          Text(
            time,
            style: const TextStyle(color: Colors.white24, fontSize: 10),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildVideoPlaceholder() {
    return Container(
      width: 200,
      height: 150,
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Center(
        child: Icon(Icons.play_circle_fill, color: Colors.white, size: 50),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 10,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _showMediaOptions(),
            child: Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[900],
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF161616),
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: "Type a message...",
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              if (_messageController.text.trim().isNotEmpty) {
                _saveMessageToFirestore(
                  msg: _messageController.text.trim(),
                  type: 'text',
                );
                _messageController.clear();
              }
            },
            child: Container(
              height: 48,
              width: 48,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF8E2DE2), Color(0xFF00D2FF)],
                ),
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMediaOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161616),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.image, color: Color(0xFF8E2DE2)),
            title: const Text("Send Photo"),
            onTap: () {
              Navigator.pop(context);
              _pickMedia(ImageSource.gallery, false);
            },
          ),
          ListTile(
            leading: const Icon(Icons.videocam, color: Color(0xFF00D2FF)),
            title: const Text("Send Video (Max 1MB)"),
            onTap: () {
              Navigator.pop(context);
              _pickMedia(ImageSource.gallery, true);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    if (status == "ONLINE") return Colors.green;
    if (status == "GRINDING") return Colors.orange;
    if (status == "AWAY") return Colors.yellow;
    return Colors.grey;
  }
}
