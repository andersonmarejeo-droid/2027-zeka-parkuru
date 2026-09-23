import 'dart:io';

const List<String> _requiredFirebaseHosts = <String>[
  'firestore.googleapis.com',
  'firebaseappcheck.googleapis.com',
  'identitytoolkit.googleapis.com',
];

Future<bool> canResolveFirebaseServices() async {
  Future<bool> resolves(String host) async {
    try {
      final List<InternetAddress> addresses = await InternetAddress.lookup(host)
          .timeout(const Duration(seconds: 3));
      return addresses.isNotEmpty;
    } on Object {
      return false;
    }
  }

  final List<bool> results = await Future.wait<bool>(
    _requiredFirebaseHosts.map(resolves),
  );
  return results.any((bool available) => available);
}
