import 'package:cloud_firestore/cloud_firestore.dart';

class CallHistoryManager {
  static Future<void> logCall({
    required String callerId,
    required String callerName,
    required String callerPic,
    required String receiverId,
    required String receiverName,
    required String receiverPic,
    required String type, // "audio" or "video"
    required String status, // "accepted", "declined", "missed", "cancelled"
  }) async {
    final timestamp = FieldValue.serverTimestamp();

    // 1. Log for Caller (Outgoing)
    await FirebaseFirestore.instance
        .collection('users')
        .doc(callerId)
        .collection('call_history')
        .add({
          'otherUserId': receiverId,
          'otherUserName': receiverName,
          'otherUserPic': receiverPic,
          'direction': 'outgoing',
          'type': type,
          'status': status,
          'timestamp': timestamp,
        });

    // 2. Log for Receiver (Incoming)
    await FirebaseFirestore.instance
        .collection('users')
        .doc(receiverId)
        .collection('call_history')
        .add({
          'otherUserId': callerId,
          'otherUserName': callerName,
          'otherUserPic': callerPic,
          'direction': 'incoming',
          'type': type,
          'status': status,
          'timestamp': timestamp,
        });
  }
}
