import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EmailAccessControl {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get current logged-in user email
  static String? getCurrentUserEmail() {
    return _auth.currentUser?.email;
  }

  /// Check if user email has access to a document
  static Future<bool> hasAccessToDocument(
      String collectionName, String docId) async {
    try {
      final currentEmail = getCurrentUserEmail();
      if (currentEmail == null) return false;

      final doc = await _firestore.collection(collectionName).doc(docId).get();
      if (!doc.exists) return false;

      // Check if the document's ownerEmail matches current user's email
      final ownerEmail = doc.data()?['ownerEmail'] as String?;
      return ownerEmail == currentEmail;
    } catch (e) {
      print('Error checking document access: $e');
      return false;
    }
  }

  /// Query only documents owned by current user
  static Query getUserOwnedDocuments(String collectionName) {
    final currentEmail = getCurrentUserEmail();
    if (currentEmail == null) {
      throw Exception('User not authenticated');
    }
    return _firestore
        .collection(collectionName)
        .where('ownerEmail', isEqualTo: currentEmail);
  }

  /// Add ownerEmail field when creating a document
  static Map<String, dynamic> addOwnershipData(
      Map<String, dynamic> data) {
    return {
      ...data,
      'ownerEmail': getCurrentUserEmail(),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  /// Check if only the same email can retrieve data
  static Future<List<DocumentSnapshot>> getFilteredDocuments(
      String collectionName) async {
    try {
      final query = getUserOwnedDocuments(collectionName);
      final snapshot = await query.get();
      return snapshot.docs;
    } catch (e) {
      print('Error fetching user documents: $e');
      return [];
    }
  }
}

