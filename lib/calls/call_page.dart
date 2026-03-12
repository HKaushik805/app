import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CallPage extends StatelessWidget {
  const CallPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- APP BAR ---
            // Using StreamBuilder to show YOUR real status in the header
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUser?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                String status = "GRINDING";
                if (snapshot.hasData && snapshot.data!.exists) {
                  var data = snapshot.data!.data() as Map<String, dynamic>;
                  status = data['status'] ?? "GRINDING";
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 20,
                        child: Icon(
                          Icons.person,
                          color: Colors.black,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Calls",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  "● ",
                                  style: TextStyle(
                                    color: status == "OFFLINE"
                                        ? Colors.grey
                                        : (status == "AWAY"
                                              ? Colors.yellow
                                              : Colors.orange),
                                    fontSize: 10,
                                  ),
                                ),
                                Text(
                                  status,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.search, color: Colors.white),
                      const SizedBox(width: 15),
                      const Icon(Icons.more_vert, color: Colors.white),
                    ],
                  ),
                );
              },
            ),

            // --- NEW CALL BUTTON ---
            Padding(
              padding: const EdgeInsets.all(16.0),
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
                    Icon(Icons.phone_outlined, color: Colors.white),
                    const SizedBox(width: 10),
                    const Text(
                      "New Call",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Padding(
              padding: EdgeInsets.only(left: 16, top: 10, bottom: 10),
              child: Text(
                "RECENT CALLS",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ),

            // --- CALL LIST ---
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: const [
                  CallTile(
                    name: "Alex Chen",
                    status: "12:34",
                    time: "2:45 PM",
                    typeIcon: Icons.call_received,
                    typeColor: Colors.green,
                    actionIcon: Icons.phone_outlined,
                  ),
                  CallTile(
                    name: "Alice Thompson",
                    status: "08:15",
                    time: "11:20 AM",
                    typeIcon: Icons.videocam_outlined,
                    typeColor: Colors.green,
                    actionIcon: Icons.videocam_outlined,
                    isVideo: true,
                  ),
                  CallTile(
                    name: "Design Team",
                    status: "Missed",
                    time: "9:15 AM",
                    typeIcon: Icons.call_missed,
                    typeColor: Colors.red,
                    actionIcon: Icons.phone_outlined,
                  ),
                  CallTile(
                    name: "Bob Jenkins",
                    status: "05:42",
                    time: "Yesterday",
                    typeIcon: Icons.call_made,
                    typeColor: Colors.green,
                    actionIcon: Icons.phone_outlined,
                  ),
                  CallTile(
                    name: "Charlie Davis",
                    status: "23:10",
                    time: "Yesterday",
                    typeIcon: Icons.videocam_outlined,
                    typeColor: Colors.green,
                    actionIcon: Icons.videocam_outlined,
                    isVideo: true,
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- STATEFUL CALL TILE (UI ONLY) ---
class CallTile extends StatefulWidget {
  final String name;
  final String status;
  final String time;
  final IconData typeIcon;
  final Color typeColor;
  final IconData actionIcon;
  final bool isVideo;

  const CallTile({
    super.key,
    required this.name,
    required this.status,
    required this.time,
    required this.typeIcon,
    required this.typeColor,
    required this.actionIcon,
    this.isVideo = false,
  });

  @override
  State<CallTile> createState() => _CallTileState();
}

class _CallTileState extends State<CallTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: _isHovered
                ? const Color(0xFF222222)
                : const Color(0xFF161616),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isHovered
                  ? const Color(0xFF8E2DE2).withOpacity(0.5)
                  : Colors.transparent,
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              splashColor: const Color(0xFF8E2DE2).withOpacity(0.1),
              onTap: () {
                // Future logic for starting a call
              },
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        const CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.person, color: Colors.black),
                        ),
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.black, width: 2),
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
                          Row(
                            children: [
                              Text(
                                widget.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              if (widget.isVideo) const SizedBox(width: 5),
                              if (widget.isVideo)
                                const Icon(
                                  Icons.videocam_outlined,
                                  color: Color(0xFFA259FF),
                                  size: 16,
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                widget.typeIcon,
                                color: widget.typeColor,
                                size: 14,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                "${widget.status}  •  ${widget.time}",
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.actionIcon,
                        color: Colors.grey,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
