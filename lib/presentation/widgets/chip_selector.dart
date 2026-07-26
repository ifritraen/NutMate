import 'package:flutter/material.dart';

class ChipSelector extends StatefulWidget {
  final String title;
  final List<String> options;
  final String selectedSingle;
  final List<String> selectedMulti;
  final bool isMultiSelect;
  final ValueChanged<String>? onSingleSelected;
  final ValueChanged<List<String>>? onMultiSelected;

  const ChipSelector({
    super.key,
    required this.title,
    required this.options,
    this.selectedSingle = '',
    this.selectedMulti = const [],
    this.isMultiSelect = false,
    this.onSingleSelected,
    this.onMultiSelected,
  });

  @override
  State<ChipSelector> createState() => _ChipSelectorState();
}

class _ChipSelectorState extends State<ChipSelector> {
  bool _showOtherField = false;
  final TextEditingController _otherController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (!widget.isMultiSelect && widget.selectedSingle.isNotEmpty && !widget.options.contains(widget.selectedSingle)) {
      _showOtherField = true;
      _otherController.text = widget.selectedSingle;
    }
  }

  @override
  void dispose() {
    _otherController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...widget.options.map((opt) {
              final isSelected = widget.isMultiSelect
                  ? widget.selectedMulti.contains(opt)
                  : (!_showOtherField && widget.selectedSingle == opt);

              return ChoiceChip(
                label: Text(opt),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _showOtherField = false;
                  });

                  if (widget.isMultiSelect) {
                    final updated = List<String>.from(widget.selectedMulti);
                    if (selected) {
                      updated.add(opt);
                    } else {
                      updated.remove(opt);
                    }
                    widget.onMultiSelected?.call(updated);
                  } else {
                    widget.onSingleSelected?.call(selected ? opt : '');
                  }
                },
              );
            }),
            ChoiceChip(
              label: const Text('Other'),
              selected: _showOtherField,
              onSelected: (selected) {
                setState(() {
                  _showOtherField = selected;
                  if (!selected) {
                    _otherController.clear();
                    if (!widget.isMultiSelect) widget.onSingleSelected?.call('');
                  }
                });
              },
            ),
          ],
        ),
        if (_showOtherField) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _otherController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Specify custom response...',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.colorScheme.primary),
              ),
            ),
            onChanged: (val) {
              if (widget.isMultiSelect) {
                final updated = List<String>.from(widget.selectedMulti.where((e) => widget.options.contains(e)));
                if (val.trim().isNotEmpty) updated.add(val.trim());
                widget.onMultiSelected?.call(updated);
              } else {
                widget.onSingleSelected?.call(val.trim());
              }
            },
          ),
        ],
      ],
    );
  }
}
