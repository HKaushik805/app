import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../auth/login_page.dart';
// --- ALL PROFESSIONAL IMPORTS ---
import '../main.dart';
import '../widgets/grind_avatar.dart';
import 'about_page.dart';
import 'appearance_page.dart';
import 'change_status_page.dart';
import 'data_usage_page.dart';
import 'edit_profile_page.dart';
import 'help_center_page.dart';
import 'privacy_page.dart';
import 'security_page.dart';
import 'sounds_haptics_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final currentUser = FirebaseAuth.instance.currentUser;

  Color _getStatusColor(String s) {
    switch (s) {
      case "ONLINE":
        return Colors.green;
      case "AWAY":
        return Colors.yellow;
      case "GRINDING":
        return Colors.orange;
      case "BUSY":
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String s) {
    switch (s) {
      case "GRINDING":
        return Icons.local_fire_department;
      case "ONLINE":
        return Icons.bolt;
      case "AWAY":
        return Icons.coffee;
      case "BUSY":
        return Icons.track_changes;
      default:
        return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser?.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData)
              return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF8E2DE2)));

            var d = snapshot.data!.data() as Map<String, dynamic>;
            String name = (d['name'] ?? "User").toString();
            String status = (d['status'] ?? "GRINDING").toString();
            String bio =
                (d['subtext'] ?? "Stay connected. Stay grinding.").toString();
            String pic = (d['profilePic'] ?? "").toString();

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- HEADER CARD ---
                      _buildProfileHeader(name, status, bio, pic),

                      // --- ACCOUNT SECTION ---
                      _buildSectionHeader("ACCOUNT"),
                      _buildSettingTile(
                        Icons.edit_outlined,
                        "Edit Profile",
                        "Change your name, photo, and bio",
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (c) => EditProfilePage(userData: d))),
                      ),
                      _buildSettingTile(
                        _getStatusIcon(status),
                        "Status",
                        "Currently: $status",
                        isStatusIcon: true,
                        iconColor: _getStatusColor(status),
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (c) => ChangeStatusPage(userData: d))),
                      ),

                      // --- PREFERENCES SECTION ---
                      _buildSectionHeader("PREFERENCES"),
                      _buildSettingTile(
                        Icons.volume_up_outlined,
                        "Sounds & Haptics",
                        "Ringtones and vibration",
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (c) => const SoundsHapticsPage())),
                      ),
                      _buildSettingTile(
                        Icons.palette_outlined,
                        "Appearance",
                        "Themes and customization",
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (c) => const AppearancePage())),
                      ),

                      // --- PRIVACY & SECURITY SECTION ---
                      _buildSectionHeader("PRIVACY & SECURITY"),
                      _buildSettingTile(
                        Icons.lock_outline,
                        "Privacy",
                        "Block contacts, disappearing messages",
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (c) => const PrivacyPage())),
                      ),
                      _buildSettingTile(
                        Icons.shield_outlined,
                        "Security",
                        "Two-step verification, change password",
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (c) => const SecurityPage())),
                      ),
                      _buildSettingTile(
                        Icons.storage_outlined,
                        "Data Usage",
                        "Network usage, auto-download",
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (c) => const DataUsagePage())),
                      ),

                      // --- SUPPORT SECTION ---
                      _buildSectionHeader("SUPPORT"),
                      _buildSettingTile(
                        Icons.help_outline,
                        "Help Center",
                        "FAQs and support",
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (c) => const HelpCenterPage())),
                      ),
                      _buildSettingTile(
                        Icons.info_outline,
                        "About",
                        "Version 2.5.6",
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (c) => const AboutPage())),
                      ),

                      const SizedBox(height: 30),

                      // --- LOG OUT BUTTON ---
                      _buildLogoutButton(),

                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileHeader(
      String name, String status, String subtext, String profilePic) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: const Color(0xFF161616),
          borderRadius: BorderRadius.circular(25)),
      child: Row(
        children: [
          Stack(
            children: [
              GrindAvatar(imageUrl: profilePic, radius: 35, name: name),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: _getStatusColor(status),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 2.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20)),
                Text("● $status",
                    style: TextStyle(
                        color: _getStatusColor(status),
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtext,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const Icon(Icons.more_vert, color: Colors.white70),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, top: 25, bottom: 10),
      child: Text(title,
          style: const TextStyle(
              color: Color(0xFF444444),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5)),
    );
  }

  Widget _buildSettingTile(IconData icon, String title, String subtitle,
      {Widget? trailing,
      VoidCallback? onTap,
      bool isStatusIcon = false,
      Color iconColor = Colors.white70}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Hero(
              tag: isStatusIcon ? 'status_icon_hero' : title,
              child: Container(
                height: 45,
                width: 45,
                decoration: const BoxDecoration(
                    color: Color(0xFF161616), shape: BoxShape.circle),
                child: Icon(icon, color: iconColor, size: 20),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15)),
                  Text(subtitle,
                      style: const TextStyle(
                          color: Color(0xFF666666), fontSize: 12)),
                ],
              ),
            ),
            trailing ??
                const Icon(Icons.arrow_forward_ios,
                    color: Color(0xFF333333), size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: InkWell(
        onTap: () async {
          messengerKey.currentState?.clearSnackBars();
          await FirebaseAuth.instance.signOut();
          if (mounted) {
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (c) => const LoginPage()),
                (r) => false);
          }
        },
        child: Container(
          height: 55,
          decoration: BoxDecoration(
            color: const Color(0xFF1A0A0A),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.red.withOpacity(0.3)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout, color: Colors.redAccent, size: 20),
              SizedBox(width: 10),
              Text("Log Out",
                  style: TextStyle(
                      color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
