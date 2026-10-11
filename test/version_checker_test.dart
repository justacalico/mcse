import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mcse/services/version_checker.dart';

MockClient releasesClient(List<List<Map<String, dynamic>>> pages,
    {int status = 200}) {
  var page = 0;
  return MockClient((request) async {
    expect(request.url.host, 'gitlab.com');
    expect(request.url.path, contains('/releases'));
    final body = page < pages.length ? jsonEncode(pages[page]) : '[]';
    page++;
    return http.Response(body, status);
  });
}

void main() {
  group('VersionChecker', () {
    test('reports update when a newer release exists', () async {
      final checker = VersionChecker(
        client: releasesClient([
          [
            {'tag_name': 'v1.2.0'},
            {'tag_name': 'v1.3.0'},
            {'tag_name': 'not-a-version'},
          ]
        ]),
      );
      final update = await checker.check('1.0.0');
      expect(update.updateAvailable, isTrue);
      expect(update.latestVersion, '1.3.0');
      expect(update.currentVersion, '1.0.0');
      expect(update.releaseUrl,
          'https://gitlab.com/HttpAnimations/mcse/-/releases/v1.3.0');
    });

    test('up to date when latest is not newer', () async {
      final checker = VersionChecker(
        client: releasesClient([
          [
            {'tag_name': 'v0.9.0'}
          ]
        ]),
      );
      final update = await checker.check('1.0.0');
      expect(update.updateAvailable, isFalse);
      expect(update.latestVersion, '0.9.0');
    });

    test('unparsable current version counts as update available', () async {
      final checker = VersionChecker(
        client: releasesClient([
          [
            {'tag_name': 'v1.0.0'}
          ]
        ]),
      );
      final update = await checker.check('dev');
      expect(update.updateAvailable, isTrue);
    });

    test('empty releases means no update', () async {
      final checker = VersionChecker(client: releasesClient([[]]));
      final update = await checker.check('1.0.0');
      expect(update.updateAvailable, isFalse);
      expect(update.latestVersion, '');
      expect(update.releaseUrl, VersionChecker.releasesUrl);
    });

    test('paginates until a short page', () async {
      final page1 = List.generate(
          100, (i) => {'tag_name': 'v1.0.$i'});
      final checker = VersionChecker(
        client: releasesClient([
          page1,
          [
            {'tag_name': 'v2.0.0'}
          ]
        ]),
      );
      final update = await checker.check('0.0.1');
      expect(update.latestVersion, '2.0.0');
    });

    test('throws on non-200', () {
      final checker = VersionChecker(client: releasesClient([], status: 500));
      expect(() => checker.check('1.0.0'), throwsA(isA<VersionCheckException>()));
    });

    test('throws on unexpected response shape', () {
      final client = MockClient((_) async => http.Response('{"a":1}', 200));
      final checker = VersionChecker(client: client);
      expect(() => checker.check('1.0.0'), throwsA(isA<VersionCheckException>()));
    });

    test('wraps transport errors', () {
      final client = MockClient((_) async => throw Exception('offline'));
      final checker = VersionChecker(client: client);
      expect(() => checker.check('1.0.0'), throwsA(isA<VersionCheckException>()));
    });

    test('skips malformed entries', () async {
      final checker = VersionChecker(
        client: releasesClient([
          [
            {'name': 'no tag'},
            {'tag_name': 42},
            {'tag_name': 'v1.1.0'},
          ]
        ]),
      );
      final update = await checker.check('1.0.0');
      expect(update.latestVersion, '1.1.0');
    });

    test('close releases owned client', () {
      final checker = VersionChecker();
      checker.close();
    });
  });
}
