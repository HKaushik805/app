import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

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
          "About",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildLogoHeader(),
            const SizedBox(height: 30),
            _buildVersionInfo(),
            const SizedBox(height: 30),
            _buildSectionLabel("FEATURES"),
            _buildFeaturesGrid(),
            const SizedBox(height: 30),
            _buildSectionLabel("WHAT'S NEW IN V2.4"),
            _buildUpdatesBox(),
            const SizedBox(height: 30),
            _buildSectionLabel("TEAM"),
            _buildTeamTile(
              "Product Design",
              "Design Team",
              Icons.groups_outlined,
            ),
            _buildTeamTile("Engineering", "Dev Team", Icons.code),
            _buildTeamTile("Security", "Security Team", Icons.security),
            const SizedBox(height: 30),
            _buildSectionLabel("MORE INFORMATION"),
            _buildInfoLink("Privacy Policy"),
            _buildInfoLink("Terms of Service"),
            _buildInfoLink("Licenses"),
            const SizedBox(height: 40),
            const Text(
              "Made with ❤️ by the GrindChat team",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 10),
            const Text(
              "© 2024 GrindChat Inc.",
              style: TextStyle(color: Colors.white24, fontSize: 10),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoHeader() {
    return Column(
      children: [
        Container(
          height: 100,
          width: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: const LinearGradient(
              colors: [Color(0xFF8E2DE2), Color(0xFF00D2FF)],
            ),
          ),
          child: const Center(
            child: Text(
              "G",
              style: TextStyle(
                color: Colors.white,
                fontSize: 50,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 15),
        const Text(
          "GrindChat",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Text(
          "Stay connected. Stay grinding.",
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildVersionInfo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _infoItem("Version", "2.4.1"),
        _infoItem("Build", "1542"),
        _infoItem("Released", "Feb 20, 2024"),
      ],
    );
  }

  Widget _infoItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturesGrid() {
    final features = [
      "End-to-end encryption",
      "Voice & video calls",
      "Stories & status",
      "Group conversations",
      "Media sharing",
      "Cross-platform sync",
    ];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: features
          .map(
            (f) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF161616),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFF8E2DE2),
                    size: 14,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    f,
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildUpdatesBox() {
    final updates = [
      "Enhanced story viewer",
      "Improved call quality",
      "New theme options",
      "Bug fixes & performance",
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF8E2DE2).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: updates
            .map(
              (u) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Text(
                      "• ",
                      style: TextStyle(
                        color: Color(0xFF00D2FF),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      u,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildTeamTile(String title, String team, IconData icon) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.white.withOpacity(0.05),
        child: Icon(icon, color: Colors.grey, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        team,
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      ),
    );
  }

  Widget _buildInfoLink(String title) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
      trailing: const Icon(Icons.open_in_new, color: Colors.white24, size: 16),
      onTap: () {},
    );
  }

  Widget _buildSectionLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
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
}
