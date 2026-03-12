import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../chat/chat_detail_page.dart';
import 'search_page.dart';
import 'friend_requests_page.dart';

class ContactsPage extends StatelessWidget {
  const ContactsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAppBar(currentUser),

            // --- ADD CONTACT BUTTON ---
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SearchPage()),
                ),
                borderRadius: BorderRadius.circular(15),
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
                      Icon(Icons.person_add_outlined, color: Colors.white),
                      SizedBox(width: 10),
                      Text(
                        "Add New Contact",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // --- FRIEND REQUESTS BADGE ---
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUser?.uid)
                  .collection('friend_requests')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                  return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FriendRequestsPage(),
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8E2DE2).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: const Color(0xFF8E2DE2).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.person_pin_circle_outlined,
                            color: Color(0xFF8E2DE2),
                          ),
                          const SizedBox(width: 15),
                          const Text(
                            "Friend Requests",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: const Color(0xFF00D2FF),
                            child: Text(
                              snapshot.data!.docs.length.toString(),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            const Padding(
              padding: EdgeInsets.only(left: 16, top: 10, bottom: 10),
              child: Text(
                "MY CONTACTS",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ),

            // --- DYNAMIC CONTACTS LIST ---
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(currentUser?.uid)
                    .collection('my_contacts')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        "Search for friends to add them here",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    );
                  }
                  final contacts = snapshot.data!.docs;
                  return ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: contacts.length,
                    itemBuilder: (context, index) {
                      String friendId = contacts[index].id;
                      return StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(friendId)
                            .snapshots(),
                        builder: (context, userSnap) {
                          if (!userSnap.hasData || !userSnap.data!.exists)
                            return const SizedBox.shrink();
                          var data =
                              userSnap.data!.data() as Map<String, dynamic>;
                          return ContactTile(
                            name: data['name'] ?? 'User',
                            status: data['status'] ?? 'OFFLINE',
                            uid: friendId,
                            profilePic: data['profilePic'] ?? '',
                          );
                        },
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

  Widget _buildAppBar(User? currentUser) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
      child: Row(
        children: [
          const Text(
            "Contacts",
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
  }
}

class ContactTile extends StatelessWidget {
  final String name;
  final String status;
  final String uid;
  final String profilePic;

  const ContactTile({
    super.key,
    required this.name,
    required this.status,
    required this.uid,
    required this.profilePic,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ChatDetailPage(receiverName: name, receiverId: uid),
        ),
      ),
      leading: CircleAvatar(
        radius: 25,
        backgroundColor: Colors.white10,
        backgroundImage: profilePic.isNotEmpty
            ? MemoryImage(base64Decode(profilePic))
            : null,
        child: profilePic.isEmpty
            ? const Icon(Icons.person, color: Colors.white)
            : null,
      ),
      title: Text(
        name,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        status,
        style: TextStyle(
          color: status == "GRINDING" ? Colors.orange : Colors.green,
          fontSize: 11,
        ),
      ),
      trailing: const Icon(
        Icons.chat_bubble_outline,
        color: Colors.white24,
        size: 20,
      ),
    );
  }
}
