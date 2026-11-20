// Unit test `CloudinaryService` — kredensial tak lengkap (best-effort null,
// tanpa exception) dan jalur sukses upload via fake HTTP client (tanpa
// jaringan nyata).

import 'dart:convert';
import 'dart:io';

import 'package:cloudinary/cloudinary.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:pbl_sem5/core/network/cloudinary_service.dart';

/// Fake `http.Client`: tidak menyentuh jaringan, mengembalikan respons
/// Upload API berisi `secure_url`.
class _FakeHttpClient extends http.BaseClient {
  Uri? lastUrl;
  String lastBody = '';

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    lastUrl = request.url;
    final bytes = <int>[];
    await for (final chunk in request.finalize()) {
      bytes.addAll(chunk);
    }
    lastBody = utf8.decode(bytes, allowMalformed: true);
    final response = jsonEncode(<String, Object?>{
      'secure_url':
          'https://res.cloudinary.com/test-cloud/image/upload/v123/test.jpg',
      'public_id': 'roastmate/analyses/test',
    });
    return http.StreamedResponse(
      Stream<List<int>>.value(utf8.encode(response)),
      200,
      request: request,
      headers: {'content-type': 'application/json'},
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late File tmpFile;

  setUp(() async {
    dotenv.clean();
    final uniqueId = DateTime.now().microsecondsSinceEpoch;
    tmpFile = File(
      '${Directory.systemTemp.path}/roastmate_cloudinary_test_$uniqueId.jpg',
    );
    // Byte JPEG minimal (magic number) agar source file valid.
    await tmpFile.writeAsBytes(<int>[0xFF, 0xD8, 0xFF, 0xD9]);
  });

  tearDown(() async {
    try {
      if (await tmpFile.exists()) {
        await tmpFile.delete();
      }
    } catch (_) {
      // Windows lock handling best-effort
    }
  });

  group('CloudinaryService', () {
    test('dotenv belum di-load → null tanpa exception', () async {
      expect(dotenv.isInitialized, isFalse);
      final url = await CloudinaryService().uploadImage(tmpFile);
      expect(url, isNull);
    });

    test('kredensial tidak lengkap → null tanpa exception', () async {
      dotenv.loadFromString(envString: 'CLOUD_NAME=test-cloud');
      final url = await CloudinaryService().uploadImage(tmpFile);
      expect(url, isNull);
    });

    test('upload sukses (client fake) → secure_url + request tersign',
        () async {
      final fake = _FakeHttpClient();
      final cloudinary = Cloudinary.signed(
        cloudName: 'test-cloud',
        apiKey: 'test-key',
        apiSecret: 'test-secret',
        client: fake,
      );
      final url = await CloudinaryService(client: cloudinary).uploadImage(
        tmpFile,
      );

      expect(url, 'https://res.cloudinary.com/test-cloud/image/upload/v123/test.jpg');
      expect(fake.lastUrl?.path, '/v1_1/test-cloud/image/upload');
      // Multipart body membawa kredensial + signature signed request.
      expect(fake.lastBody, contains('api_key'));
      expect(fake.lastBody, contains('signature'));
    });

    test('respons tanpa secure_url → null (best-effort)', () async {
      final cloudinary = Cloudinary.signed(
        cloudName: 'test-cloud',
        apiKey: 'k',
        apiSecret: 's',
        client: _HttpClientNoSecureUrl(),
      );
      final url = await CloudinaryService(client: cloudinary).uploadImage(
        tmpFile,
      );
      expect(url, isNull);
    });
  });
}

/// Fake yang mengembalikan respons valid tanpa field `secure_url`.
class _HttpClientNoSecureUrl extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    request.finalize().drain<void>();
    return http.StreamedResponse(
      Stream<List<int>>.value(utf8.encode('{"public_id":"x"}')),
      200,
      request: request,
      headers: {'content-type': 'application/json'},
    );
  }
}
