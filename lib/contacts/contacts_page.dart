import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../chat/chat_detail_page.dart';
import '../widgets/grind_avatar.dart';
import 'friend_requests_page.dart';
import 'search_page.dart';

class ContactsPage extends StatefulWidget {
  final int activeTabIndex;
  const ContactsPage({super.key, required this.activeTabIndex});
  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  final currentUser = FirebaseAuth.instance.currentUser;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void didUpdateWidget(covariant ContactsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activeTabIndex != 1 && _isSearching) {
      _closeSearch();
    }
  }

  void _closeSearch() {
    setState(() {
      _isSearching = false;
      _searchController.clear();
      _searchQuery = "";
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getStatusColor(String s) {
    if (s == "GRINDING") return Colors.orange;
    if (s == "ONLINE") return Colors.green;
    if (s == "AWAY") return Colors.yellow;
    if (s == "BUSY") return Colors.redAccent;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Center(
            child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildAppBar(),
            if (!_isSearching) ...[
              _buildAddBtn(context),
              _buildRequestsBadge(context, currentUser!.uid)
            ],
            Padding(
                padding: const EdgeInsets.only(left: 16, top: 10, bottom: 10),
                child: Text(_isSearching ? "SEARCH RESULTS" : "MY CONTACTS",
                    style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5))),
            Expanded(
                child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUser?.uid)
                  .collection('my_contacts')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return const Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFF8E2DE2)));
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                  return const Center(
                      child: Text("No contacts yet",
                          style: TextStyle(color: Colors.grey, fontSize: 12)));

                return ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      String friendId = snapshot.data!.docs[index].id;
                      return StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .doc(friendId)
                              .snapshots(),
                          builder: (context, userSnap) {
                            if (!userSnap.hasData || !userSnap.data!.exists)
                              return const SizedBox.shrink();
                            var d =
                                userSnap.data!.data() as Map<String, dynamic>;
                            if (_searchQuery.isNotEmpty &&
                                !(d['name'] ?? "")
                                    .toLowerCase()
                                    .contains(_searchQuery.toLowerCase()))
                              return const SizedBox.shrink();
                            return ContactTile(
                                name: d['name'] ?? 'User',
                                status: d['status'] ?? 'OFFLINE',
                                uid: friendId,
                                profilePic: d['profilePic'] ?? '',
                                statusColor:
                                    _getStatusColor(d['status'] ?? 'OFFLINE'));
                          });
                    });
              },
            )),
          ]),
        )),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
        child: Row(children: [
          if (!_isSearching) ...[
            const Text("Contacts",
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 22)),
            const Spacer(),
            IconButton(
                icon: const Icon(Icons.search, color: Colors.white),
                onPressed: () => setState(() => _isSearching = true))
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
                            hintText: "Search contacts...",
                            hintStyle: const TextStyle(color: Colors.white10),
                            prefixIcon: const Icon(Icons.search,
                                color: Color(0xFF00D2FF), size: 20),
                            suffixIcon: IconButton(
                                icon: const Icon(Icons.close,
                                    color: Colors.grey, size: 20),
                                onPressed: _closeSearch),
                            border: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 10)))))
          ]
        ]));
  }

  Widget _buildAddBtn(BuildContext c) => Padding(
      padding: const EdgeInsets.all(16.0),
      child: InkWell(
          onTap: () => Navigator.push(
              c, MaterialPageRoute(builder: (c) => const SearchPage())),
          child: Container(
              width: double.infinity,
              height: 55,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: const LinearGradient(
                      colors: [Color(0xFF8E2DE2), Color(0xFF00D2FF)])),
              child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_add_outlined, color: Colors.white),
                    SizedBox(width: 10),
                    Text("Add New Contact",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold))
                  ]))));
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: InkWell(
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (c) => const FriendRequestsPage())),
                    child: Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                            color: const Color(0xFF8E2DE2).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                                color:
                                    const Color(0xFF8E2DE2).withOpacity(0.3))),
                        child: Row(children: [
                          const Icon(Icons.person_pin_circle_outlined,
                              color: Color(0xFF8E2DE2)),
                          const SizedBox(width: 15),
                          const Text("Friend Requests",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                          const Spacer(),
                          CircleAvatar(
                              radius: 12,
                              backgroundColor: const Color(0xFF00D2FF),
                              child: Text(snap.data!.docs.length.toString(),
                                  style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold))),
                          const Icon(Icons.chevron_right, color: Colors.grey)
                        ]))));
          });
}

class ContactTile extends StatelessWidget {
  final String name, status, uid, profilePic;
  final Color statusColor;
  const ContactTile(
      {super.key,
      required this.name,
      required this.status,
      required this.uid,
      required this.profilePic,
      required this.statusColor});
  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (c) =>
                  ChatDetailPage(receiverName: name, receiverId: uid))),
      leading: Stack(children: [
        GrindAvatar(imageUrl: profilePic, radius: 25, name: name),
        Positioned(
            right: 0,
            bottom: 0,
            child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 2))))
      ]),
      title: Text(name,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold)),
      subtitle: Text(status,
          style: TextStyle(
              color: statusColor, fontSize: 11, fontWeight: FontWeight.w500)),
      trailing:
          const Icon(Icons.chevron_right, color: Colors.white10, size: 18),
    );
  }
}
