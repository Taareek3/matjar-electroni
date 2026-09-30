import 'package:flutter/widgets.dart';

String formatPrice(num price) {
  final String digits = price.toStringAsFixed(2);
  return '$digits\$';
}

Widget priceText(
  num price, {
  required TextStyle? style,
}) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: Text(
      formatPrice(price),
      style: style,
    ),
  );
}

String formatDate(DateTime date) {
  final String day = date.day.toString().padLeft(2, '0');
  final String month = date.month.toString().padLeft(2, '0');
  final String year = date.year.toString();
  return '$day/$month/$year';
}

String formatTime(DateTime date) {
  final String hour = date.hour.toString().padLeft(2, '0');
  final String minute = date.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String formatElapsed(Duration duration) {
  final int totalSeconds = duration.inSeconds < 0 ? 0 : duration.inSeconds;
  final int minutes = totalSeconds ~/ 60;
  final int seconds = totalSeconds % 60;
  final String minuteText = minutes.toString().padLeft(2, '0');
  final String secondText = seconds.toString().padLeft(2, '0');
  return '$minuteText:$secondText';
}
