import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  final now = DateTime.now();
  final snapshot = await FirebaseFirestore.instance.collection('secrets').get();
  
  print("TOTAL SECRETS: ${snapshot.docs.length}");
  
  for (var doc in snapshot.docs) {
    print("Secret ${doc.id}:");
    print(" - isHidden: ${doc.data()['isHidden']}");
    print(" - expiresAt: ${doc.data()['expiresAt']}");
    print(" - lat/lng: ${doc.data()['lat']}, ${doc.data()['lng']}");
  }
}
