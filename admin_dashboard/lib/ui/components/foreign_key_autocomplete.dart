import 'package:flutter/material.dart';

class ForeignKeyAutocomplete<T extends Object> extends StatelessWidget {
  final List<T> items;
  final String Function(T) displayStringForOption;
  final String Function(T) idForOption;
  final TextEditingController controller;
  final String labelText;

  const ForeignKeyAutocomplete({
    super.key,
    required this.items,
    required this.displayStringForOption,
    required this.idForOption,
    required this.controller,
    required this.labelText,
  });

  @override
  Widget build(BuildContext context) {
    return Autocomplete<T>(
      displayStringForOption: displayStringForOption,
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text == '') {
          return items.take(50);
        }
        return items.where((T option) {
          return displayStringForOption(option)
                  .toLowerCase()
                  .contains(textEditingValue.text.toLowerCase()) ||
                 idForOption(option)
                  .toLowerCase()
                  .contains(textEditingValue.text.toLowerCase());
        }).take(50);
      },
      onSelected: (T selection) {
        controller.text = idForOption(selection);
      },
      fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: textEditingController,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: labelText,
            border: const OutlineInputBorder(),
          ),
          onChanged: (value) {
            controller.text = value;
          },
          validator: (v) {
            if (v == null || v.isEmpty) return 'Required';
            final exists = items.any((item) => idForOption(item) == v);
            if (!exists) return 'Invalid $labelText';
            return null;
          },
        );
      },
    );
  }
}
