import 'package:bc_launcher/utils/news_markdown.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('bold, italic and code keep their style', () {
    final [block] = NewsMarkdown.parse(
      'Hola **fuerte** y *suave* con `/spawn`',
    );
    expect(block.type, NewsBlockType.paragraph);
    expect(block.text, 'Hola fuerte y suave con /spawn');
    expect(block.spans.firstWhere((s) => s.text == 'fuerte').bold, isTrue);
    expect(block.spans.firstWhere((s) => s.text == 'suave').italic, isTrue);
    expect(block.spans.firstWhere((s) => s.text == '/spawn').code, isTrue);
  });

  test('_ is never italic', () {
    final [block] = NewsMarkdown.parse('Gana _Nyx_ar_ y __otro__');
    expect(block.text, 'Gana _Nyx_ar_ y __otro__');
    expect(block.spans.any((s) => s.italic || s.bold), isFalse);
  });

  test('headings, paragraphs and lists, nested and numbered', () {
    final blocks = NewsMarkdown.parse(
      '# Novedades\n\nUn texto\nen dos líneas\n\n- uno\n  - dentro\n- dos\n\n3. tres\n4. cuatro',
    );
    expect(blocks.map((b) => (b.type, b.text, b.marker, b.depth)).toList(), [
      (NewsBlockType.heading, 'Novedades', null, 0),
      (NewsBlockType.paragraph, 'Un texto en dos líneas', null, 0),
      (NewsBlockType.item, 'uno', '•', 0),
      (NewsBlockType.item, 'dentro', '•', 1),
      (NewsBlockType.item, 'dos', '•', 0),
      (NewsBlockType.item, 'tres', '3.', 0),
      (NewsBlockType.item, 'cuatro', '4.', 0),
    ]);
  });

  test('a code block keeps its lines', () {
    final [block] = NewsMarkdown.parse('```\n/tp 0 64 0\n/spawn\n```');
    expect(block.type, NewsBlockType.code);
    expect(block.text, '/tp 0 64 0\n/spawn');
  });

  test('only http(s) links are links', () {
    final [block] = NewsMarkdown.parse(
      '[web](https://example.com/a) y [otro](javascript:alert(1))',
    );
    expect(
      block.spans.firstWhere((s) => s.text == 'web').link,
      Uri.parse('https://example.com/a'),
    );
    expect(block.spans.firstWhere((s) => s.text == 'otro').link, isNull);
  });

  test('HTML is shown as text', () {
    final [block] = NewsMarkdown.parse('Usa <b>esto</b> & aquello');
    expect(block.text, contains('&'));
  });
}
