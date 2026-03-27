import 'package:flutter/material.dart';

/// `@` 뒤 공백이 아닌 문자열(멘션)을 [mentionStyle]로, 나머지는 [baseStyle]로 나눈다.
List<TextSpan> commentMentionTextSpans(
  String text,
  TextStyle baseStyle, {
  TextStyle? mentionStyle,
}) {
  final mention =
      mentionStyle ?? baseStyle.copyWith(fontWeight: FontWeight.bold);
  final regex = RegExp(r'@\S+');
  final spans = <TextSpan>[];
  var last = 0;
  for (final m in regex.allMatches(text)) {
    if (m.start > last) {
      spans.add(TextSpan(
        text: text.substring(last, m.start),
        style: baseStyle,
      ));
    }
    spans.add(TextSpan(
      text: text.substring(m.start, m.end),
      style: mention,
    ));
    last = m.end;
  }
  if (last < text.length) {
    spans.add(TextSpan(text: text.substring(last), style: baseStyle));
  }
  if (spans.isEmpty) {
    spans.add(TextSpan(text: text, style: baseStyle));
  }
  return spans;
}
