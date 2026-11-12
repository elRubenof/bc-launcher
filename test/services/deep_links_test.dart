import 'package:bc_launcher/services/deep_links.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  String? parse(String link) => DeepLinks.parseAdd(Uri.parse(link));

  test('reads the server of an add link', () {
    expect(
      parse('bclauncher://add?server=https://example.com'),
      'https://example.com',
    );
  });

  test('adds https:// and drops the trailing slash', () {
    expect(
      parse('bclauncher://add?server=example.com/'),
      'https://example.com',
    );
  });

  test('keeps http:// and the port', () {
    expect(
      parse('bclauncher://add?server=http%3A%2F%2F127.0.0.1%3A8787'),
      'http://127.0.0.1:8787',
    );
  });

  test('ignores other links', () {
    expect(parse('https://add?server=example.com'), isNull);
    expect(parse('bclauncher://remove?server=example.com'), isNull);
    expect(parse('bclauncher://add'), isNull);
    expect(parse('bclauncher://add?server='), isNull);
    expect(parse('bclauncher://add?server=%20%20'), isNull);
  });

  test('ignores servers that are not http(s) addresses', () {
    expect(parse('bclauncher://add?server=ftp://example.com'), isNull);
    expect(parse('bclauncher://add?server=javascript:alert(1)'), isNull);
    expect(parse('bclauncher://add?server=https://'), isNull);
  });
}
