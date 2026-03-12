import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendRequestsPage extends StatelessWidget {
  const FriendRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text("Friend Requests"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(myUid)
            .collection('friend_requests')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final requests = snapshot.data!.docs;

          if (requests.isEmpty) {
            return const Center(
              child: Text(
                "No pending requests",
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              var req = requests[index].data() as Map<String, dynamic>;
              return _buildRequestTile(context, req, myUid);
            },
          );
        },
      ),
    );
  }

  Widget _buildRequestTile(
    BuildContext context,
    Map<String, dynamic> req,
    String myUid,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundImage:
                (req['senderPic'] != null && req['senderPic'] != "")
                ? MemoryImage(base64Decode(req['senderPic']))
                : null,
            child: (req['senderPic'] == "" || req['senderPic'] == null)
                ? const Icon(Icons.person)
                : null,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              req['senderName'],
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.redAccent),
            onPressed: () => _handleAction(req['senderId'], myUid, false),
          ),
          const SizedBox(width: 10),
          Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF8E2DE2), Color(0xFF00D2FF)],
              ),
            ),
            child: IconButton(
              icon: const Icon(Icons.check, color: Colors.white),
              onPressed: () => _handleAction(req['senderId'], myUid, true),
            ),
          ),
        ],
      ),
    );
  }

  void _handleAction(String senderId, String myUid, bool approve) async {
    final batch = FirebaseFirestore.instance.batch();
    final requestDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(myUid)
        .collection('friend_requests')
        .doc(senderId);

    if (approve) {
      batch.set(
        FirebaseFirestore.instance
            .collection('users')
            .doc(myUid)
            .collection('my_contacts')
            .doc(senderId),
        {'uid': senderId},
      );
      batch.set(
        FirebaseFirestore.instance
            .collection('users')
            .doc(senderId)
            .collection('my_contacts')
            .doc(myUid),
        {'uid': myUid},
      );
    }
    batch.delete(requestDoc);
    await batch.commit();
  }
}
