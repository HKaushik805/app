import 'package:flutter/material.dart';

class AppearancePage extends StatefulWidget {
  const AppearancePage({super.key});

  @override
  State<AppearancePage> createState() => _AppearancePageState();
}

class _AppearancePageState extends State<AppearancePage> {
  String selectedTheme = "Neon Dreams";

  final List<Map<String, dynamic>> themes = [
    {
      'name': 'Neon Dreams',
      'desc': 'Purple to cyan gradient',
      'colors': [const Color(0xFF8E2DE2), const Color(0xFF00D2FF)],
    },
    {
      'name': 'Sunset Vibes',
      'desc': 'Pink to orange gradient',
      'colors': [const Color(0xFFED4264), const Color(0xFFFFEDBC)],
    },
    {
      'name': 'Ocean Breeze',
      'desc': 'Green to blue gradient',
      'colors': [const Color(0xFF00B09B), const Color(0xFF96C93D)],
    },
    {
      'name': 'Electric Pulse',
      'desc': 'Red to purple gradient',
      'colors': [const Color(0xFF8E0E00), const Color(0xFF4e085e)],
    },
    {
      'name': 'Sunset Glow',
      'desc': 'Yellow to pink gradient',
      'colors': [const Color(0xFFFDC830), const Color(0xFFF37335)],
    },
    {
      'name': 'Midnight Magic',
      'desc': 'Indigo to purple gradient',
      'colors': [const Color(0xFF0F2027), const Color(0xFF2C5364)],
    },
  ];

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    final currentTheme = themes.firstWhere((t) => t['name'] == selectedTheme);
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
          "Appearance",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 700,
          ), // Same as Status Page
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionLabel("CURRENT THEME"),
                _buildCurrentThemeHeader(currentTheme),

                const SizedBox(height: 32),
                _buildSectionLabel("CHOOSE THEME"),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: 1.3, // Adjusted to look like status cards
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: themes.length,
                  itemBuilder: (context, index) =>
                      _buildThemeCard(themes[index]),
                ),

                const SizedBox(height: 32),
                _buildSectionLabel("CUSTOMIZATION"),
                _buildCustomizationTile(
                  "Chat Wallpaper",
                  "Customize your background",
                ),
                _buildCustomizationTile(
                  "Message Bubbles",
                  "Change bubble style",
                ),
                _buildCustomizationTile(
                  "Font Size",
                  "Adjust text size",
                  isFont: true,
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentThemeHeader(Map<String, dynamic> theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            height: 55,
            width: 55,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: theme['colors']),
            ),
            child: const Icon(Icons.palette_outlined, color: Colors.white),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                theme['name'],
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                theme['desc'],
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThemeCard(Map<String, dynamic> theme) {
    bool isSelected = selectedTheme == theme['name'];
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => setState(() => selectedTheme = theme['name']),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: const Color(0xFF161616),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF8E2DE2)
                  : Colors.white.withOpacity(0.05),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 30,
                width: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: theme['colors']),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                theme['name'],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomizationTile(
    String title,
    String sub, {
    bool isFont = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
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
                sub,
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
          isFont
              ? const Text(
                  "Medium",
                  style: TextStyle(
                    color: Color(0xFF00D2FF),
                    fontWeight: FontWeight.bold,
                  ),
                )
              : const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }

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
}
