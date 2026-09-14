import 'package:intl/intl.dart';

/// Centralized utility for currency formatting in Kite CRM using Indian Rupee (₹).
class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _currencyFormatter =
      NumberFormat.currency(symbol: '₹', decimalDigits: 0);

  /// Formats a numeric value with the Indian Rupee symbol (e.g., ₹93,500).
  static String format(num value) {
    return _currencyFormatter.format(value);
  }

  /// Compact formatting with ₹ symbol (e.g., ₹25k, ₹1.2M).
  static String formatCompact(num value) {
    final d = value.toDouble();
    if (d >= 1000000) {
      return '₹${(d / 1000000).toStringAsFixed(1)}M';
    } else if (d >= 1000) {
      return '₹${(d / 1000).toStringAsFixed(0)}k';
    } else {
      return '₹${d.toStringAsFixed(0)}';
    }
  }
}
