/// Supported unit types for purchase entries.
///
/// Units are stored as their [name] string in the database (nullable).
/// A null value or [UnitType.count] means "piece / item" — no physical unit.
enum UnitType {
  // ── No physical unit ─────────────────────────────────────────────
  count,

  // ── Mass — metric ────────────────────────────────────────────────
  gram,
  kilogram,

  // ── Mass — imperial ──────────────────────────────────────────────
  ounce,
  pound,

  // ── Volume — metric ──────────────────────────────────────────────
  milliliter,
  liter,

  // ── Volume — imperial ────────────────────────────────────────────
  fluidOunce,
}

extension UnitTypeExtension on UnitType {
  /// Short display label, e.g. 'kg', 'ml', '×'.
  String get label {
    switch (this) {
      case UnitType.count:
        return '×';
      case UnitType.gram:
        return 'g';
      case UnitType.kilogram:
        return 'kg';
      case UnitType.ounce:
        return 'oz';
      case UnitType.pound:
        return 'lb';
      case UnitType.milliliter:
        return 'ml';
      case UnitType.liter:
        return 'l';
      case UnitType.fluidOunce:
        return 'fl oz';
    }
  }

  /// Human-readable full name for dropdowns.
  String get displayName {
    switch (this) {
      case UnitType.count:
        return 'Count (×)';
      case UnitType.gram:
        return 'Gram (g)';
      case UnitType.kilogram:
        return 'Kilogram (kg)';
      case UnitType.ounce:
        return 'Ounce (oz)';
      case UnitType.pound:
        return 'Pound (lb)';
      case UnitType.milliliter:
        return 'Milliliter (ml)';
      case UnitType.liter:
        return 'Liter (l)';
      case UnitType.fluidOunce:
        return 'Fluid Ounce (fl oz)';
    }
  }

  /// Conversion factor to the canonical base unit for cross-unit comparisons.
  ///
  /// Base units:
  ///   - Mass    → grams  (g)
  ///   - Volume  → milliliters (ml)
  ///   - Count   → 1 (no conversion)
  double get toBaseMultiplier {
    switch (this) {
      case UnitType.count:
        return 1.0;
      case UnitType.gram:
        return 1.0; // base
      case UnitType.kilogram:
        return 1000.0;
      case UnitType.ounce:
        return 28.3495;
      case UnitType.pound:
        return 453.592;
      case UnitType.milliliter:
        return 1.0; // base
      case UnitType.liter:
        return 1000.0;
      case UnitType.fluidOunce:
        return 29.5735;
    }
  }

  /// The display label for the normalised base unit (used in per-unit prices).
  ///
  /// e.g. g → 'g', kg → 'g', oz → 'g', lb → 'g',
  ///      ml → 'ml', l → 'ml', fl oz → 'ml', count → '×'
  String get baseUnitLabel {
    switch (this) {
      case UnitType.count:
        return '×';
      case UnitType.gram:
      case UnitType.kilogram:
      case UnitType.ounce:
      case UnitType.pound:
        return 'g';
      case UnitType.milliliter:
      case UnitType.liter:
      case UnitType.fluidOunce:
        return 'ml';
    }
  }

  /// Returns true if both units measure the same physical dimension (mass / volume).
  /// count is only compatible with count.
  /// Formats an already-normalised price (CHF/g or CHF/ml or CHF/item) into a
  /// human-readable label, scaling up to kg/l when the value is small.
  ///
  /// Use this when you already hold the result of [normalizedPrice].
  String formattedUnitPriceFromNormalized(
      double pricePerBase, String currencySymbol) {
    if (this == UnitType.count) {
      return '$currencySymbol ${pricePerBase.toStringAsFixed(2)}/×';
    }
    switch (_dimension) {
      case _UnitDimension.mass:
        if (pricePerBase < 0.1) {
          return '$currencySymbol ${(pricePerBase * 1000).toStringAsFixed(2)}/kg';
        }
        return '$currencySymbol ${pricePerBase.toStringAsFixed(4)}/g';
      case _UnitDimension.volume:
        if (pricePerBase < 0.1) {
          return '$currencySymbol ${(pricePerBase * 1000).toStringAsFixed(2)}/l';
        }
        return '$currencySymbol ${pricePerBase.toStringAsFixed(4)}/ml';
      case _UnitDimension.count:
        return '$currencySymbol ${pricePerBase.toStringAsFixed(2)}/×';
    }
  }

  bool compatibleWith(UnitType other) {
    return _dimension == other._dimension;
  }

  _UnitDimension get _dimension {
    switch (this) {
      case UnitType.count:
        return _UnitDimension.count;
      case UnitType.gram:
      case UnitType.kilogram:
      case UnitType.ounce:
      case UnitType.pound:
        return _UnitDimension.mass;
      case UnitType.milliliter:
      case UnitType.liter:
      case UnitType.fluidOunce:
        return _UnitDimension.volume;
    }
  }

  /// Compute the normalised price per base unit.
  ///
  /// E.g. 2.00 CHF for 500 g → [normalizedPrice] = 0.004 CHF/g
  double normalizedPrice(double price, double quantity) {
    final q = quantity * toBaseMultiplier;
    if (q == 0) return 0;
    return price / q;
  }

  /// Returns a user-friendly per-unit price label, adapting the displayed unit
  /// to a more readable scale when appropriate.
  ///
  /// E.g. 0.004 CHF/g is displayed as "4.00 CHF/kg"
  String formattedUnitPrice(
      double price, double quantity, String currencySymbol) {
    if (this == UnitType.count) {
      // For count, just show price per item
      final perItem = quantity > 0 ? price / quantity : 0.0;
      return '$currencySymbol ${perItem.toStringAsFixed(2)}/×';
    }

    final perBase = normalizedPrice(price, quantity);

    // Scale up to a human-friendly unit
    switch (_dimension) {
      case _UnitDimension.mass:
        // perBase is in CHF/g — show per kg if < 0.1 CHF/g for readability
        if (perBase < 0.1) {
          return '$currencySymbol ${(perBase * 1000).toStringAsFixed(2)}/kg';
        }
        return '$currencySymbol ${perBase.toStringAsFixed(4)}/g';
      case _UnitDimension.volume:
        // perBase is in CHF/ml — show per liter if < 0.1 CHF/ml
        if (perBase < 0.1) {
          return '$currencySymbol ${(perBase * 1000).toStringAsFixed(2)}/l';
        }
        return '$currencySymbol ${perBase.toStringAsFixed(4)}/ml';
      case _UnitDimension.count:
        final perItem = quantity > 0 ? price / quantity : 0.0;
        return '$currencySymbol ${perItem.toStringAsFixed(2)}/×';
    }
  }
}

enum _UnitDimension { count, mass, volume }

/// Units shown when the app is in metric mode.
const List<UnitType> metricUnits = [
  UnitType.count,
  UnitType.gram,
  UnitType.kilogram,
  UnitType.milliliter,
  UnitType.liter,
];

/// Units shown when the app is in imperial mode.
const List<UnitType> imperialUnits = [
  UnitType.count,
  UnitType.ounce,
  UnitType.pound,
  UnitType.fluidOunce,
];

/// Returns the available units based on the metric/imperial preference.
List<UnitType> availableUnits(bool isMetric) =>
    isMetric ? metricUnits : imperialUnits;

/// Parses a stored unit string back to [UnitType].
/// Returns [UnitType.count] for null or unrecognised strings.
UnitType unitTypeFromString(String? value) {
  if (value == null) return UnitType.count;
  return UnitType.values.firstWhere(
    (u) => u.name == value,
    orElse: () => UnitType.count,
  );
}
