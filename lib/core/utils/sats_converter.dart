import 'package:intl/intl.dart';

class SatsConverter {
  SatsConverter._();

  static const int satsPerBtc = 100000000;

  static int btcToSats(double btc) {
    return (btc * satsPerBtc).round();
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
}
