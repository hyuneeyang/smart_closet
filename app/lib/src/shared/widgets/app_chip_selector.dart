import 'package:flutter/material.dart';

class AppChipSelector<T> extends StatelessWidget {
  const AppChipSelector({
    super.key,
    required this.values,
    required this.selected,
    required this.labelBuilder,
    required this.onSelected,
  });

  final List<T> values;
  final T selected;
  final String Function(T value) labelBuilder;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: values.map((value) {
        final isSelected = value == selected;
        return ChoiceChip(
          selected: isSelected,
          label: Text(labelBuilder(value)),
          onSelected: (_) => onSelected(value),
        );
      }).toList(),
    );
  }
}
