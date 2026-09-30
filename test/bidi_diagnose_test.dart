import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_customer_app/core/utils/formatters.dart';

void main() {
  testWidgets('diagnose visual glyph order of formatPrice in RTL',
      (WidgetTester tester) async {
    for (final String s in <String>[formatPrice(60.44), formatPrice(57.45)]) {
      final TextPainter painter = TextPainter(
        text: TextSpan(
          text: s,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        textDirection: TextDirection.rtl,
      )..layout();
      final StringBuffer sb = StringBuffer('RTL string="$s" => ');
      for (int i = 0; i < s.length; i++) {
        final List<TextBox> boxes = painter.getBoxesForSelection(
          TextSelection(baseOffset: i, extentOffset: i + 1),
        );
        sb.write('${s[i]}@${boxes.isEmpty ? -1 : boxes.first.left.round()} ');
      }
      debugPrint(sb.toString());
    }

    final TextPainter ltr = TextPainter(
      text: TextSpan(
        text: formatPrice(60.44),
        style: const TextStyle(fontSize: 20),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final StringBuffer sb = StringBuffer('LTR string="${formatPrice(60.44)}" => ');
    for (int i = 0; i < formatPrice(60.44).length; i++) {
      final List<TextBox> boxes = ltr.getBoxesForSelection(
        TextSelection(baseOffset: i, extentOffset: i + 1),
      );
      sb.write('${formatPrice(60.44)[i]}@${boxes.isEmpty ? -1 : boxes.first.left.round()} ');
    }
    debugPrint(sb.toString());
  });
}
