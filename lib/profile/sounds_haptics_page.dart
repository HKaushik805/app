import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For HapticFeedback

class SoundsHapticsPage extends StatefulWidget {
  const SoundsHapticsPage({super.key});

  @override
  State<SoundsHapticsPage> createState() => _SoundsHapticsPageState();
}

class _SoundsHapticsPageState extends State<SoundsHapticsPage> {
  // Values for Sliders
  double masterVol = 0.8;
  double ringVol = 0.9;
  double notifyVol = 0.7;
  double mediaVol = 0.85;

  // Toggle States
  bool isVibrationOn = true;
  bool isHapticOn = true;

  // Ringtone Selection
  String selectedRingtone = "Neon Pulse";
  final List<String> ringtones = [
    "Neon Pulse",
    "Digital Chime",
    "Cyber Wave",
    "Electric Dreams",
    "Gradient Flow",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Sounds & Haptics",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 600,
          ), // Responsive constraint
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionLabel("VOLUME"),
                _buildVolumeSlider(
                  "Master Volume",
                  Icons.volume_up_outlined,
                  masterVol,
                  (val) {
                    setState(() => masterVol = val);
                  },
                ),
                _buildVolumeSlider("Ringtone", Icons.phone_outlined, ringVol, (
                  val,
                ) {
                  setState(() => ringVol = val);
                }),
                _buildVolumeSlider(
                  "Notifications",
                  Icons.notifications_none_outlined,
                  notifyVol,
                  (val) {
                    setState(() => notifyVol = val);
                  },
                ),
                _buildVolumeSlider(
                  "Media",
                  Icons.music_note_outlined,
                  mediaVol,
                  (val) {
                    setState(() => mediaVol = val);
                  },
                ),

                const SizedBox(height: 30),
                _buildSectionLabel("VIBRATION & HAPTICS"),
                _buildToggleCard(
                  "Vibration",
                  "Vibrate on calls and notifications",
                  Icons.vibration,
                  isVibrationOn,
                  (val) {
                    setState(() => isVibrationOn = val);
                    if (val) HapticFeedback.mediumImpact();
                  },
                ),
                const SizedBox(height: 12),
                _buildToggleCard(
                  "Haptic Feedback",
                  "Feel taps and gestures",
                  Icons.edgesensor_high_outlined,
                  isHapticOn,
                  (val) {
                    setState(() => isHapticOn = val);
                    if (val) HapticFeedback.lightImpact();
                  },
                ),

                const SizedBox(height: 30),
                _buildSectionLabel("RINGTONES & SOUNDS"),
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    "Call Ringtone",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                ...ringtones.map((name) => _buildRingtoneItem(name)).toList(),

                const SizedBox(height: 24),
                _buildTestButton(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- VOLUME SLIDER WIDGET ---
  Widget _buildVolumeSlider(
    String label,
    IconData icon,
    double value,
    ValueChanged<double> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: Colors.grey, size: 20),
                  const SizedBox(width: 15),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Text(
                "${(value * 100).toInt()}%",
                style: const TextStyle(
                  color: Color(0xFF00D2FF),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              activeTrackColor:
                  Colors.transparent, // We'll use the stack for gradient
              inactiveTrackColor: Colors.white.withOpacity(0.1),
              thumbColor: const Color(0xFF00D2FF),
              overlayColor: const Color(0xFF00D2FF).withOpacity(0.2),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                // THE GRADIENT TRACK
                LayoutBuilder(
                  builder: (context, constraints) {
                    return Container(
                      height: 4,
                      width: constraints.maxWidth * value,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8E2DE2), Color(0xFF00D2FF)],
                        ),
                      ),
                    );
                  },
                ),
                Slider(
                  value: value,
                  onChanged: (val) {
                    onChanged(val);
                    if (isHapticOn) HapticFeedback.selectionClick();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- TOGGLE CARD WIDGET ---
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

  // --- RINGTONE ITEM WIDGET ---
  Widget _buildRingtoneItem(String name) {
    bool isSelected = selectedRingtone == name;
    return GestureDetector(
      onTap: () => setState(() => selectedRingtone = name),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF161616),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF8E2DE2)
                : Colors.white.withOpacity(0.02),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
                fontSize: 14,
              ),
            ),
            if (isSelected)
              const Icon(Icons.check, color: Color(0xFF8E2DE2), size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildTestButton() {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.vibrate();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Playing $selectedRingtone...")),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: const Center(
          child: Text(
            "Test Ringtone",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 10),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF4C535F),
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}
