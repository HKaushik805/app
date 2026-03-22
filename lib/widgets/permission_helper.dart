import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionHelper {
  // --- LOGIC: REQUEST MICROPHONE & CAMERA ---
  static Future<bool> checkCallPermissions(
      BuildContext context, bool isVideo) async {
    // 1. Define permissions based on call type
    List<Permission> permissions = [
      Permission.microphone,
      if (isVideo) Permission.camera,
    ];

    // 2. Request and get statuses
    Map<Permission, PermissionStatus> statuses = await permissions.request();

    // 3. Check if all permissions are granted
    // We use ?.isGranted to handle null safety correctly
    bool allGranted = statuses.values.every((status) => status.isGranted);

    if (allGranted) {
      return true;
    } else {
      // 4. Show custom dialog if any permission was denied
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
        title: const Row(
          children: [
            Icon(Icons.security, color: Color(0xFF8E2DE2)),
            SizedBox(width: 12),
            Text("Permissions Needed",
                style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: Text(
          "GrindChat needs access to your ${isVideo ? 'Camera and Microphone' : 'Microphone'} to start this call. Please enable them in settings.",
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text("Cancel", style: TextStyle(color: Colors.white24)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8E2DE2),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              await openAppSettings(); // Opens device settings
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("Open Settings",
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
