import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PrivacyPage extends StatefulWidget {
  const PrivacyPage({super.key});

  @override
  State<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacyPage> {
  final currentUser = FirebaseAuth.instance.currentUser;

  // Local State
  String lastSeen = "Everyone";
  String profilePhoto = "My Contacts";
  String status = "Everyone";
  bool readReceipts = true;
  bool onlineStatus = true;

  // NEW State for Disappearing Messages
  String disappearingSetting = "Off";

  // --- LOGIC: UPDATE FIRESTORE ---
  void _updatePrivacySetting(String field, dynamic value) {
    FirebaseFirestore.instance.collection('users').doc(currentUser?.uid).update(
      {'privacy_$field': value},
    );
  }

  // --- UI: DISAPPEARING MESSAGES PICKER ---
  void _showDisappearingMessagesPicker() {
    final List<Map<String, dynamic>> options = [
      {'label': '24 Hours', 'icon': Icons.history},
      {
        'label': '7 Days',
        'icon': Icons.calendar_view_week,
      }, // Extra standard option
      {'label': '6 Hours', 'icon': Icons.timer_outlined},
      {
        'label': 'Disappear after viewing',
        'icon': Icons.visibility_off_outlined,
      },
      {'label': 'Off', 'icon': Icons.block_outlined},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161616),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Disappearing Messages",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
              child: Text(
                "New messages will disappear from this chat after the selected duration.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
            const SizedBox(height: 10),
            ...options.map(
              (opt) => ListTile(
                leading: Icon(
                  opt['icon'],
                  color: disappearingSetting == opt['label']
                      ? const Color(0xFF8E2DE2)
                      : Colors.grey,
                ),
                title: Text(
                  opt['label'],
                  style: TextStyle(
                    color: disappearingSetting == opt['label']
                        ? Colors.white
                        : Colors.grey[400],
                    fontWeight: disappearingSetting == opt['label']
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                trailing: disappearingSetting == opt['label']
                    ? const Icon(
                        Icons.check_circle,
                        color: Color(0xFF00D2FF),
                        size: 20,
                      )
                    : null,
                onTap: () {
                  setState(() => disappearingSetting = opt['label']);
                  _updatePrivacySetting("disappearing_msg", opt['label']);
                  Navigator.pop(context);
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Privacy",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionLabel("WHO CAN SEE MY..."),

                _buildSubHeader(Icons.access_time, "Last Seen"),
                _buildSelectorGroup(
                  ["Everyone", "My Contacts", "Nobody"],
                  lastSeen,
                  (val) {
                    setState(() => lastSeen = val);
                    _updatePrivacySetting("lastSeen", val);
                  },
                ),

                const SizedBox(height: 25),
                _buildSubHeader(Icons.portrait_outlined, "Profile Photo"),
                _buildSelectorGroup(
                  ["Everyone", "My Contacts", "Nobody"],
                  profilePhoto,
                  (val) {
                    setState(() => profilePhoto = val);
                    _updatePrivacySetting("profilePhoto", val);
                  },
                ),

                const SizedBox(height: 35),
                _buildSectionLabel("PRIVACY SETTINGS"),
                _buildToggleCard(
                  "Read Receipts",
                  "Show when you've read messages",
                  Icons.visibility_outlined,
                  readReceipts,
                  (val) {
                    setState(() => readReceipts = val);
                    _updatePrivacySetting("readReceipts", val);
                  },
                ),
                const SizedBox(height: 12),
                _buildToggleCard(
                  "Online Status",
                  "Show when you're online",
                  Icons.shield_outlined,
                  onlineStatus,
                  (val) {
                    setState(() => onlineStatus = val);
                    _updatePrivacySetting("showOnline", val);
                  },
                ),

                const SizedBox(height: 12),

                // UPDATED DISAPPEARING MESSAGES TILE
                _buildClickableSettingTile(
                  "Disappearing Messages",
                  "Timer: $disappearingSetting",
                  Icons.timer_outlined,
                  onTap: _showDisappearingMessagesPicker,
                ),

                const SizedBox(height: 35),
                _buildSectionLabel("BLOCKED CONTACTS"),
                _buildBlockedContactsTile(),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- UI HELPERS ---

  Widget _buildClickableSettingTile(
    String title,
    String subtitle,
    IconData icon, {
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF161616),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
              child: Icon(icon, color: const Color(0xFF8E2DE2), size: 18),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF00D2FF),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
          ],
        ),
      ),
    );
  }

  // (The rest of the helpers like _buildToggleCard, _buildSelectorGroup, etc. stay exactly the same as before)
  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF4C535F),
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildSubHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 16),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectorGroup(
    List<String> options,
    String currentSelection,
    Function(String) onSelect,
  ) {
    return Column(
      children: options.map((option) {
        bool isSelected = option == currentSelection;
        return GestureDetector(
          onTap: () => onSelect(option),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF161616),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF8E2DE2)
                    : Colors.white.withOpacity(0.02),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  option,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[400],
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle_outline,
                    color: Color(0xFF00D2FF),
                    size: 18,
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildToggleCard(
    String title,
    String subtitle,
    IconData icon,
    bool state,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.05),
            ),
            child: Icon(icon, color: const Color(0xFF8E2DE2), size: 18),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
          Switch(
            value: state,
            onChanged: onChanged,
            activeColor: const Color(0xFF00D2FF),
            activeTrackColor: const Color(0xFF8E2DE2).withOpacity(0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockedContactsTile() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.redAccent.withOpacity(0.1),
            ),
            child: const Icon(
              Icons.person_remove_outlined,
              color: Colors.redAccent,
              size: 18,
            ),
          ),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Blocked Contacts",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "3 contacts blocked",
                  style: TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
        ],
      ),
    );
  }
}
