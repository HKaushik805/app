import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../contacts/contact_profile_page.dart';
import '../main.dart';
import '../widgets/grind_avatar.dart';

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

  final String cloudName = "dke7bkleb";
  final String uploadPreset = "grind_preset";

  bool _isUploadingMedia = false;
  bool _isMeTyping = false;
  bool _showScrollButton = false;

  @override
  void initState() {
    super.initState();
    _markMessagesAsRead();
    _resetUnreadCount();
    _messageController.addListener(_onTextChanged);
    _scrollController.addListener(() {
      if (_scrollController.offset > 300 && !_showScrollButton) {
        setState(() => _showScrollButton = true);
      } else if (_scrollController.offset <= 300 && _showScrollButton) {
        setState(() => _showScrollButton = false);
      }
    });
  }

  @override
  void dispose() {
    _updateTypingStatus(false);
    messengerKey.currentState?.clearSnackBars();
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToLatest() {
    _scrollController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCirc,
    );
  }

  void _onTextChanged() {
    bool isCurrentlyTyping = _messageController.text.trim().isNotEmpty;
    if (isCurrentlyTyping != _isMeTyping) {
      _isMeTyping = isCurrentlyTyping;
      _updateTypingStatus(_isMeTyping);
    }
  }

  void _updateTypingStatus(bool isTyping) async {
    await FirebaseFirestore.instance.collection('chats').doc(getChatId()).set({
      'typingStatus': {currentUserId: isTyping},
    }, SetOptions(merge: true));
  }

  void _resetUnreadCount() {
    FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('recent_chats')
        .doc(widget.receiverId)
        .update({'unreadCount': 0})
        .catchError((e) => debugPrint("First chat"));
  }

  void _markMessagesAsRead() {
    FirebaseFirestore.instance
        .collection('chats')
        .doc(getChatId())
        .collection('messages')
        .where('receiverId', isEqualTo: currentUserId)
        .where('isRead', isEqualTo: false)
        .get()
        .then((snapshot) {
          for (var doc in snapshot.docs) {
            doc.reference.update({'isRead': true, 'isReceived': true});
          }
        });
  }

  String getChatId() {
    List<String> ids = [currentUserId, widget.receiverId];
    ids.sort();
    return ids.join("_");
  }

  void _handleSendAction() {
    String text = _messageController.text.trim();
    if (text.isNotEmpty) {
      HapticFeedback.lightImpact();
      _saveMsg(msg: text, type: 'text');
      _messageController.clear();
      _scrollToLatest();
    }
  }

  void _saveMsg({
    required String msg,
    required String type,
    String cloudinaryId = "",
  }) async {
    final mySnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .get();
    final partnerSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.receiverId)
        .get();

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(getChatId())
        .collection('messages')
        .add({
          'senderId': currentUserId,
          'receiverId': widget.receiverId,
          'message': msg,
          'cloudinary_id': cloudinaryId,
          'type': type,
          'timestamp': FieldValue.serverTimestamp(),
          'deletedBy': [],
          'isReceived': false,
          'isRead': false,
          'reactions': {}, // Initialize reactions
        });

    String displayMsg = type == 'image'
        ? "📷 Photo"
        : (type == 'video' ? "🎥 Video" : msg);
    var d = mySnap.data()!;
    var pd = partnerSnap.data()!;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('recent_chats')
        .doc(widget.receiverId)
        .set({
          'lastMessage': displayMsg,
          'timestamp': FieldValue.serverTimestamp(),
          'unreadCount': 0,
          'name': pd['name'],
          'profilePic': pd['profilePic'],
          'status': pd['status'] ?? "ONLINE",
        }, SetOptions(merge: true));

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.receiverId)
        .collection('recent_chats')
        .doc(currentUserId)
        .set({
          'lastMessage': displayMsg,
          'timestamp': FieldValue.serverTimestamp(),
          'unreadCount': FieldValue.increment(1),
          'name': d['name'],
          'profilePic': d['profilePic'],
          'status': d['status'] ?? "ONLINE",
        }, SetOptions(merge: true));
  }

  // --- LOGIC: REACTION UPDATE ---
  void _toggleReaction(
    String messageId,
    String emoji,
    Map existingReactions,
  ) async {
    HapticFeedback.heavyImpact();
    Map newReactions = Map.from(existingReactions);

    if (newReactions[currentUserId] == emoji) {
      newReactions.remove(currentUserId); // Remove if same emoji tapped
    } else {
      newReactions[currentUserId] = emoji; // Add/Update emoji
    }

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(getChatId())
        .collection('messages')
        .doc(messageId)
        .update({'reactions': newReactions});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(widget.receiverId)
              .snapshots(),
          builder: (context, userSnapshot) {
            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(getChatId())
                  .snapshots(),
              builder: (context, chatSnapshot) {
                String pPic = "";
                String status = "OFFLINE";
                bool isTyping = false;
                if (userSnapshot.hasData && userSnapshot.data!.exists) {
                  var d = userSnapshot.data!.data() as Map<String, dynamic>;
                  pPic = d['profilePic'] ?? "";
                  status = d['status'] ?? "OFFLINE";
                }
                if (chatSnapshot.hasData && chatSnapshot.data!.exists) {
                  var chatData =
                      chatSnapshot.data!.data() as Map<String, dynamic>;
                  Map typingMap = chatData['typingStatus'] ?? {};
                  isTyping = typingMap[widget.receiverId] ?? false;
                }
                return InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (c) => ContactProfilePage(
                        receiverId: widget.receiverId,
                        receiverName: widget.receiverName,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      GrindAvatar(
                        imageUrl: pPic,
                        radius: 20,
                        name: widget.receiverName,
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
                            isTyping
                                ? const BreathingTypingIndicator()
                                : Text(
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
      body: Stack(
        children: [
          Column(
            children: [
              if (_isUploadingMedia)
                const LinearProgressIndicator(
                  backgroundColor: Colors.transparent,
                  color: Color(0xFF00D2FF),
                ),
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
                    _markMessagesAsRead();
                    var docs = snapshot.data!.docs.where((doc) {
                      Map<String, dynamic> d =
                          doc.data() as Map<String, dynamic>;
                      return !(d.containsKey('deletedBy') &&
                          d['deletedBy'].contains(currentUserId));
                    }).toList();
                    return ListView.builder(
                      reverse: true,
                      controller: _scrollController,
                      padding: const EdgeInsets.all(20),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        var d = docs[index].data() as Map<String, dynamic>;
                        String msgId = docs[index].id;
                        bool isMe = d['senderId'] == currentUserId;
                        return ChatMessageBubble(
                          messageId: msgId,
                          content: d['message'],
                          isMe: isMe,
                          type: d['type'] ?? 'text',
                          time: d['timestamp'] != null
                              ? DateFormat(
                                  'hh:mm a',
                                ).format((d['timestamp'] as Timestamp).toDate())
                              : "",
                          isPending: docs[index].metadata.hasPendingWrites,
                          isRead: d['isRead'] ?? false,
                          isReceived: d['isReceived'] ?? false,
                          reactions: d['reactions'] ?? {},
                          onReact: (emoji) => _toggleReaction(
                            msgId,
                            emoji,
                            d['reactions'] ?? {},
                          ),
                          onLongPress: () => _showDeleteMenu(msgId),
                        );
                      },
                    );
                  },
                ),
              ),
              _buildInput(),
            ],
          ),
          if (_showScrollButton)
            Positioned(
              bottom: 100,
              right: 20,
              child: FloatingActionButton.small(
                onPressed: _scrollToLatest,
                backgroundColor: const Color(0xFF161616),
                child: const Icon(
                  Icons.arrow_downward,
                  color: Color(0xFF8E2DE2),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- DELETE MENU ---
  void _showDeleteMenu(String msgId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161616),
      builder: (c) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text("Delete for me"),
            onTap: () {
              Navigator.pop(c);
              _deleteForMe(msgId);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
            title: const Text("Delete for everyone"),
            onTap: () {
              Navigator.pop(c);
              _deleteForBoth(msgId);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _deleteForMe(String id) async {
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(getChatId())
        .collection('messages')
        .doc(id)
        .update({
          'deletedBy': FieldValue.arrayUnion([currentUserId]),
        });
    messengerKey.currentState?.showSnackBar(
      SnackBar(
        content: const Text("Deleted"),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: "Undo",
          onPressed: () => FirebaseFirestore.instance
              .collection('chats')
              .doc(getChatId())
              .collection('messages')
              .doc(id)
              .update({
                'deletedBy': FieldValue.arrayRemove([currentUserId]),
              }),
        ),
      ),
    );
  }

  void _deleteForBoth(String id) async {
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(getChatId())
        .collection('messages')
        .doc(id)
        .delete();
  }

  Widget _buildInput() => Container(
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
            child: const Icon(Icons.add, color: Colors.white),
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
              onSubmitted: (v) => _handleSendAction(),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "Message...",
                border: InputBorder.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: _handleSendAction,
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

  void _showMediaOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161616),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (c) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.image, color: Color(0xFF8E2DE2)),
            title: const Text("Send Photo"),
            onTap: () {
              Navigator.pop(c);
              _pickMedia(false);
            },
          ),
          ListTile(
            leading: const Icon(Icons.videocam, color: Color(0xFF00D2FF)),
            title: const Text("Send Video"),
            onTap: () {
              Navigator.pop(c);
              _pickMedia(true);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Future<void> _pickMedia(bool isV) async {
    final f = isV
        ? await ImagePicker().pickVideo(source: ImageSource.gallery)
        : await ImagePicker().pickImage(
            source: ImageSource.gallery,
            imageQuality: 80,
          );
    if (f == null) return;
    final m = await _uploadToCloudinary(File(f.path), isV);
    if (m != null)
      _saveMsg(
        msg: m['url']!,
        type: isV ? 'video' : 'image',
        cloudinaryId: m['public_id']!,
      );
  }

  Future<Map<String, String>?> _uploadToCloudinary(File f, bool v) async {
    setState(() => _isUploadingMedia = true);
    var url = Uri.parse(
      "https://api.cloudinary.com/v1_1/$cloudName/${v ? 'video' : 'image'}/upload",
    );
    var req = http.MultipartRequest("POST", url)
      ..fields['upload_preset'] = uploadPreset
      ..fields['folder'] = "chats/${getChatId()}"
      ..files.add(await http.MultipartFile.fromPath('file', f.path));
    try {
      var res = await req.send();
      if (res.statusCode == 200) {
        var d = await res.stream.toBytes();
        var j = jsonDecode(String.fromCharCodes(d));
        return {'url': j['secure_url'], 'public_id': j['public_id']};
      }
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      setState(() => _isUploadingMedia = false);
    }
    return null;
  }
}

// --- NEW REUSABLE CHAT BUBBLE WITH REACTIONS & HOVER ---
class ChatMessageBubble extends StatefulWidget {
  final String messageId, content, type, time;
  final bool isMe, isPending, isRead, isReceived;
  final Map reactions;
  final Function(String) onReact;
  final VoidCallback onLongPress;

  const ChatMessageBubble({
    super.key,
    required this.messageId,
    required this.content,
    required this.isMe,
    required this.type,
    required this.time,
    required this.isPending,
    required this.isRead,
    required this.isReceived,
    required this.reactions,
    required this.onReact,
    required this.onLongPress,
  });

  @override
  State<ChatMessageBubble> createState() => _ChatMessageBubbleState();
}

class _ChatMessageBubbleState extends State<ChatMessageBubble> {
  bool _isHovered = false;
  bool _showReactionPanel = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() {
        _isHovered = false;
        _showReactionPanel = false;
      }),
      child: GestureDetector(
        onLongPress: widget.onLongPress,
        onTap: () => setState(() => _showReactionPanel = !_showReactionPanel),
        child: Align(
          alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: widget.isMe
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              // --- FLOATING REACTION PANEL ---
              if (_isHovered || _showReactionPanel) _buildReactionPanel(),

              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: (widget.type != 'text')
                        ? const EdgeInsets.all(5)
                        : const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.7,
                    ),
                    decoration: BoxDecoration(
                      color: widget.isMe ? null : const Color(0xFF1A1A1A),
                      gradient: widget.isMe
                          ? const LinearGradient(
                              colors: [Color(0xFF8E2DE2), Color(0xFF00D2FF)],
                            )
                          : null,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: widget.type == 'image'
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.network(widget.content),
                          )
                        : (widget.type == 'video'
                              ? Container(
                                  width: 200,
                                  height: 150,
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: const Icon(
                                    Icons.play_circle_fill,
                                    size: 50,
                                  ),
                                )
                              : Text(
                                  widget.content,
                                  style: const TextStyle(color: Colors.white),
                                )),
                  ),
                  // --- DISPLAYED REACTIONS ---
                  if (widget.reactions.isNotEmpty)
                    Positioned(
                      bottom: -10,
                      right: widget.isMe ? null : -10,
                      left: widget.isMe ? -10 : null,
                      child: _buildReactionBadge(),
                    ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.time,
                    style: const TextStyle(color: Colors.white24, fontSize: 10),
                  ),
                  if (widget.isMe) ...[
                    const SizedBox(width: 4),
                    _buildTick(
                      widget.isPending,
                      widget.isReceived,
                      widget.isRead,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 15),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReactionPanel() {
    final emojis = ["🔥", "❤️", "👍", "😂", "😮", "😢"];
    return AnimatedScale(
      duration: const Duration(milliseconds: 200),
      scale: 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 5),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF161616),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: emojis
              .map(
                (e) => GestureDetector(
                  onTap: () => widget.onReact(e),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(e, style: const TextStyle(fontSize: 18)),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildReactionBadge() {
    String emojiText = widget.reactions.values.toSet().join("");
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF222222),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Text(emojiText, style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _buildTick(bool p, bool r, bool s) {
    if (p)
      return const Icon(Icons.access_time, size: 12, color: Colors.white24);
    if (s)
      return ShaderMask(
        shaderCallback: (b) => const LinearGradient(
          colors: [Color(0xFFD633FF), Color(0xFF00D2FF)],
        ).createShader(b),
        child: const Icon(Icons.done_all, size: 13, color: Colors.white),
      );
    if (r) return const Icon(Icons.done_all, size: 13, color: Colors.white24);
    return const Icon(Icons.done, size: 13, color: Colors.white24);
  }
}

// --- BREATHING TYPING INDICATOR ---
class BreathingTypingIndicator extends StatefulWidget {
  const BreathingTypingIndicator({super.key});
  @override
  State<BreathingTypingIndicator> createState() =>
      _BreathingTypingIndicatorState();
}

class _BreathingTypingIndicatorState extends State<BreathingTypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.3, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [Color(0xFFD633FF), Color(0xFF00D2FF)],
        ).createShader(bounds),
        child: const Text(
          "typing...",
          style: TextStyle(
            fontSize: 10,
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }
}
