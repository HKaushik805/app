import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const EditProfilePage({super.key, required this.userData});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final currentUser = FirebaseAuth.instance.currentUser;
  bool _isSaving = false;
  bool _isUploadingImage = false;

  final String cloudName = "dke7bkleb";
  final String uploadPreset = "grind_preset";

  late TextEditingController _nameController,
      _usernameController,
      _bioController,
      _emailController,
      _phoneController,
      _locationController,
      _websiteController,
      _instaController,
      _twitterController,
      _linkedinController;
  String _profilePicUrl = "";
  String _profilePicId = "";
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
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
    _profilePicUrl = widget.userData['profilePic'] ?? "";
    _profilePicId = widget.userData['profilePicId'] ?? "";
    if (widget.userData['birthday'] != null)
      _selectedDate = (widget.userData['birthday'] as Timestamp).toDate();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _websiteController.dispose();
    _instaController.dispose();
    _twitterController.dispose();
    _linkedinController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image == null) return;
    setState(() => _isUploadingImage = true);

    try {
      final Uint8List bytes = await image.readAsBytes();
      var url = Uri.parse(
        "https://api.cloudinary.com/v1_1/$cloudName/image/upload",
      );
      var request = http.MultipartRequest("POST", url);
      request.fields['upload_preset'] = uploadPreset;
      request.fields['folder'] = "profile_pics";
      request.fields['public_id'] =
          currentUser!.uid; // Overwrites old one automatically

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: '${currentUser!.uid}.jpg',
        ),
      );
      var response = await request.send();
      if (response.statusCode == 200) {
        var d = await response.stream.toBytes();
        var jsonRes = jsonDecode(String.fromCharCodes(d));
        setState(() {
          _profilePicUrl = jsonRes['secure_url'];
          _profilePicId = jsonRes['public_id'];
        });
      }
    } catch (e) {
      debugPrint("Upload Error: $e");
    } finally {
      setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    String newName = _nameController.text.trim();
    String newPic = _profilePicUrl;
    String currentStatus = widget.userData['status'] ?? "GRINDING";

    try {
      // 1. Update Master Profile
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .update({
            'name': newName,
            'username': _usernameController.text.trim().toLowerCase(),
            'subtext': _bioController.text.trim(),
            'phone': _phoneController.text.trim(),
            'location': _locationController.text.trim(),
            'website': _websiteController.text.trim(),
            'instagram': _instaController.text.trim(),
            'twitter': _twitterController.text.trim(),
            'linkedin': _linkedinController.text.trim(),
            'profilePic': newPic,
            'profilePicId': _profilePicId,
            'birthday': _selectedDate != null
                ? Timestamp.fromDate(_selectedDate!)
                : null,
          });

      // 2. Global Sync: Update all inboxes with my new info
      var myRecentChats = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('recent_chats')
          .get();

      if (myRecentChats.docs.isNotEmpty) {
        WriteBatch batch = FirebaseFirestore.instance.batch();
        for (var doc in myRecentChats.docs) {
          batch.update(
            FirebaseFirestore.instance
                .collection('users')
                .doc(doc.id)
                .collection('recent_chats')
                .doc(currentUser!.uid),
            {'name': newName, 'profilePic': newPic, 'status': currentStatus},
          );
        }
        await batch.commit();
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint("Sync Error: $e");
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
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Edit Profile",
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
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white10,
                    backgroundImage: _profilePicUrl.startsWith('http')
                        ? NetworkImage(_profilePicUrl)
                        : (_profilePicUrl.isNotEmpty
                                  ? MemoryImage(base64Decode(_profilePicUrl))
                                  : null)
                              as ImageProvider?,
                    child: _profilePicUrl.isEmpty && !_isUploadingImage
                        ? const Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  if (_isUploadingImage)
                    const Positioned.fill(
                      child: CircularProgressIndicator(
                        color: Color(0xFF8E2DE2),
                      ),
                    ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickAndUploadImage,
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
            ),
            TextButton(
              onPressed: _pickAndUploadImage,
              child: const Text(
                "Change Profile Photo",
                style: TextStyle(color: Color(0xFFA259FF)),
              ),
            ),
            const SizedBox(height: 20),
            _buildFieldLabel("Full Name"),
            _buildTextField(_nameController, "Name"),
            _buildFieldLabel("Username"),
            _buildTextField(_usernameController, "username"),
            _buildFieldLabel("Bio"),
            _buildTextField(_bioController, "Bio", maxLines: 3),
            const SizedBox(height: 32),
            _buildSectionHeader("CONTACT INFORMATION"),
            _buildFieldLabel("Email"),
            _buildTextField(_emailController, "email", enabled: false),
            _buildFieldLabel("Phone"),
            _buildTextField(_phoneController, "phone"),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) => Align(
    alignment: Alignment.centerLeft,
    child: Padding(
      padding: const EdgeInsets.only(top: 15, bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
  Widget _buildSectionHeader(String title) => Align(
    alignment: Alignment.centerLeft,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF4C535F),
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    ),
  );
  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
    bool enabled = true,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      enabled: enabled,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFF161616),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
