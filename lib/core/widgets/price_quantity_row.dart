import 'package:flutter/material.dart';
import 'package:inflabasket/core/models/unit.dart';
import 'package:inflabasket/core/widgets/luxury_dropdown_field.dart';
import 'package:inflabasket/core/widgets/luxury_text_field.dart';

class PriceQuantityRow extends StatelessWidget {
  final TextEditingController priceController;
  final TextEditingController quantityController;
  final UnitType selectedUnit;
  final List<UnitType> units;
  final String currency;
  final String? Function(String?)? priceValidator;
  final String? Function(String?)? quantityValidator;
  final void Function(UnitType)? onUnitChanged;
  final String priceLabel;
  final String quantityLabel;
  final String unitLabel;

  const PriceQuantityRow({
    super.key,
    required this.priceController,
    required this.quantityController,
    required this.selectedUnit,
    required this.units,
    required this.currency,
    required this.priceLabel,
    required this.quantityLabel,
    required this.unitLabel,
    this.priceValidator,
    this.quantityValidator,
    this.onUnitChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LuxuryTextField(
          controller: priceController,
          labelText: priceLabel,
          prefixText: '$currency ',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: priceValidator,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: LuxuryTextField(
                controller: quantityController,
                labelText: quantityLabel,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: quantityValidator,
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 130,
              child: LuxuryDropdownField<UnitType>(
                value: units.contains(selectedUnit)
                    ? selectedUnit
                    : UnitType.count,
                items: units
                    .map((u) => DropdownMenuItem(
                          value: u,
                          child: Text(u.label),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) onUnitChanged?.call(val);
                },
                labelText: unitLabel,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
