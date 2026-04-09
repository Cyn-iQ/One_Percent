class AppFormatters {
  static String _trimTrailingZeros(String value) {
    if (!value.contains('.')) return value;
    value = value.replaceFirst(RegExp(r'0+$'), '');
    value = value.replaceFirst(RegExp(r'\.$'), '');
    return value;
  }

  static String score(double value) {
    return _trimTrailingZeros(value.toStringAsFixed(2));
  }

  static String delta(double value) {
    final prefix = value > 0 ? '+' : '';
    return '$prefix${_trimTrailingZeros(value.toStringAsFixed(2))}';
  }

  static String percentage(double value) {
    final prefix = value > 0 ? '+' : '';
    return '$prefix${value.toStringAsFixed(2)}%';
  }

  static String dateTime(DateTime time) {
    final y = time.year.toString().padLeft(4, '0');
    final m = time.month.toString().padLeft(2, '0');
    final d = time.day.toString().padLeft(2, '0');
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }

  static String day(DateTime time) {
    final y = time.year.toString().padLeft(4, '0');
    final m = time.month.toString().padLeft(2, '0');
    final d = time.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}