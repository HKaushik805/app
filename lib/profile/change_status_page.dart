import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChangeStatusPage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const ChangeStatusPage({super.key, required this.userData});

  @override
  State<ChangeStatusPage> createState() => _ChangeStatusPageState();
}

class _ChangeStatusPageState extends State<ChangeStatusPage> {
  final currentUser = FirebaseAuth.instance.currentUser;
  bool _isSaving = false;

  late String selectedStatus;
  late TextEditingController _messageController;

  final List<Map<String, dynamic>> statusOptions = [
    {
      'name': 'GRINDING',
      'icon': Icons.local_fire_department,
      'color': Colors.orange,
    },
    {'name': 'ONLINE', 'icon': Icons.bolt, 'color': Colors.green},
    {'name': 'BUSY', 'icon': Icons.track_changes, 'color': Colors.redAccent},
    {'name': 'AWAY', 'icon': Icons.coffee, 'color': Colors.orangeAccent},
    {
      'name': 'FOCUSED',
      'icon': Icons.rocket_launch,
      'color': Colors.purpleAccent,
    },
    {
      'name': 'CHILLING',
      'icon': Icons.nightlight_round,
      'color': Colors.blueAccent,
    },
    {
      'name': 'MOTIVATED',
      'icon': Icons.star_border,
      'color': Colors.pinkAccent,
    },
    {
      'name': 'VIBING',
      'icon': Icons.favorite_border,
      'color': Colors.tealAccent,
    },
  ];

  final List<String> quickMessages = [
    "Crushing deadlines 💪",
    "In the zone 🎯",
    "Taking a break ☕",
    "Deep work mode 🚀",
    "Available to chat 💬",
    "Do not disturb 🔔",
  ];

  @override
  void initState() {
    super.initState();
    selectedStatus = widget.userData['status'] ?? "GRINDING";
    _messageController = TextEditingController(
      text: widget.userData['subtext'] ?? "",
    );
  }

  // --- LOGIC: SAVE & GLOBAL STATUS SYNC ---
  Future<void> _saveStatus() async {
    setState(() => _isSaving = true);
    try {
      // 1. Update Master Profile
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .update({
            'status': selectedStatus,
            'subtext': _messageController.text.trim(),
          });

      // 2. Global Sync: Update my status in everyone's "Recent Chats" list
      var myRecentChats = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('recent_chats')
          .get();

      if (myRecentChats.docs.isNotEmpty) {
        WriteBatch batch = FirebaseFirestore.instance.batch();
        for (var doc in myRecentChats.docs) {
          // Find the partner's inbox and update my status entry there
          DocumentReference partnerInboxRef = FirebaseFirestore.instance
              .collection('users')
              .doc(doc.id)
              .collection('recent_chats')
              .doc(currentUser!.uid);

          batch.update(partnerInboxRef, {'status': selectedStatus});
        }
        await batch.commit();
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint("Status Sync Error: $e");
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = screenWidth > 900 ? 4 : (screenWidth > 600 ? 3 : 2);

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
          "Change Status",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 10, bottom: 10),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [Color(0xFF8E2DE2), Color(0xFF00D2FF)],
                ),
              ),
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveStatus,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        "Save",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionLabel("CURRENT PREVIEW"),
                _buildCurrentStatusCard(),

                const SizedBox(height: 32),
                _buildSectionLabel("CHOOSE STATUS"),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: 1.5,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: statusOptions.length,
                  itemBuilder: (context, index) =>
                      _buildStatusOptionCard(statusOptions[index]),
                ),

                const SizedBox(height: 32),
                _buildSectionLabel("CUSTOM STATUS MESSAGE"),
                _buildStatusInput(),

                const SizedBox(height: 24),
                _buildSectionLabel("QUICK MESSAGES"),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: quickMessages
                      .map((msg) => _buildQuickMsgChip(msg))
                      .toList(),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStatusCard() {
    final currentOption = statusOptions.firstWhere(
      (e) => e['name'] == selectedStatus,
    );
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Hero(
            tag: 'status_icon_hero',
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    currentOption['color'],
                    currentOption['color'].withOpacity(0.5),
                  ],
                ),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  currentOption['icon'],
                  key: ValueKey(selectedStatus),
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedStatus,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  _messageController.text.isEmpty
                      ? "No status set"
                      : _messageController.text,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusOptionCard(Map<String, dynamic> option) {
    bool isSelected = selectedStatus == option['name'];
    return GestureDetector(
      onTap: () => setState(() => selectedStatus = option['name']),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1C1C1E) : const Color(0xFF161616),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF8E2DE2)
                : Colors.white.withOpacity(0.05),
            width: 1.5,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    option['icon'],
                    color: isSelected ? option['color'] : Colors.grey[600],
                    size: 22,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    option['name'],
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[500],
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF8E2DE2),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        TextField(
          controller: _messageController,
          maxLength: 100,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          onChanged: (val) => setState(() {}),
          decoration: InputDecoration(
            counterText: "",
            filled: true,
            fillColor: const Color(0xFF161616),
            hintText: "What are you doing?",
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 18,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          "${_messageController.text.length}/100",
          style: const TextStyle(color: Colors.grey, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildQuickMsgChip(String msg) => GestureDetector(
    onTap: () => setState(() => _messageController.text = msg),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Text(
        msg,
        style: const TextStyle(color: Colors.white70, fontSize: 13),
      ),
    ),
  );
  Widget _buildSectionLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 14, left: 4),
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
