import 'package:bemyday/features/comments/widgets/comment_mention_text_spans.dart';
import 'package:flutter/material.dart';

/// 입력 중 `@…` 멘션 구간을 굵게 표시한다. IME 조합 중에는 기본 밑줄과 함께 적용한다.
class MentionTextEditingController extends TextEditingController {
  MentionTextEditingController({super.text});

  List<InlineSpan> _mentionInlineSpans(String part, TextStyle baseStyle) {
    return commentMentionTextSpans(part, baseStyle);
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final effectiveStyle = style ?? DefaultTextStyle.of(context).style;
    final text = value.text;

    if (withComposing &&
        value.isComposingRangeValid &&
        !value.composing.isCollapsed) {
      final range = value.composing;
      final before = text.substring(0, range.start.clamp(0, text.length));
      final inside = text.substring(
        range.start.clamp(0, text.length),
        range.end.clamp(0, text.length),
      );
      final after = text.substring(range.end.clamp(0, text.length));
      final composingStyle = effectiveStyle.merge(
        const TextStyle(decoration: TextDecoration.underline),
      );
      return TextSpan(
        style: effectiveStyle,
        children: <InlineSpan>[
          ..._mentionInlineSpans(before, effectiveStyle),
          ..._mentionInlineSpans(inside, composingStyle),
          ..._mentionInlineSpans(after, effectiveStyle),
        ],
      );
    }

    return TextSpan(
      style: effectiveStyle,
      children: _mentionInlineSpans(text, effectiveStyle),
    );
  }
}
