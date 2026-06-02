import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ─────────────────────────────────────────
// FIREBASE SERVICE
// All data is scoped under: users/{uid}/...
// So each Google account only sees its own data
// ─────────────────────────────────────────
class FirebaseService {
  static final FirebaseFirestore _db =
      FirebaseFirestore.instance;

  // ── Get current logged-in user's UID ────
  static String get uid {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');
    return user.uid;
  }

  // ── Get current user's email ─────────────
  static String get email {
    return FirebaseAuth.instance.currentUser?.email ?? '';
  }

  // ─────────────────────────────────────────
  // COLLECTION PATHS — scoped per user UID
  // Structure: users/{uid}/members
  //            users/{uid}/attendance/{date}/records
  // ─────────────────────────────────────────

  // Members collection for current user
  static CollectionReference get membersCollection =>
      _db.collection('users').doc(uid).collection('members');

  // Attendance doc for a specific date
  static DocumentReference attendanceDoc(String dateKey) =>
      _db
          .collection('users')
          .doc(uid)
          .collection('attendance')
          .doc(dateKey);

  // Attendance records sub-collection for a specific date
  static CollectionReference attendanceRecords(
      String dateKey) =>
      _db
          .collection('users')
          .doc(uid)
          .collection('attendance')
          .doc(dateKey)
          .collection('records');

  // ─────────────────────────────────────────
  // MEMBERS — Add / Fetch / Delete
  // ─────────────────────────────────────────

  // Add a new member
  static Future<void> addMember(
      Map<String, dynamic> data) async {
    await membersCollection.add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
      'ownerUid': uid,      // store owner uid for reference
      'ownerEmail': email,  // store owner email for reference
    });
  }

  // Fetch all members for current user
  static Future<List<Map<String, dynamic>>>
  fetchMembers() async {
    final snap = await membersCollection.get();
    return snap.docs
        .map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>})
        .toList();
  }

  // Stream members (real-time updates)
  static Stream<QuerySnapshot> membersStream() =>
      membersCollection.snapshots();

  // ─────────────────────────────────────────
  // ATTENDANCE — Save / Fetch
  // ─────────────────────────────────────────

  // Save attendance for a date (batch)
  static Future<void> saveAttendance({
    required String dateKey,
    required List<Map<String, dynamic>> records,
    required Map<String, dynamic> summary,
  }) async {
    final batch = _db.batch();

    // Save each employee record as row_1, row_2 ...
    for (int i = 0; i < records.length; i++) {
      final ref = attendanceRecords(dateKey).doc('row_${i + 1}');
      batch.set(ref, {
        ...records[i],
        'ownerUid': uid,
        'savedAt':  FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    // Save summary doc
    batch.set(attendanceDoc(dateKey), {
      ...summary,
      'ownerUid':  uid,
      'ownerEmail': email,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  // Fetch attendance records for a date
  static Future<List<Map<String, dynamic>>>
  fetchAttendanceRecords(String dateKey) async {
    final snap = await attendanceRecords(dateKey)
        .orderBy('row')
        .get();
    return snap.docs
        .map((d) => d.data() as Map<String, dynamic>)
        .toList();
  }

  // Check if attendance saved for a date
  static Future<bool> isAttendanceSaved(
      String dateKey) async {
    final snap =
    await attendanceRecords(dateKey).limit(1).get();
    return snap.docs.isNotEmpty;
  }
}