import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key});

  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  // Toggle States
  bool is2FA = true;
  bool isBiometric = true;
  bool isAppLock = true;

  final currentUser = FirebaseAuth.instance.currentUser;

  // --- LOGIC: SEND PASSWORD RESET EMAIL ---
  void _handleChangePassword() async {
    if (currentUser?.email != null) {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: currentUser!.email!,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password reset email sent!"),
          backgroundColor: Colors.green,
        ),
      );
    }
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
          "Security",
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
          ), // Responsive Desktop support
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- PROTECTION STATUS HEADER ---
                _buildProtectionHeader(),

                const SizedBox(height: 30),
                _buildSectionLabel("AUTHENTICATION"),
                _buildToggleTile(
                  "Two-Factor Authentication",
                  "Extra security for your account",
                  Icons.shield_outlined,
                  is2FA,
                  (v) => setState(() => is2FA = v),
                ),
                const SizedBox(height: 12),
                _buildToggleTile(
                  "Biometric Authentication",
                  "Face ID or fingerprint",
                  Icons.smartphone_outlined,
                  isBiometric,
                  (v) => setState(() => isBiometric = v),
                ),
                const SizedBox(height: 12),
                _buildToggleTile(
                  "App Lock",
                  "Require passcode to open app",
                  Icons.lock_outline,
                  isAppLock,
                  (v) => setState(() => isAppLock = v),
                ),

                const SizedBox(height: 30),
                _buildSectionLabel("PASSWORD"),
                _buildClickableTile(
                  "Change Password",
                  "Last changed 30 days ago",
                  Icons.vpn_key_outlined,
                  onTap: _handleChangePassword,
                ),
                const SizedBox(height: 12),
                _buildClickableTile(
                  "Recovery Email",
                  "${currentUser?.email?.substring(0, 1)}***h@email.com",
                  Icons.email_outlined,
                ),

                const SizedBox(height: 30),
                _buildSectionLabel("ACTIVE SESSIONS"),
                _buildSessionCard(
                  "iPhone 14 Pro",
                  "San Francisco, CA",
                  "Active now",
                  true,
                ),
                const SizedBox(height: 12),
                _buildSessionCard(
                  "MacBook Pro",
                  "San Francisco, CA",
                  "2 hours ago",
                  false,
                ),
                const SizedBox(height: 12),
                _buildSessionCard(
                  "iPad Air",
                  "Oakland, CA",
                  "Yesterday",
                  false,
                ),

                const SizedBox(height: 30),
                _buildEndAllButton(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildProtectionHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1F16), // Dark green tint
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            height: 50,
            width: 50,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF00C853),
            ),
            child: const Icon(
              Icons.verified_user_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Account Protected",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Your account is secured with two-factor authentication and biometric lock",
                  style: TextStyle(color: Colors.greenAccent, fontSize: 11),
                ),
              ],
            ),
          ),
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

  Widget _buildToggleTile(
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
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: const BoxDecoration(
              color: Color(0xFF1F1B24),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF8E2DE2), size: 20),
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
                    fontSize: 14,
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

  Widget _buildClickableTile(
    String title,
    String subtitle,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF161616),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Container(
              height: 40,
              width: 40,
              decoration: const BoxDecoration(
                color: Color(0xFF1F1B24),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFF8E2DE2), size: 20),
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
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
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

  Widget _buildSessionCard(
    String device,
    String location,
    String time,
    bool isActive,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.02)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                height: 45,
                width: 45,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  device.contains("iPhone")
                      ? Icons.phone_iphone
                      : (device.contains("Mac")
                            ? Icons.laptop
                            : Icons.tablet_mac),
                  color: Colors.grey,
                  size: 22,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          device,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        if (isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: const Text(
                              "Active",
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    Text(
                      location,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    Text(
                      time,
                      style: TextStyle(
                        color: isActive ? const Color(0xFF00D2FF) : Colors.grey,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!isActive) ...[
            const SizedBox(height: 15),
            GestureDetector(
              onTap: () {},
              child: Container(
                width: double.infinity,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.withOpacity(0.2)),
                  color: const Color(0xFF1A0A0A),
                ),
                child: const Center(
                  child: Text(
                    "End Session",
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEndAllButton() {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        color: const Color(0xFF1A0A0A),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: const Center(
        child: Text(
          "End All Other Sessions",
          style: TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
