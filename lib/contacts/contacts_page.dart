import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../chat/chat_detail_page.dart';
import '../widgets/grind_avatar.dart';
import 'friend_requests_page.dart';
import 'search_page.dart';

class ContactsPage extends StatelessWidget {
  const ContactsPage({super.key});

  // --- HELPER: GENERATE CHAT ID ---
  String _getChatId(String uid1, String uid2) {
    List<String> ids = [uid1, uid2];
    ids.sort();
    return ids.join("_");
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAppBar(),
            _buildAddBtn(context),
            _buildRequestsBadge(context, currentUser!.uid),
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
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(currentUser.uid)
                    .collection('my_contacts')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                    return const Center(
                      child: Text(
                        "No contacts yet",
                        style: TextStyle(color: Colors.grey),
                      ),
                    );

                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      String friendId = snapshot.data!.docs[index].id;
                      return StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(friendId)
                            .snapshots(),
                        builder: (context, userSnap) {
                          if (!userSnap.hasData) return const SizedBox.shrink();
                          var data =
                              userSnap.data!.data() as Map<String, dynamic>;

                          return ListTile(
                            onTap: () {
                              // --- SPEED OPTIMIZATION: PRE-LOADING ---
                              String chatId = _getChatId(
                                currentUser.uid,
                                friendId,
                              );

                              // We trigger a 'get()' here. We don't wait for it.
                              // This 'warms up' the Firestore cache so ChatDetailPage loads instantly.
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
                                    receiverName: data['name'],
                                    receiverId: friendId,
                                  ),
                                ),
                              );
                            },
                            leading: GrindAvatar(
                              imageUrl: data['profilePic'],
                              radius: 25,
                              name: data['name'] ?? "",
                            ),
                            title: Text(
                              data['name'] ?? "User",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              data['status'] ?? "OFFLINE",
                              style: TextStyle(
                                color: data['status'] == "GRINDING"
                                    ? Colors.orange
                                    : Colors.green,
                                fontSize: 11,
                              ),
                            ),
                            trailing: const Icon(
                              Icons.chat_bubble_outline,
                              color: Colors.white24,
                              size: 20,
                            ),
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

  // (AppBar, AddBtn, and RequestsBadge helpers remain the same as previous updated version)
  Widget _buildAppBar() => Padding(
    padding: const EdgeInsets.all(16),
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
  Widget _buildAddBtn(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16.0),
    child: InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (c) => const SearchPage()),
      ),
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
              ),
            ),
          ],
        ),
      ),
    ),
  );
  Widget _buildRequestsBadge(BuildContext context, String uid) =>
      StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('friend_requests')
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData || snap.data!.docs.isEmpty)
            return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => const FriendRequestsPage()),
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
                        snap.data!.docs.length.toString(),
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
      );
}
