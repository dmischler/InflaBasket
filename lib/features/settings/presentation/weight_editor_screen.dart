import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inflabasket/core/database/database.dart';
import 'package:inflabasket/features/entry_management/application/entry_providers.dart';
import 'package:inflabasket/features/settings/application/settings_provider.dart';

/// Screen that lets the user assign a fixed percentage weight to each category
/// for the inflation basket calculation.
///
/// The sliders are percentage-based (0–100). When the user taps Save, the
/// values are normalised to fractions that sum to 1.0 and persisted via
/// [CategoryWeightsController].
class WeightEditorScreen extends ConsumerStatefulWidget {
  const WeightEditorScreen({super.key});

  @override
  ConsumerState<WeightEditorScreen> createState() => _WeightEditorScreenState();
}

class _WeightEditorScreenState extends ConsumerState<WeightEditorScreen> {
  /// categoryId → percentage (0–100)
  Map<int, double> _percentages = {};
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;

    final categories =
        ref.read(categoriesProvider).valueOrNull ?? <Category>[];
    final savedWeights =
        ref.read(categoryWeightsControllerProvider).valueOrNull ?? {};

    if (categories.isEmpty) return;

    _initialized = true;

    if (savedWeights.isEmpty) {
      // Equal distribution
      final equal = 100.0 / categories.length;
      _percentages = {for (final c in categories) c.id: equal};
    } else {
      // Convert stored fractions → percentages, fill missing categories with 0
      _percentages = {
        for (final c in categories)
          c.id: ((savedWeights[c.id] ?? 0.0) * 100).roundToDouble(),
      };
    }
  }

  double get _totalPercent =>
      _percentages.values.fold(0.0, (a, b) => a + b);

  bool get _isValid => (_totalPercent - 100.0).abs() < 0.5;

  void _resetEqual(List<Category> categories) {
    if (categories.isEmpty) return;
    final equal =
        double.parse((100.0 / categories.length).toStringAsFixed(1));
    setState(() {
      _percentages = {for (final c in categories) c.id: equal};
    });
  }

  Future<void> _save(List<Category> categories) async {
    if (!_isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Weights must sum to 100% (currently ${_totalPercent.toStringAsFixed(1)}%)',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    // Normalise to fractions, re-normalise so they sum exactly to 1.0
    final total = _totalPercent;
    final fractions = {
      for (final e in _percentages.entries) e.key: e.value / total,
    };

    await ref
        .read(categoryWeightsControllerProvider.notifier)
        .saveWeights(fractions);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category weights saved.')),
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _clearWeights() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Weights'),
        content: const Text(
          'Remove all custom weights? The basket will revert to '
          'spend-weighted averaging.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref
          .read(categoryWeightsControllerProvider.notifier)
          .clearWeights();
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Category Weights'),
        actions: [
          TextButton(
            onPressed: () {
              final cats =
                  categoriesAsync.valueOrNull ?? <Category>[];
              _resetEqual(cats);
            },
            child: const Text('Reset Equal'),
          ),
        ],
      ),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (categories) {
          if (categories.isEmpty) {
            return const Center(child: Text('No categories found.'));
          }

          // Ensure _percentages has an entry for every category
          for (final c in categories) {
            _percentages.putIfAbsent(c.id, () => 0.0);
          }

          final total = _totalPercent;
          final isValid = (total - 100.0).abs() < 0.5;

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    final pct = _percentages[cat.id] ?? 0.0;
                    return _WeightSliderTile(
                      categoryName: cat.name,
                      value: pct,
                      onChanged: (v) {
                        setState(() {
                          _percentages[cat.id] = v;
                        });
                      },
                    );
                  },
                ),
              ),
              // Total indicator + action buttons
              Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${total.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isValid
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                    if (!isValid)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Must equal 100%',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _clearWeights,
                            child: const Text('Use Spend-Weighted'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: isValid
                                ? () => _save(categories)
                                : null,
                            child: const Text('Save'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _WeightSliderTile extends StatelessWidget {
  const _WeightSliderTile({
    required this.categoryName,
    required this.value,
    required this.onChanged,
  });

  final String categoryName;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(categoryName,
                  style: const TextStyle(fontWeight: FontWeight.w500)),
              Text('${value.toStringAsFixed(1)}%'),
            ],
          ),
          Slider(
            min: 0,
            max: 100,
            divisions: 100,
            value: value.clamp(0.0, 100.0),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
