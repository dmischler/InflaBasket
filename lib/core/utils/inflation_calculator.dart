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
    this.productsAtBaseline = 0,
    this.jumpDrivers = const [],
  });

  final DateTime date;
  final double inflationPct;
  final int contributingProducts;
  final int productsAtBaseline;
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

  static PriceEntry? _lastEntryOnOrBefore(
      List<PriceEntry> sorted, DateTime target) {
    return sorted.lastWhereOrNull((e) => !e.date.isAfter(target));
  }

  static List<DateTime> _monthlyChartDates(DateTime start, DateTime end) {
    if (start.isAfter(end)) return const [];

    final dates = <DateTime>[start];
    var cursor = DateTime(start.year, start.month, 1);
    final endMonth = DateTime(end.year, end.month, 1);

    while (!cursor.isAfter(endMonth)) {
      if (cursor.isAfter(start) && !cursor.isAfter(end)) {
        dates.add(cursor);
      }
      cursor = DateTime(cursor.year, cursor.month + 1, 1);
    }

    if (!dates.last.isAtSameMomentAs(end)) {
      dates.add(end);
    }

    return dates;
  }

  static double? productPercentChange(
    TrackedProduct p,
    DateTime start,
    DateTime end,
  ) {
    if (!p.isActive || p.priceHistory.isEmpty || start.isAfter(end)) {
      return null;
    }
    final history = List<PriceEntry>.from(p.priceHistory)
      ..sort((a, b) => a.date.compareTo(b.date));

    final startEntry = _lastEntryOnOrBefore(history, start);
    if (startEntry == null) {
      return null;
    }

    final endEntry = _lastEntryOnOrBefore(history, end);
    if (endEntry == null) return null;

    final startPrice = startEntry.price;
    final endPrice = endEntry.price;
    if (!startPrice.isFinite ||
        startPrice <= 0 ||
        !endPrice.isFinite ||
        endPrice <= 0) {
      return null;
    }

    if (startEntry == endEntry) return null;

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
    DateTime rangeStart,
    DateTime endDate,
    List<TrackedProduct> products,
  ) {
    if (rangeStart.isAfter(endDate)) return const [];
    final dates = _monthlyChartDates(rangeStart, endDate);
    if (dates.isEmpty) return const [];

    final productData = <({
      String name,
      List<PriceEntry> history,
      PriceEntry? baselineEntry,
      bool hasBaselineBeforeRange,
    })>[];

    for (final product in products.where((p) => p.isActive)) {
      final history = product.priceHistory
          .where((e) => e.price.isFinite && e.price > 0)
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));
      if (history.isEmpty) continue;

      final baselineBefore = _lastEntryOnOrBefore(history, rangeStart);
      final hasBeforeRange = baselineBefore != null;

      if (hasBeforeRange) {
        productData.add((
          name: product.name,
          history: history,
          baselineEntry: baselineBefore,
          hasBaselineBeforeRange: true,
        ));
      }
    }

    if (productData.isEmpty) return const [];

    final rawPoints = <({
      DateTime date,
      double avgInflation,
      double coverage,
      int contributing,
      List<String> jumpDrivers,
    })>[];

    for (final d in dates) {
      final changes = <double>[];
      final jumpDrivers = <String>[];

      for (final product in productData) {
        final current = _lastEntryOnOrBefore(product.history, d);
        if (current == null) continue;

        if (identical(current, product.baselineEntry)) continue;

        final change = ((current.price - product.baselineEntry!.price) /
                product.baselineEntry!.price) *
            100;
        changes.add(change);

        final changedToday = product.history.any((e) =>
            e.date.year == d.year &&
            e.date.month == d.month &&
            e.date.day == d.day);
        if (changedToday) jumpDrivers.add(product.name);
      }

      if (changes.isEmpty) continue;

      rawPoints.add((
        date: d,
        avgInflation: changes.average,
        coverage: changes.length / productData.length,
        contributing: changes.length,
        jumpDrivers: jumpDrivers,
      ));
    }

    if (rawPoints.isEmpty) return const [];

    if (rawPoints.isEmpty || rawPoints.first.date != rangeStart) {
      rawPoints.insert(
        0,
        (
          date: rangeStart,
          avgInflation: 0.0,
          coverage: 0.0,
          contributing: 0,
          jumpDrivers: <String>[],
        ),
      );
    }

    final baselineInflation = rawPoints.first.avgInflation;

    return rawPoints.map((p) {
      final shifted = p.avgInflation - baselineInflation;
      return ChartPoint(
        date: p.date,
        inflationPct: shifted.abs() < 1e-9 ? 0.0 : shifted,
        contributingProducts: p.contributing,
        productsAtBaseline: productData.length - p.contributing,
        jumpDrivers: p.jumpDrivers,
      );
    }).toList();
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
