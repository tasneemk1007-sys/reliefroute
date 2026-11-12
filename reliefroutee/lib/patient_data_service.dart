import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PatientDataService {
  static final _medicationNamePattern = RegExp(r"^[A-Za-z][A-Za-z '\-]*$");
  PatientDataService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  DocumentReference<Map<String, dynamic>> deliveryTracking(String orderId) =>
      _firestore.collection('deliveries').doc(orderId);

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchDeliveryTracking(
    String orderId,
  ) => deliveryTracking(orderId).snapshots();

  String get uid =>
      _auth.currentUser?.uid ??
      (throw StateError('A signed-in patient is required.'));

  DocumentReference<Map<String, dynamic>> get profile =>
      _firestore.collection('users').doc(uid);

  CollectionReference<Map<String, dynamic>> get medications =>
      _firestore.collection('medications');

  CollectionReference<Map<String, dynamic>> get appointments =>
      _firestore.collection('appointments');

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchProfile() =>
      profile.snapshots();

  Future<void> saveProfile(Map<String, dynamic> values) => profile.set({
    ...values,
    'uid': uid,
    'email': _auth.currentUser?.email,
    'updatedAt': FieldValue.serverTimestamp(),
    'createdAt': values['createdAt'] ?? FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));

  Stream<QuerySnapshot<Map<String, dynamic>>> watchMedications() =>
      medications.where('userId', isEqualTo: uid).snapshots();

  Future<DocumentReference<Map<String, dynamic>>> addMedication(
    Map<String, dynamic> values,
  ) {
    final name = (values['name'] as String? ?? '').trim();
    if (!_medicationNamePattern.hasMatch(name)) {
      throw ArgumentError('Medication name must contain letters only.');
    }
    return medications.add({
      ...values,
      'name': name,
      'userId': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateMedication(String id, Map<String, dynamic> values) {
    if (values.containsKey('name')) {
      final name = (values['name'] as String? ?? '').trim();
      if (!_medicationNamePattern.hasMatch(name)) {
        throw ArgumentError('Medication name must contain letters only.');
      }
      values = {...values, 'name': name};
    }
    return medications.doc(id).update({
      ...values,
      'userId': uid,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteMedication(String id) => medications.doc(id).delete();

  Stream<QuerySnapshot<Map<String, dynamic>>> watchAppointments() =>
      appointments.where('userId', isEqualTo: uid).snapshots();

  Future<DocumentReference<Map<String, dynamic>>> addAppointment(
    Map<String, dynamic> values,
  ) => appointments.add({
    ...values,
    'userId': uid,
    'status': 'requested',
    'createdAt': FieldValue.serverTimestamp(),
  });

  Future<void> updateAppointment(String id, Map<String, dynamic> values) =>
      appointments.doc(id).update({
        ...values,
        'userId': uid,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> cancelAppointment(String id) => appointments.doc(id).update({
    'status': 'cancelled',
    'updatedAt': FieldValue.serverTimestamp(),
  });

  Future<void> addPrescriptionMetadata({
    required String fileName,
    required String storagePath,
  }) => profile.collection('prescriptions').add({
    'userId': uid,
    'fileName': fileName,
    'storagePath': storagePath,
    'status': 'pending',
    'createdAt': FieldValue.serverTimestamp(),
  });
}
