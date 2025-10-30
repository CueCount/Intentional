import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewCaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Generate case ID
  String _generateCaseId(String userId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'case_${userId}_$timestamp';
  }

  // Create flagged case when user is reported
  Future<String> createFlaggedCase({
    required String userId,
    required String flaggedByUserId,
    required String reason,
    String? chatId,
  }) async {
    try {
      final caseId = _generateCaseId(userId);
      
      // Build the note with available information
      String note = reason;
      if (chatId != null) {
        note = 'This user had an inappropriate comment made in chat_$chatId, and was flagged. Reason: $reason';
      }

      final caseData = {
        'caseId': caseId,
        'userId': userId,
        'type': 'flagged',
        'status': 'pending',
        'note': note,
        'created': Timestamp.fromDate(DateTime.now()),
        'closed': null,
        'flaggedByUserId': flaggedByUserId,
        'relatedChatId': chatId,
      };

      // Create the case document
      await _firestore
          .collection('cases')
          .doc(caseId)
          .set(caseData);

      print('Flag case created: $caseId');
      return caseId;

    } catch (e) {
      print('Error creating flag case: $e');
      throw Exception('Failed to create flag case: $e');
    }
  }

}
