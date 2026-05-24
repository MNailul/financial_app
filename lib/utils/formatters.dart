import 'package:intl/intl.dart';

class Formatters {
  static String formatCurrency(double amount, String symbol) {
    if (symbol == 'Rp') {
      final formatter = NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp ',
        decimalDigits: 0,
      );
      return formatter.format(amount);
    } else {
      final formatter = NumberFormat.currency(
        locale: 'en_US',
        symbol: symbol,
        decimalDigits: 2,
      );
      return formatter.format(amount);
    }
  }

  static String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  static String formatMonthYear(DateTime date) {
    return DateFormat('MMMM yyyy', 'id_ID').format(date);
  }

  static String formatShortMonth(DateTime date) {
    return DateFormat('MMM').format(date);
  }
}
