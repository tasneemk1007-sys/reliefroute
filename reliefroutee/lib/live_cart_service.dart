
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class LiveCartService {
  LiveCartService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : db = firestore ??
            FirebaseFirestore.instanceFor(
              app: Firebase.app(),
              databaseId: 'reliefroute4',
            ),
        auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore db;
  final FirebaseAuth auth;

  String get uid =>
      auth.currentUser?.uid ?? (throw StateError('Sign in required'));

  CollectionReference<Map<String, dynamic>> get items =>
      db.collection('users').doc(uid).collection('cart');

  Stream<QuerySnapshot<Map<String, dynamic>>> watch() =>
      items.orderBy('name').snapshots();

  Future<void> add(Map<String, dynamic> medicine) async {
    final ref = items.doc('${medicine['id']}');
    final old = await ref.get();

    await ref.set({
      ...medicine,
      'quantity': (old.data()?['quantity'] ?? 0) + 1,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> change(String id, int quantity) =>
      quantity <= 0
          ? items.doc(id).delete()
          : items.doc(id).update({
              'quantity': quantity,
              'updatedAt': FieldValue.serverTimestamp(),
            });

  Future<void> clear() async {
    for (final doc in (await items.get()).docs) {
      await doc.reference.delete();
    }
  }
}
