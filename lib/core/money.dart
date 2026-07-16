import 'package:intl/intl.dart';

/// Single source of truth for money formatting across the app.
///
/// The platform currency is XAF (Central African CFA franc), which is a
/// zero-decimal currency — amounts are whole numbers, there are no cents.
/// Displayed as e.g. "5 000 FCFA".
class Money {
  static final NumberFormat _fmt = NumberFormat.decimalPattern('fr');

  /// Format an amount as XAF, e.g. `Money.xaf(5000)` -> "5 000 FCFA".
  static String xaf(num? amount) {
    final v = (amount ?? 0).round();
    return '${_fmt.format(v)} FCFA';
  }

  /// Just the grouped number without the suffix, e.g. "5 000".
  static String amount(num? amount) => _fmt.format((amount ?? 0).round());

  static const String code = 'XAF';
  static const String symbol = 'FCFA';
}
