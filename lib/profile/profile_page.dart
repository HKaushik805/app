import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../auth/login_page.dart';
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
  bool isDarkMode = true;

  Color _getStatusColor(String s) {
    if (s == "ONLINE") return Colors.green;
    if (s == "AWAY") return Colors.yellow;
    if (s == "GRINDING") return Colors.orange;
    return Colors.grey;
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
                child: CircularProgressIndicator(color: Color(0xFF8E2DE2)),
              );
            var d = snapshot.data!.data() as Map<String, dynamic>;
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(d),
                      _buildSectionHeader("ACCOUNT"),
                      _buildTile(
                        Icons.edit_outlined,
                        "Edit Profile",
                        "Change name and photo",
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (c) => EditProfilePage(userData: d),
                          ),
                        ),
                      ),
                      _buildTile(
                        Icons.bolt,
                        "Status",
                        "Currently: ${d['status']}",
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (c) => ChangeStatusPage(userData: d),
                          ),
                        ),
                      ),
                      _buildSectionHeader("PREFERENCES"),
                      _buildTile(
                        Icons.dark_mode_outlined,
                        "Dark Mode",
                        "Always on",
                        trailing: Switch(
                          value: isDarkMode,
                          onChanged: (v) => setState(() => isDarkMode = v),
                          activeThumbColor: const Color(0xFF8E2DE2),
                        ),
                      ),
                      _buildTile(
                        Icons.volume_up_outlined,
                        "Sounds & Haptics",
                        "Ringtones",
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (c) => const SoundsHapticsPage(),
                          ),
                        ),
                      ),
                      _buildTile(
                        Icons.palette_outlined,
                        "Appearance",
                        "Themes",
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (c) => const AppearancePage(),
                          ),
                        ),
                      ),
                      _buildSectionHeader("PRIVACY & SECURITY"),
                      _buildTile(
                        Icons.lock_outline,
                        "Privacy",
                        "Block contacts",
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (c) => const PrivacyPage(),
                          ),
                        ),
                      ),
                      _buildTile(
                        Icons.shield_outlined,
                        "Security",
                        "Change password",
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (c) => const SecurityPage(),
                          ),
                        ),
                      ),
                      _buildTile(
                        Icons.storage_outlined,
                        "Data Usage",
                        "Network usage",
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (c) => const DataUsagePage(),
                          ),
                        ),
                      ),
                      _buildSectionHeader("SUPPORT"),
                      _buildTile(
                        Icons.help_outline,
                        "Help Center",
                        "FAQs",
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (c) => const HelpCenterPage(),
                          ),
                        ),
                      ),
                      _buildTile(
                        Icons.info_outline,
                        "About",
                        "Version 2.5.6",
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (c) => const AboutPage()),
                        ),
                      ),
                      const SizedBox(height: 30),
                      _buildLogout(),
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

  Widget _buildHeader(Map<String, dynamic> d) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              GrindAvatar(
                imageUrl: d['profilePic'],
                radius: 35,
                name: d['name'] ?? "",
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: _getStatusColor(d['status'] ?? ""),
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
                Text(
                  d['name'] ?? "User",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                Text(
                  "● ${d['status'] ?? 'OFFLINE'}",
                  style: TextStyle(
                    color: _getStatusColor(d['status'] ?? ""),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  d['subtext'] ?? "",
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String t) => Padding(
    padding: const EdgeInsets.only(left: 20, top: 25, bottom: 10),
    child: Text(
      t,
      style: const TextStyle(
        color: Color(0xFF444444),
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
    ),
  );
  Widget _buildTile(
    IconData i,
    String t,
    String s, {
    Widget? trailing,
    VoidCallback? onTap,
  }) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            height: 45,
            width: 45,
            decoration: const BoxDecoration(
              color: Color(0xFF161616),
              shape: BoxShape.circle,
            ),
            child: Icon(i, color: Colors.white70, size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                Text(
                  s,
                  style: const TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          trailing ??
              const Icon(
                Icons.arrow_forward_ios,
                color: Color(0xFF333333),
                size: 14,
              ),
        ],
      ),
    ),
  );
  Widget _buildLogout() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16.0),
    child: InkWell(
      onTap: () async {
        messengerKey.currentState?.clearSnackBars();
        await FirebaseAuth.instance.signOut();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (c) => const LoginPage()),
          (r) => false,
        );
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
            Icon(Icons.logout, color: Colors.redAccent),
            SizedBox(width: 10),
            Text(
              "Log Out",
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
