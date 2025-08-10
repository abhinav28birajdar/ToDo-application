import 'package:flutter/material.dart';

class FilterChipWidget extends StatelessWidget {
  final String label;
  final VoidCallback? onDeleted;
  final Color? backgroundColor;
  final Color? labelColor;

  const FilterChipWidget({
    super.key,
    required this.label,
    this.onDeleted,
    this.backgroundColor,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        label,
        style: TextStyle(
          color: labelColor ?? Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: backgroundColor ?? Colors.blue,
      deleteIcon: onDeleted != null
          ? Icon(
              Icons.close,
              size: 16,
              color: labelColor ?? Colors.white,
            )
          : null,
      onDeleted: onDeleted,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide.none,
      ),
    );
  }
}
