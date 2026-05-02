import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../widgets/grind_avatar.dart';

class ContactProfilePage extends StatelessWidget {
  final String receiverId, receiverName;
  const ContactProfilePage(
      {super.key, required this.receiverId, required this.receiverName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context)),
          title: const Text("Contact Profile",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          actions: [
            IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onPressed: () {})
          ]),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(receiverId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFF8E2DE2)));
          var d = snapshot.data!.data() as Map<String, dynamic>?;
          if (d == null) return const Center(child: Text("User not found"));

          String pic = d['profilePic'] ?? "";
          String status = d['status'] ?? "OFFLINE";
          String bio = d['subtext'] ?? "Stay connected. Stay grinding.";

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(children: [
              const SizedBox(height: 20),
              _buildAvatar(pic, status),
              const SizedBox(height: 20),
              Text(receiverName,
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                        color: _getStatusColor(status),
                        shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text(status,
                    style: const TextStyle(
                        color: Colors.grey,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.bold,
                        fontSize: 12))
              ]),
              const SizedBox(height: 20),
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(bio,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Color(0xFF7B8BB2), fontSize: 14))),
              const SizedBox(height: 30),

              // --- UPDATED ACTION BUTTONS: Call and Video Removed ---
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _actionBtn(Icons.chat_bubble_outline, "Message",
                    onTap: () => Navigator.pop(context)),
              ]),

              const SizedBox(height: 40),
              _section("CONTACT INFORMATION"),
              _tile("Phone Number", d['phone'] ?? "Not provided"),
              _tile("Email Address", d['email'] ?? "Not provided"),
              const SizedBox(height: 30),
              _section("SETTINGS & ACTIONS"),
              _actionTile(Icons.star, "Remove from Favorites",
                  iconColor: Colors.amber),
              _actionTile(Icons.notifications_none, "Notifications"),
              _actionTile(Icons.shield_outlined, "Block Contact"),
              _actionTile(Icons.delete_outline, "Delete Contact",
                  isDestructive: true),
              const SizedBox(height: 50),
            ]),
          );
        },
      ),
    );
  }

  Widget _buildAvatar(String pic, String s) =>
      Stack(alignment: Alignment.center, children: [
        Container(
            height: 140,
            width: 140,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [
                  const Color(0xFF8E2DE2).withOpacity(0.4),
                  Colors.transparent
                ], begin: Alignment.topCenter, end: Alignment.bottomCenter))),
        GrindAvatar(imageUrl: pic, radius: 60, name: receiverName),
        Positioned(
            bottom: 10,
            right: 10,
            child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                    color: _getStatusColor(s),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 3)))),
      ]);

  Widget _actionBtn(IconData i, String l, {VoidCallback? onTap}) => InkWell(
      onTap: onTap ?? () {},
      borderRadius: BorderRadius.circular(15),
      child: Container(
          width: 100,
          height: 90,
          decoration: BoxDecoration(
              color: const Color(0xFF161616),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.05))),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(i, color: Colors.white, size: 24),
            const SizedBox(height: 8),
            Text(l, style: const TextStyle(color: Colors.grey, fontSize: 12))
          ])));
  Widget _section(String l) => Align(
      alignment: Alignment.centerLeft,
      child: Padding(
          padding: const EdgeInsets.only(bottom: 15, left: 4),
          child: Text(l,
              style: const TextStyle(
                  color: Color(0xFF4C535F),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2))));
  Widget _tile(String l, String v) => Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: const Color(0xFF161616),
          borderRadius: BorderRadius.circular(15)),
      child: Row(children: [
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          const SizedBox(height: 4),
          Text(v,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14))
        ])),
        const Icon(Icons.chevron_right, color: Colors.white24, size: 18)
      ]));
  Widget _actionTile(IconData i, String t,
          {Color? iconColor, bool isDestructive = false}) =>
      Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
              color: const Color(0xFF161616),
              borderRadius: BorderRadius.circular(15)),
          child: Row(children: [
            Icon(i,
                color: isDestructive
                    ? Colors.redAccent
                    : (iconColor ?? Colors.grey),
                size: 20),
            const SizedBox(width: 15),
            Expanded(
                child: Text(t,
                    style: TextStyle(
                        color: isDestructive ? Colors.redAccent : Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14))),
            const Icon(Icons.chevron_right, color: Colors.white10, size: 18)
          ]));
  Color _getStatusColor(String s) {
    if (s == "ONLINE") return Colors.green;
    if (s == "GRINDING") return Colors.orange;
    if (s == "AWAY") return Colors.yellow;
    return Colors.grey;
  }
}
