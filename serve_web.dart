import 'dart:io';

const Map<String, String> mimeTypes = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'application/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.webp': 'image/webp',
  '.svg': 'image/svg+xml',
  '.wasm': 'application/wasm',
  '.otf': 'font/otf',
  '.ttf': 'font/ttf',
  '.woff': 'font/woff',
  '.woff2': 'font/woff2',
};

void main() async {
  final webDir = Directory('F:/App/KHTL/build/web');
  if (!webDir.existsSync()) {
    print('[LOI] Khong tim thay thu muc build/web! Vui long chay build_web.bat truoc.');
    exit(1);
  }

  const port = 8080;
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
  print('========================================================');
  print('   MAY CHU THU NGHIEM WEB - KHOA HOC TAM LINH');
  print('   Dang phat tai: http://localhost:$port');
  print('========================================================');
  print('   Nhan Ctrl + C trong cua so nay de tat may chu.\n');

  // Auto open browser
  try {
    Process.run('cmd', ['/c', 'start', 'http://localhost:$port']);
  } catch (_) {}

  await for (HttpRequest request in server) {
    try {
      var path = request.uri.path;

      // TTS Proxy to bypass Chrome referer block
      if (path == '/api/tts') {
        final q = request.uri.queryParameters['q'] ?? '';
        final tl = request.uri.queryParameters['tl'] ?? 'vi';
        if (q.trim().isEmpty) {
          request.response.statusCode = HttpStatus.badRequest;
          await request.response.close();
          continue;
        }
        final googleUrl = 'https://translate.google.com/translate_tts?ie=UTF-8&tl=$tl&client=tw-ob&q=${Uri.encodeComponent(q)}';
        final client = HttpClient();
        try {
          final googleReq = await client.getUrl(Uri.parse(googleUrl));
          googleReq.headers.set('User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)');
          final googleRes = await googleReq.close();
          request.response.statusCode = googleRes.statusCode;
          request.response.headers.set('Content-Type', 'audio/mpeg');
          request.response.headers.set('Access-Control-Allow-Origin', '*');
          request.response.headers.set('Cache-Control', 'public, max-age=86400');
          await googleRes.pipe(request.response);
        } catch (_) {
          request.response.statusCode = HttpStatus.internalServerError;
          await request.response.close();
        } finally {
          client.close();
        }
        continue;
      }

      // Proxy /app/ images from khoahoctamlinh.vn
      if (path.startsWith('/app/')) {
        final targetUrl = 'https://khoahoctamlinh.vn$path';
        final client = HttpClient();
        try {
          final proxyReq = await client.getUrl(Uri.parse(targetUrl));
          proxyReq.headers.set('User-Agent', 'Mozilla/5.0');
          final proxyRes = await proxyReq.close();
          request.response.statusCode = proxyRes.statusCode;
          final ext = path.contains('.') ? '.${path.split('.').last.toLowerCase()}' : '';
          final mime = mimeTypes[ext] ?? 'application/octet-stream';
          request.response.headers.set('Content-Type', mime);
          request.response.headers.set('Access-Control-Allow-Origin', '*');
          request.response.headers.set('Cache-Control', 'public, max-age=86400');
          await proxyRes.pipe(request.response);
        } catch (_) {
          request.response.statusCode = HttpStatus.internalServerError;
          await request.response.close();
        } finally {
          client.close();
        }
        continue;
      }

      if (path == '/' || path.isEmpty) {
        path = '/index.html';
      }

      var file = File('${webDir.path}$path');
      if (!file.existsSync()) {
        // Fallback to index.html for Flutter Web routing
        file = File('${webDir.path}/index.html');
      }

      final ext = file.path.contains('.') ? '.${file.path.split('.').last.toLowerCase()}' : '';
      final mime = mimeTypes[ext] ?? 'application/octet-stream';

      request.response.headers.set('Content-Type', mime);
      request.response.headers.set('Access-Control-Allow-Origin', '*');
      request.response.headers.set('Cache-Control', 'no-store, no-cache, must-revalidate, max-age=0');
      await file.openRead().pipe(request.response);
    } catch (e) {
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.close();
    }
  }
}
