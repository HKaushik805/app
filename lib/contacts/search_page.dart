import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../chat/chat_detail_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final currentUser = FirebaseAuth.instance.currentUser;

  bool isLoading = false;
  List<DocumentSnapshot> searchResults = [];

  // --- LOGIC: SEARCH BY USERNAME OR EMAIL ---
  void _performSearch(String query) async {
    if (query.isEmpty) return;
    setState(() => isLoading = true);

    // We check both email and username fields
    final emailQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: query.trim())
        .get();

    final usernameQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('username', isEqualTo: query.trim().toLowerCase())
        .get();

    setState(() {
      // Combine results and remove duplicates
      searchResults = [...emailQuery.docs, ...usernameQuery.docs];
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Find People",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Search Input
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              onChanged: (val) => _performSearch(val), // Search as you type
              decoration: InputDecoration(
                hintText: "Search by email or @username",
                hintStyle: const TextStyle(color: Colors.white10),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF00D2FF)),
                filled: true,
                fillColor: const Color(0xFF161616),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          if (isLoading)
            const CircularProgressIndicator(color: Color(0xFF8E2DE2)),

          if (!isLoading &&
              searchResults.isEmpty &&
              _searchController.text.isNotEmpty)
            const Text("No users found.", style: TextStyle(color: Colors.grey)),

          Expanded(
            child: ListView.builder(
              itemCount: searchResults.length,
              itemBuilder: (context, index) {
                var userData =
                    searchResults[index].data() as Map<String, dynamic>;
                String targetUid = userData['uid'];

                if (targetUid == currentUser!.uid)
                  return const SizedBox.shrink();

                return _buildSmartSearchResult(userData);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartSearchResult(Map<String, dynamic> userData) {
    String targetUid = userData['uid'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundImage:
                (userData['profilePic'] != null && userData['profilePic'] != "")
                ? MemoryImage(base64Decode(userData['profilePic']))
                : null,
            child:
                (userData['profilePic'] == "" || userData['profilePic'] == null)
                ? const Icon(Icons.person)
                : null,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userData['name'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "@${userData['username'] ?? 'user'}",
                  style: const TextStyle(
                    color: Color(0xFF00D2FF),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // --- SMART BUTTON LOGIC ---
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(currentUser!.uid)
                .collection('my_contacts')
                .doc(targetUid)
                .snapshots(),
            builder: (context, contactSnap) {
              // 1. Check if already Friends
              if (contactSnap.hasData && contactSnap.data!.exists) {
                return TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (c) => ChatDetailPage(
                        receiverName: userData['name'],
                        receiverId: targetUid,
                      ),
                    ),
                  ),
                  child: const Text(
                    "Message",
                    style: TextStyle(color: Color(0xFF00D2FF)),
                  ),
                );
              }

              // 2. Check if Request is already Pending
              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(targetUid)
                    .collection('friend_requests')
                    .doc(currentUser!.uid)
                    .snapshots(),
                builder: (context, requestSnap) {
                  bool isRequested =
                      requestSnap.hasData && requestSnap.data!.exists;

                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isRequested
                          ? Colors.white10
                          : const Color(0xFF8E2DE2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    onPressed: isRequested
                        ? null
                        : () => _sendRequest(userData),
                    child: Text(
                      isRequested ? "Requested" : "Add",
                      style: TextStyle(
                        color: isRequested ? Colors.grey : Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  void _sendRequest(Map<String, dynamic> targetUser) async {
    final myDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .get();
    final myData = myDoc.data() as Map<String, dynamic>;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(targetUser['uid'])
        .collection('friend_requests')
        .doc(currentUser!.uid)
        .set({
          'senderId': currentUser!.uid,
          'senderName': myData['name'],
          'senderPic': myData['profilePic'] ?? "",
          'timestamp': FieldValue.serverTimestamp(),
        });
  }
}
