import 'package:intl/intl.dart';

abstract final class Formatters {
  static final _date = DateFormat('d MMM yyyy');
  static final _shortDate = DateFormat('d MMM');

  static String date(DateTime? value) =>
      value == null ? '—' : _date.format(value);

  static String shortDate(DateTime? value) =>
      value == null ? '—' : _shortDate.format(value);

  static String timeAgo(DateTime? value) {
    if (value == null) return '';
    final diff = DateTime.now().difference(value);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    return date(value);
  }

  static String greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  static String scoreLabel(int score) {
    if (score >= 85) return 'Excellent';
    if (score >= 70) return 'Strong';
    if (score >= 55) return 'Good';
    if (score >= 40) return 'Fair';
    return 'Needs work';
  }

  static String compactNumber(int value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
    return '$value';
  }

  static String initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'V';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  static String sentenceCase(String value) {
    if (value.trim().isEmpty) return value;
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }
}
