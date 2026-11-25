import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class SportCategoryList extends StatelessWidget {
  const SportCategoryList({
    super.key,
    required this.selectedSport,
    required this.onSelected,
  });

  final String? selectedSport;
  final ValueChanged<String?> onSelected;

  static const List<String> categories = [
    'Semua',
    'Futsal',
    'Badminton',
    'Basket',
    'Tenis',
    'Mini Soccer',
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == 'Semua'
              ? (selectedSport == null || selectedSport!.isEmpty)
              : selectedSport == category;

          return ChoiceChip(
            label: Text(category),
            selected: isSelected,
            showCheckmark: false,
            selectedColor: AppColors.primary,
            backgroundColor: AppColors.surface,
            side: BorderSide(
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isSelected ? AppColors.background : AppColors.textSecondary,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            onSelected: (_) {
              if (category == 'Semua') {
                onSelected(null);
              } else {
                onSelected(isSelected ? null : category);
              }
            },
          );
        },
      ),
    );
  }
}
