import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DataUsagePage extends StatefulWidget {
  const DataUsagePage({super.key});

  @override
  State<DataUsagePage> createState() => _DataUsagePageState();
}

class _DataUsagePageState extends State<DataUsagePage> {
  final currentUser = FirebaseAuth.instance.currentUser;

  // Local states for toggles
  bool autoPhotos = true;
  bool autoVideos = false;
  bool autoAudio = true;
  bool autoDocs = false;
  bool lowDataMode = false;

  void _updateDataSetting(String field, bool value) {
    FirebaseFirestore.instance.collection('users').doc(currentUser?.uid).update(
      {'settings_data_$field': value},
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
          "Data Usage",
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
                _buildSectionLabel("USAGE THIS MONTH"),
                _buildTotalDataCard(),
                const SizedBox(height: 30),
                _buildSectionLabel("BREAKDOWN BY TYPE"),
                _buildTypeTile(
                  "Photos",
                  "850 MB",
                  Icons.image_outlined,
                  const Color(0xFF8E2DE2),
                ),
                _buildTypeTile(
                  "Videos",
                  "1.1 GB",
                  Icons.videocam_outlined,
                  const Color(0xFF00D2FF),
                ),
                _buildTypeTile(
                  "Audio",
                  "320 MB",
                  Icons.music_note_outlined,
                  const Color(0xFFED4264),
                ),
                _buildTypeTile(
                  "Documents",
                  "130 MB",
                  Icons.description_outlined,
                  const Color(0xFFF37335),
                ),
                const SizedBox(height: 30),
                _buildSectionLabel("AUTO-DOWNLOAD MEDIA"),
                _buildToggleTile(
                  "Photos",
                  "Auto-download when receiving",
                  Icons.image_outlined,
                  autoPhotos,
                  (v) {
                    setState(() => autoPhotos = v);
                    _updateDataSetting("autoPhotos", v);
                  },
                ),
                _buildToggleTile(
                  "Videos",
                  "Auto-download when receiving",
                  Icons.videocam_outlined,
                  autoVideos,
                  (v) {
                    setState(() => autoVideos = v);
                    _updateDataSetting("autoVideos", v);
                  },
                ),
                _buildToggleTile(
                  "Audio",
                  "Auto-download voice messages",
                  Icons.headset_outlined,
                  autoAudio,
                  (v) {
                    setState(() => autoAudio = v);
                    _updateDataSetting("autoAudio", v);
                  },
                ),
                _buildToggleTile(
                  "Documents",
                  "Auto-download files",
                  Icons.file_copy_outlined,
                  autoDocs,
                  (v) {
                    setState(() => autoDocs = v);
                    _updateDataSetting("autoDocs", v);
                  },
                ),
                const SizedBox(height: 30),
                _buildSectionLabel("NETWORK SETTINGS"),
                _buildToggleTile(
                  "Low Data Mode",
                  "Reduce data consumption",
                  Icons.wifi_off,
                  lowDataMode,
                  (v) {
                    setState(() => lowDataMode = v);
                    _updateDataSetting("lowData", v);
                  },
                ),
                const SizedBox(height: 20),
                _buildResetButton(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTotalDataCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF8E2DE2).withOpacity(0.2),
            const Color(0xFF00D2FF).withOpacity(0.1),
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Total Data",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const Text(
                    "2.4 GB",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                height: 50,
                width: 50,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF8E2DE2), Color(0xFF00D2FF)],
                  ),
                ),
                child: const Icon(Icons.storage, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _dataSubStat("Sent", "1.2 GB"),
              _dataSubStat("Received", "1.2 GB"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dataSubStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  Widget _buildTypeTile(String title, String size, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Container(
            height: 45,
            width: 45,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white),
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
                  size,
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
          const Icon(Icons.bar_chart, color: Colors.white10),
        ],
      ),
    );
  }

  Widget _buildToggleTile(
    String title,
    String sub,
    IconData icon,
    bool state,
    ValueChanged<bool> onChanged,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey, size: 20),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        sub,
        style: const TextStyle(color: Colors.grey, fontSize: 11),
      ),
      trailing: Switch(
        value: state,
        onChanged: onChanged,
        activeColor: const Color(0xFF00D2FF),
      ),
    );
  }

  Widget _buildResetButton() {
    return InkWell(
      onTap: () {},
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: const Center(
          child: Text(
            "Reset Data Statistics",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 10),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF4C535F),
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
