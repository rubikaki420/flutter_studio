import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:mime/mime.dart';

class HtmlHttpServer {
  HttpServer? _server;
  final String rootPath;
  final int port;

  HtmlHttpServer({required this.rootPath, this.port = 8080});

  Future<void> start() async {
    await stop();
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
    _server!.listen(_handleRequest);
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
  }

  bool get isRunning => _server != null;

  void _handleRequest(HttpRequest request) async {
    final path = request.uri.path;
    String fullPath = p.join(
      rootPath,
      path.startsWith('/') ? path.substring(1) : path,
    );

    // Handle directory (index.html)
    if (await FileSystemEntity.isDirectory(fullPath)) {
      fullPath = p.join(fullPath, 'index.html');
    }

    final file = File(fullPath);
    if (await file.exists()) {
      try {
        final mimeType = lookupMimeType(fullPath) ?? 'application/octet-stream';
        request.response.headers.contentType = ContentType.parse(mimeType);

        // Add CORS headers just in case
        request.response.headers.add('Access-Control-Allow-Origin', '*');

        await request.response.addStream(file.openRead());
      } catch (e) {
        request.response.statusCode = HttpStatus.internalServerError;
        request.response.write('Error: $e');
      }
    } else {
      request.response.statusCode = HttpStatus.notFound;
      request.response.write('404 Not Found');
    }
    await request.response.close();
  }
}
