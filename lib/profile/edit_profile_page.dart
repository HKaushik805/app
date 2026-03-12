import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const EditProfilePage({super.key, required this.userData});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final currentUser = FirebaseAuth.instance.currentUser;
  bool _isSaving = false;

  // Controllers for all the fields in your design
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _bioController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _locationController;
  late TextEditingController _websiteController;
  late TextEditingController _instaController;
  late TextEditingController _twitterController;
  late TextEditingController _linkedinController;

  String _profilePic = "";
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing data
    _nameController = TextEditingController(
      text: widget.userData['name'] ?? "",
    );
    _usernameController = TextEditingController(
      text: widget.userData['username'] ?? "",
    );
    _bioController = TextEditingController(
      text: widget.userData['subtext'] ?? "",
    );
    _emailController = TextEditingController(
      text: widget.userData['email'] ?? "",
    );
    _phoneController = TextEditingController(
      text: widget.userData['phone'] ?? "",
    );
    _locationController = TextEditingController(
      text: widget.userData['location'] ?? "",
    );
    _websiteController = TextEditingController(
      text: widget.userData['website'] ?? "",
    );
    _instaController = TextEditingController(
      text: widget.userData['instagram'] ?? "",
    );
    _twitterController = TextEditingController(
      text: widget.userData['twitter'] ?? "",
    );
    _linkedinController = TextEditingController(
      text: widget.userData['linkedin'] ?? "",
    );
    _profilePic = widget.userData['profilePic'] ?? "";

    // Parse existing birthday if it exists
    if (widget.userData['birthday'] != null) {
      _selectedDate = (widget.userData['birthday'] as Timestamp).toDate();
    }
  }

  // --- IMAGE PICKER LOGIC ---
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 200,
      maxHeight: 200,
      imageQuality: 70,
    );
    if (image == null) return;
    Uint8List bytes = await image.readAsBytes();
    setState(() => _profilePic = base64Encode(bytes));
  }

  // --- DATE PICKER LOGIC ---
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(1995, 8, 15),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  // --- SAVE LOGIC ---
  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .update({
            'name': _nameController.text.trim(),
            'username': _usernameController.text.trim(),
            'subtext': _bioController.text.trim(),
            'phone': _phoneController.text.trim(),
            'location': _locationController.text.trim(),
            'website': _websiteController.text.trim(),
            'instagram': _instaController.text.trim(),
            'twitter': _twitterController.text.trim(),
            'linkedin': _linkedinController.text.trim(),
            'profilePic': _profilePic,
            'birthday': _selectedDate != null
                ? Timestamp.fromDate(_selectedDate!)
                : null,
          });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isSaving = false);
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
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Edit Profile",
          style: TextStyle(fontWeight: FontWeight.bold),
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
                onPressed: _isSaving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // --- PROFILE PHOTO SECTION ---
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.white10,
                        backgroundImage: _profilePic.isNotEmpty
                            ? MemoryImage(base64Decode(_profilePic))
                            : null,
                        child: _profilePic.isEmpty
                            ? const Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Color(0xFFD633FF),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: _pickImage,
                    child: const Text(
                      "Change Profile Photo",
                      style: TextStyle(color: Color(0xFFA259FF)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --- INPUT FIELDS ---
            _buildFieldLabel("Full Name"),
            _buildTextField(_nameController, "Your Name"),

            _buildFieldLabel("Username"),
            _buildTextField(_usernameController, "username"),

            _buildFieldLabel("Bio"),
            _buildTextField(
              _bioController,
              "What's on your mind?",
              maxLines: 3,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "${_bioController.text.length}/150",
                style: const TextStyle(color: Colors.grey, fontSize: 10),
              ),
            ),

            const SizedBox(height: 20),
            _buildSectionHeader("CONTACT INFORMATION"),
            _buildFieldLabel("Email"),
            _buildTextField(
              _emailController,
              "email@example.com",
              enabled: false,
            ), // Email usually fixed

            _buildFieldLabel("Phone"),
            _buildTextField(_phoneController, "+1 (555) 000-0000"),

            const SizedBox(height: 20),
            _buildSectionHeader("PERSONAL INFORMATION"),
            _buildFieldLabel("Birthday"),
            GestureDetector(
              onTap: _selectDate,
              child: _buildTextField(
                TextEditingController(
                  text: _selectedDate == null
                      ? ""
                      : DateFormat('dd-MM-yyyy').format(_selectedDate!),
                ),
                "DD-MM-YYYY",
                enabled: false,
                suffixIcon: Icons.calendar_today_outlined,
              ),
            ),

            _buildFieldLabel("Location"),
            _buildTextField(_locationController, "City, Country"),

            const SizedBox(height: 20),
            _buildSectionHeader("SOCIAL LINKS"),
            _buildFieldLabel("Website"),
            _buildTextField(_websiteController, "yourwebsite.com"),
            _buildFieldLabel("Instagram"),
            _buildTextField(_instaController, "@username"),
            _buildFieldLabel("Twitter"),
            _buildTextField(_twitterController, "@username"),
            _buildFieldLabel("LinkedIn"),
            _buildTextField(_linkedinController, "profile-link"),

            const SizedBox(height: 100), // Bottom padding
          ],
        ),
      ),
    );
  }

  // --- UI COMPONENTS ---
  Widget _buildFieldLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(top: 15, bottom: 8),
        child: Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(
          title,
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

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
    bool enabled = true,
    IconData? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      enabled: enabled,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      onChanged: (val) => setState(() {}), // Refresh character count
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white10),
        filled: true,
        fillColor: const Color(0xFF161616),
        suffixIcon: suffixIcon != null
            ? Icon(suffixIcon, color: Colors.grey, size: 18)
            : null,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
