import 'package:scrcpy_mcp/scrcpy_mcp.dart';

/// Result of a visual assertion against a screenshot.
class ScreenCheckResult {
  const ScreenCheckResult({required this.matched, required this.reason});

  /// Whether the model judged the expectation present on screen.
  final bool matched;

  /// The model's full reply, surfaced via `expect(..., reason: r.reason)`.
  final String reason;
}

/// Parses a raw vision-model reply into a [ScreenCheckResult].
///
/// Rules: trim, take the first line. Leading "否"/"不" → not matched;
/// leading "是" → matched; anything else (including empty) → [LlmException].
/// Checking "否"/"不" before "是" avoids the `contains('是')` misjudgment
/// where "不是" was wrongly read as a match.
ScreenCheckResult parseScreenCheckResponse(String raw) {
  final text = raw.trim();
  if (text.isEmpty) {
    throw const LlmException('Empty response from vision model');
  }
  final firstLine = text.split('\n').first.trim();
  if (firstLine.startsWith('否') || firstLine.startsWith('不')) {
    return ScreenCheckResult(matched: false, reason: text);
  }
  if (firstLine.startsWith('是')) {
    return ScreenCheckResult(matched: true, reason: text);
  }
  throw LlmException('Unparseable vision response: $raw');
}
