import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _idrFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static String formatIdr(num amount) => _idrFormat.format(amount);

  static String formatSlotTimeRange(DateTime startAt, DateTime endAt) {
    final timeFmt = DateFormat('HH:mm');
    return '${timeFmt.format(startAt)} - ${timeFmt.format(endAt)}';
  }

  static String formatFullDate(DateTime date) {
    return DateFormat('EEE, dd MMM yyyy').format(date);
  }
}
