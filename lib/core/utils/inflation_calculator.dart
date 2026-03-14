import 'package:collection/collection.dart';
import 'package:inflabasket/core/database/database.dart';
import 'package:inflabasket/core/models/unit.dart';

class PriceEntry {
  const PriceEntry({required this.date, required this.price});

  final DateTime date;
  final double price;
}

class TrackedProduct {
  const TrackedProduct({
    required this.name,
    required this.isActive,
    required this.priceHistory,
  });

  final String name;
  final bool isActive;
  final List<PriceEntry> priceHistory;
}

class ChartPoint {
  const ChartPoint({
    required this.date,
    required this.inflationPct,
    this.contributingProducts = 0,
    this.jumpDrivers = const [],
  });

  final DateTime date;
  final double inflationPct;
  final int contributingProducts;
  final List<String> jumpDrivers;
}

class ReceiptItem {
  const ReceiptItem({
    required this.name,
    required this.price,
    this.isActive = true,
  });

  final String name;
  final double price;
  final bool isActive;
}

class InflationCalculator {
  static double _normalizedUnitPrice(PurchaseEntry e) {
    final price = e.price;
    final quantity = e.quantity;
    if (!price.isFinite || !quantity.isFinite || quantity <= 0 || price <= 0) {
      return 0;
    }
    return unitTypeFromString(e.unit).normalizedPrice(price, quantity);
  }

  static double? _lastPriceOnOrBefore(
      List<PriceEntry> sorted, DateTime target) {
    final found = sorted.lastWhereOrNull((e) => !e.date.isAfter(target));
    if (found == null || !found.price.isFinite || found.price <= 0) {
      return null;
    }
    return found.price;
  }

  static double? productPercentChange(
    TrackedProduct p,
    DateTime start,
    DateTime end,
  ) {
    if (!p.isActive || p.priceHistory.isEmpty || start.isAfter(end))
      return null;
    final history = List<PriceEntry>.from(p.priceHistory)
      ..sort((a, b) => a.date.compareTo(b.date));
    final startPrice = _lastPriceOnOrBefore(history, start);
    final endPrice = _lastPriceOnOrBefore(history, end);
    if (startPrice == null || endPrice == null) return null;
    return ((endPrice - startPrice) / startPrice) * 100;
  }

  static double? overallInflationPercent(
    DateTime start,
    DateTime end,
    List<TrackedProduct> products,
  ) {
    if (start.isAfter(end)) return null;
    final values = products
        .where((p) => p.isActive)
        .map((p) => productPercentChange(p, start, end))
        .whereType<double>()
        .toList();
    if (values.isEmpty) return null;
    return values.average;
  }

  static List<ChartPoint> generateInflationChart(
    DateTime baseline,
    DateTime endDate,
    List<TrackedProduct> products,
  ) {
    if (baseline.isAfter(endDate)) return const [];
    final activeProducts = products.where((p) => p.isActive).toList();
    final dateSet = <DateTime>{baseline, endDate};

    for (final product in activeProducts) {
      for (final entry in product.priceHistory) {
        if (!entry.date.isBefore(baseline) && !entry.date.isAfter(endDate)) {
          dateSet.add(entry.date);
        }
      }
    }

    final dates = dateSet.toList()..sort();
    final points = <ChartPoint>[];
    for (final d in dates) {
      final changes = <double>[];
      final jumpDrivers = <String>[];
      for (final p in activeProducts) {
        final c = productPercentChange(p, baseline, d);
        if (c != null) {
          changes.add(c);
        }
        final changedToday = p.priceHistory.any((e) =>
            e.date.year == d.year &&
            e.date.month == d.month &&
            e.date.day == d.day);
        if (changedToday) jumpDrivers.add(p.name);
      }

      final inflation = d == baseline
          ? 0.0
          : (changes.isEmpty
              ? points.lastOrNull?.inflationPct ?? 0.0
              : changes.average);

      points.add(ChartPoint(
        date: d,
        inflationPct: inflation,
        contributingProducts: changes.length,
        jumpDrivers: jumpDrivers,
      ));
    }

    return points;
  }

  static List<TrackedProduct> importReceiptMonth(
    DateTime receiptDate,
    List<ReceiptItem> scannedItems,
    List<TrackedProduct> existingProducts,
  ) {
    final byName = {
      for (final p in existingProducts) p.name.trim().toLowerCase(): p,
    };

    for (final item in scannedItems) {
      final normalizedName = item.name.trim();
      if (normalizedName.isEmpty || !item.price.isFinite || item.price <= 0) {
        continue;
      }

      final key = normalizedName.toLowerCase();
      final existing = byName[key];
      if (existing == null) {
        byName[key] = TrackedProduct(
          name: normalizedName,
          isActive: item.isActive,
          priceHistory: [PriceEntry(date: receiptDate, price: item.price)],
        );
      } else {
        final history = List<PriceEntry>.from(existing.priceHistory)
          ..add(PriceEntry(date: receiptDate, price: item.price))
          ..sort((a, b) => a.date.compareTo(b.date));
        byName[key] = TrackedProduct(
          name: existing.name,
          isActive: existing.isActive,
          priceHistory: history,
        );
      }
    }

    return byName.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  static TrackedProduct toTrackedProduct(
    Product product,
    List<PurchaseEntry> entries,
  ) {
    final sorted = List<PurchaseEntry>.from(entries)
      ..sort((a, b) => a.purchaseDate.compareTo(b.purchaseDate));
    final history = sorted
        .map((e) =>
            PriceEntry(date: e.purchaseDate, price: _normalizedUnitPrice(e)))
        .where((e) => e.price > 0)
        .toList();
    return TrackedProduct(
      name: product.name,
      isActive: true,
      priceHistory: history,
    );
  }
}
