import 'package:flutter/services.dart';

class DeviceNarrationService {
  static const MethodChannel _channel = MethodChannel(
    'zeka_parkuru/reader_speech',
  );

  Future<bool> speak({
    required String text,
    required String languageTag,
    required void Function() onFinished,
  }) async {
    _channel.setMethodCallHandler((MethodCall call) async {
      if (call.method == 'finished' || call.method == 'stopped') {
        onFinished();
      }
      return null;
    });
    try {
      final bool? accepted = await _channel.invokeMethod<bool>(
        'speak',
        <String, Object?>{'text': text, 'languageTag': languageTag},
      );
      return accepted == true;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  Future<void> stop() async {
    try {
      await _channel.invokeMethod<void>('stop');
    } on MissingPluginException {
      // The article remains fully readable when native speech is unavailable.
    } on PlatformException {
      // Stopping speech is best-effort during a route or app lifecycle change.
    }
  }

  void dispose() => _channel.setMethodCallHandler(null);
}
