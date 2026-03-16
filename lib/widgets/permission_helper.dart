import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionHelper {
  // --- LOGIC: REQUEST MICROPHONE & CAMERA ---
  static Future<bool> checkCallPermissions(
    BuildContext context,
    bool isVideo,
  ) async {
    // 1. Request permissions
    Map<Permission, PermissionStatus> statuses = await [
      Permission.microphone,
      if (isVideo) Permission.camera,
    ].request();

    // 2. Check if all are granted
    bool allGranted = statuses.values.every((status) => status.isGranted);

    if (allGranted) {
      return true;
    } else {
      // 3. Show custom dialog if denied
      if (context.mounted) {
        _showPermissionDialog(context, isVideo);
      }
      return false;
    }
  }

  // --- UI: GRINDCHAT STYLED PERMISSION DIALOG ---
  static void _showPermissionDialog(BuildContext context, bool isVideo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161616),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: Row(
          children: [
            const Icon(Icons.security, color: Color(0xFF8E2DE2)),
            const SizedBox(width: 12),
            const Text(
              "Permissions Needed",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          "GrindChat needs access to your ${isVideo ? 'Camera and Microphone' : 'Microphone'} to start this call. Please enable them in settings.",
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Colors.white24),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                colors: [Color(0xFF8E2DE2), Color(0xFF00D2FF)],
              ),
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
              ),
              onPressed: () {
                openAppSettings(); // Native function to open phone settings
                Navigator.pop(context);
              },
              child: const Text(
                "Open Settings",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
