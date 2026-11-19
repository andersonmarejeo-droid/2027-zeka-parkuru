import 'dart:io';

Future<void> main() async {
  final ip = '100.92.60.33';
  print('Derin tarama baslatildi: $ip');

  final openPorts = <int>[];
  final checkPorts = [39745, 38745, 5555, ...List.generate(26001, (i) => 30000 + i)];

  const batchSize = 600;
  for (var i = 0; i < checkPorts.length; i += batchSize) {
    final end = (i + batchSize < checkPorts.length) ? i + batchSize : checkPorts.length;
    final batch = checkPorts.sublist(i, end);

    final futures = batch.map((p) async {
      try {
        final s = await Socket.connect(ip, p, timeout: const Duration(milliseconds: 350));
        s.destroy();
        return p;
      } catch (_) {
        return null;
      }
    });

    final results = await Future.wait(futures);
    for (final r in results) {
      if (r != null) {
        print('ACIK PORT: $r');
        openPorts.add(r);
      }
    }
    if (openPorts.isNotEmpty) break;
  }

  if (openPorts.isEmpty) {
    print('KAPALI');
  }
}
