import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ContactProfilePage extends StatelessWidget {
  final String receiverId;
  final String receiverName;

  const ContactProfilePage({
    super.key,
    required this.receiverId,
    required this.receiverName,
  });

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
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Contact Profile",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(receiverId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF8E2DE2)),
            );
          }
          var data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data == null)
            return const Center(
              child: Text(
                "User not found",
                style: TextStyle(color: Colors.white),
              ),
            );

          String pPic = data['profilePic'] ?? "";
          String status = data['status'] ?? "OFFLINE";
          String bio = data['subtext'] ?? "Stay connected. Stay grinding.";
          String email = data['email'] ?? "No email provided";
          String phone = data['phone'] ?? "Not provided";

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 20),
                // --- FIXED PROFILE IMAGE & STATUS ---
                _buildProfileAvatar(pPic, status),

                const SizedBox(height: 20),
                Text(
                  receiverName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _getStatusColor(status),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      status,
                      style: const TextStyle(
                        color: Colors.grey,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    bio,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF7B8BB2),
                      fontSize: 14,
                    ),
                  ),
                ),

                const SizedBox(height: 30),
                // --- ACTION BUTTONS ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildActionButton(
                      Icons.chat_bubble_outline,
                      "Message",
                      onTap: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 15),
                    _buildActionButton(Icons.phone_outlined, "Call"),
                    const SizedBox(width: 15),
                    _buildActionButton(Icons.videocam_outlined, "Video"),
                  ],
                ),

                const SizedBox(height: 40),
                _buildSectionLabel("CONTACT INFORMATION"),
                _buildInfoTile("Phone Number", phone),
                _buildInfoTile("Email Address", email),

                const SizedBox(height: 30),
                _buildSectionLabel("SETTINGS & ACTIONS"),
                _buildActionTile(
                  Icons.star,
                  "Remove from Favorites",
                  iconColor: Colors.amber,
                ),
                _buildActionTile(Icons.notifications_none, "Notifications"),
                _buildActionTile(Icons.shield_outlined, "Block Contact"),
                _buildActionTile(
                  Icons.delete_outline,
                  "Delete Contact",
                  isDestructive: true,
                ),

                const SizedBox(height: 50),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildProfileAvatar(String pPic, String status) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          height: 140,
          width: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                const Color(0xFF8E2DE2).withOpacity(0.4),
                Colors.transparent,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        // --- FIXED HYBRID LOGIC HERE ---
        CircleAvatar(
          radius: 60,
          backgroundColor: Colors.white10,
          backgroundImage: pPic.startsWith('http')
              ? NetworkImage(pPic)
              : (pPic.isNotEmpty ? MemoryImage(base64Decode(pPic)) : null)
                    as ImageProvider?,
          child: pPic.isEmpty
              ? const Icon(Icons.person, size: 60, color: Colors.white)
              : null,
        ),
        Positioned(
          bottom: 10,
          right: 10,
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: _getStatusColor(status),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 3),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String label, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap ?? () {},
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: 100,
        height: 90,
        decoration: BoxDecoration(
          color: const Color(0xFF161616),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white24, size: 18),
        ],
      ),
    );
  }

  Widget _buildActionTile(
    IconData icon,
    String title, {
    Color? iconColor,
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: isDestructive
                ? Colors.redAccent
                : (iconColor ?? Colors.grey),
            size: 20,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: isDestructive ? Colors.redAccent : Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white10, size: 18),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 15, left: 4),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF4C535F),
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case "ONLINE":
        return Colors.green;
      case "GRINDING":
        return Colors.orange;
      case "AWAY":
        return Colors.yellow;
      default:
        return Colors.grey;
    }
  }
}
