import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'firebase_bootstrap_service.dart';

class AccountDataService {
  AccountDataService._();

  static final AccountDataService instance = AccountDataService._();

  final FirebaseBootstrapService _firebase = FirebaseBootstrapService.instance;

  Future<bool> requestOnlineDataDeletion() async {
    await _firebase.initialize(forceRetry: true);
    final User? user = FirebaseAuth.instance.currentUser;
    if (!_firebase.ready || user == null) return false;

    try {
      await FirebaseFirestore.instance
          .collection('account_deletion_requests_v1')
          .doc(user.uid)
          .set(<String, dynamic>{
            'uid': user.uid,
            'requestedAt': FieldValue.serverTimestamp(),
            'schemaVersion': 1,
          });
      // Sunucu isteği işleyip anonim Firebase kullanıcısını silecektir.
      // Yerel oyun ilerlemesi bu işlemden etkilenmez.
      await FirebaseAuth.instance.signOut();
      return true;
    } catch (error) {
      debugPrint('Online data deletion request failed: $error');
      return false;
    }
  }
}
