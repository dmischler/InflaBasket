import 'package:intl/intl.dart';

class SatsConverter {
  SatsConverter._();

  static const int satsPerBtc = 100000000;

  static int btcToSats(double btc) {
    return (btc * satsPerBtc).round();
  }

  static double satsToBtc(int sats) {
    return sats / satsPerBtc;
  }

  static int fiatToSats(double fiatAmount, double btcPrice) {
    if (btcPrice <= 0) return 0;
    final btcAmount = fiatAmount / btcPrice;
    return btcToSats(btcAmount);
  }

  static String formatSats(int sats) {
    final formatted = NumberFormat('#,###').format(sats);
    return '$formatted sats';
  }

  static String formatSatsWithFiat(int sats, double btcPrice, String currency) {
    if (btcPrice <= 0 || sats <= 0) {
      return formatSats(sats);
    }
    final btc = satsToBtc(sats);
    final fiatAmount = btc * btcPrice;
    final fiatFormatted = NumberFormat.currency(
      symbol: _currencySymbol(currency),
      decimalDigits: 2,
    ).format(fiatAmount);
    return '${formatSats(sats)} (~$fiatFormatted)';
  }

  static String _currencySymbol(String currency) {
    return switch (currency.toUpperCase()) {
      'CHF' => 'CHF',
      'EUR' => '\u20AC',
      'USD' => '\$',
      'GBP' => '\u00A3',
      _ => currency,
    };
  }
}
