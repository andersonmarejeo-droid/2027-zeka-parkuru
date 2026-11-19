import 'dart:io';

void main() async {
  final server = await HttpServer.bind(InternetAddress.anyIPv4, 8088);
  print('Sunucu hazir: http://localhost:8088/oyun_secim_paneli.html');

  await for (HttpRequest request in server) {
    try {
      String path = request.uri.path;
      if (path == '/' || path.isEmpty) path = '/oyun_secim_paneli.html';
      
      final file = File('.' + path.replaceAll('/', Platform.pathSeparator));
      if (await file.exists()) {
        final ext = path.split('.').last.toLowerCase();
        final contentType = switch (ext) {
          'html' => ContentType.html,
          'css' => ContentType('text', 'css'),
          'js' => ContentType('application', 'javascript'),
          'webp' => ContentType('image', 'webp'),
          'png' => ContentType('image', 'png'),
          'jpg' || 'jpeg' => ContentType('image', 'jpeg'),
          _ => ContentType.binary,
        };
        request.response.headers.contentType = contentType;
        await request.response.addStream(file.openRead());
      } else {
        request.response.statusCode = HttpStatus.notFound;
        request.response.write('Dosya bulunamadi: $path');
      }
    } catch (e) {
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.write('Hata: $e');
    } finally {
      await request.response.close();
    }
  }
}
