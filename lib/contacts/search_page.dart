import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // REQUIRED

import '../chat/chat_detail_page.dart';
import '../widgets/grind_avatar.dart';

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
  List<String> _searchHistory = [];

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
  }

  // --- LOGIC: LOAD HISTORY FROM LOCAL STORAGE ---
  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _searchHistory = prefs.getStringList('recent_searches') ?? [];
    });
  }

  // --- LOGIC: SAVE TO HISTORY (Limit to 3) ---
  Future<void> _addToHistory(String query) async {
    if (query.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();

    // Remove if already exists (to move it to the front)
    _searchHistory.remove(query);
    _searchHistory.insert(0, query);

    // Keep only the last 3
    if (_searchHistory.length > 3) {
      _searchHistory = _searchHistory.sublist(0, 3);
    }

    await prefs.setStringList('recent_searches', _searchHistory);
    setState(() {});
  }

  // --- LOGIC: SEARCH BY NAME, EMAIL, OR USERNAME ---
  void _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() => searchResults = []);
      return;
    }
    setState(() => isLoading = true);

    // 1. Search by exact Email
    final emailQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: query.trim())
        .get();

    // 2. Search by exact Username
    final usernameQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('username', isEqualTo: query.trim().toLowerCase())
        .get();

    // 3. NEW: Search by Name (Exact Match)
    final nameQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('name', isEqualTo: query.trim())
        .get();

    if (mounted) {
      setState(() {
        // Combine all results and remove duplicates based on document ID
        final allDocs = [
          ...emailQuery.docs,
          ...usernameQuery.docs,
          ...nameQuery.docs,
        ];
        final seen = <String>{};
        searchResults = allDocs.where((doc) => seen.add(doc.id)).toList();

        isLoading = false;
      });

      // If we found people, save this query to history
      if (searchResults.isNotEmpty) {
        _addToHistory(query.trim());
      }
    }
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Input
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              onChanged: (val) => _performSearch(val),
              decoration: InputDecoration(
                hintText: "Search by name, email or @username",
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

          // --- SEARCH HISTORY CHIPS ---
          if (_searchController.text.isEmpty && _searchHistory.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "RECENT SEARCHES",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    children: _searchHistory
                        .map(
                          (query) => GestureDetector(
                            onTap: () {
                              _searchController.text = query;
                              _performSearch(query);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(
                                    0xFF8E2DE2,
                                  ).withOpacity(0.4),
                                ),
                                color: const Color(
                                  0xFF8E2DE2,
                                ).withOpacity(0.05),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.history,
                                    color: Colors.grey,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    query,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),

          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(color: Color(0xFF8E2DE2)),
              ),
            ),

          if (!isLoading &&
              searchResults.isEmpty &&
              _searchController.text.isNotEmpty)
            const Center(
              child: Text(
                "No users found.",
                style: TextStyle(color: Colors.grey),
              ),
            ),

          Expanded(
            child: ListView.builder(
              itemCount: searchResults.length,
              itemBuilder: (context, index) {
                var userData =
                    searchResults[index].data() as Map<String, dynamic>;
                if (userData['uid'] == currentUser!.uid)
                  return const SizedBox.shrink();
                return SearchResultTile(userData: userData);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// --- ANIMATED TILE CLASS ---
class SearchResultTile extends StatefulWidget {
  final Map<String, dynamic> userData;
  const SearchResultTile({super.key, required this.userData});

  @override
  State<SearchResultTile> createState() => _SearchResultTileState();
}

class _SearchResultTileState extends State<SearchResultTile> {
  final currentUser = FirebaseAuth.instance.currentUser;
  bool _isLocalLoading = false;
  bool _showCheckmark = false;

  void _sendRequest() async {
    setState(() => _isLocalLoading = true);
    try {
      final myDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get();
      final myData = myDoc.data() as Map<String, dynamic>;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userData['uid'])
          .collection('friend_requests')
          .doc(currentUser!.uid)
          .set({
            'senderId': currentUser!.uid,
            'senderName': myData['name'],
            'senderPic': myData['profilePic'] ?? "",
            'timestamp': FieldValue.serverTimestamp(),
          });

      setState(() {
        _isLocalLoading = false;
        _showCheckmark = true;
      });

      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) setState(() => _showCheckmark = false);
    } catch (e) {
      setState(() => _isLocalLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String targetUid = widget.userData['uid'];
    String name = widget.userData['name'] ?? "User";

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
          GrindAvatar(
            imageUrl: widget.userData['profilePic'] ?? "",
            radius: 25,
            name: name,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "@${widget.userData['username'] ?? 'user'}",
                  style: const TextStyle(
                    color: Color(0xFF00D2FF),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(currentUser!.uid)
                .collection('my_contacts')
                .doc(targetUid)
                .snapshots(),
            builder: (context, contactSnap) {
              if (contactSnap.hasData && contactSnap.data!.exists) {
                return TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (c) => ChatDetailPage(
                        receiverName: name,
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
              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(targetUid)
                    .collection('friend_requests')
                    .doc(currentUser!.uid)
                    .snapshots(),
                builder: (context, requestSnap) {
                  bool isRequestedInDB =
                      requestSnap.hasData && requestSnap.data!.exists;
                  return SizedBox(
                    width: 100,
                    height: 35,
                    child: _showCheckmark
                        ? const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 28,
                          )
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isRequestedInDB
                                  ? Colors.white10
                                  : const Color(0xFF8E2DE2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            onPressed: (isRequestedInDB || _isLocalLoading)
                                ? null
                                : _sendRequest,
                            child: _isLocalLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    isRequestedInDB ? "Requested" : "Add",
                                    style: TextStyle(
                                      color: isRequestedInDB
                                          ? Colors.grey
                                          : Colors.white,
                                      fontSize: 12,
                                    ),
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
}
