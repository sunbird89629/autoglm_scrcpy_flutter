import 'package:scrcpy_mcp/scrcpy_mcp.dart';
import 'package:test/test.dart';

import 'visual_assertion.dart';

void main() {
  group('parseScreenCheckResponse', () {
    test('leading 是 → matched', () {
      final r = parseScreenCheckResponse('是\n界面上有应用图标');
      expect(r.matched, isTrue);
      expect(r.reason, contains('应用图标'));
    });

    test('bare 是 → matched', () {
      expect(parseScreenCheckResponse('是').matched, isTrue);
    });

    test('leading 否 → not matched', () {
      expect(parseScreenCheckResponse('否\n没有看到').matched, isFalse);
    });

    test('不是 → not matched (regression for contains("是") bug)', () {
      expect(parseScreenCheckResponse('不是').matched, isFalse);
    });

    test('leading/trailing whitespace tolerated', () {
      expect(parseScreenCheckResponse('  是  ').matched, isTrue);
    });

    test('only first line decides', () {
      expect(parseScreenCheckResponse('否\n是的部分内容相似').matched, isFalse);
    });

    test('empty → throws LlmException', () {
      expect(() => parseScreenCheckResponse(''), throwsA(isA<LlmException>()));
    });

    test('whitespace-only → throws LlmException', () {
      expect(() => parseScreenCheckResponse('   \n  '),
          throwsA(isA<LlmException>()));
    });

    test('unparseable prose → throws LlmException', () {
      expect(() => parseScreenCheckResponse('这个界面看起来像桌面'),
          throwsA(isA<LlmException>()));
    });
  });
}
