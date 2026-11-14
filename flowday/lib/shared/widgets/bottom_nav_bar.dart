import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

/// Barre de navigation Flowday : 4 destinations + bouton d'ajout central.
class BottomNavBar extends StatelessWidget {
  const BottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    required this.onAdd,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback onAdd;

  static const List<IconData> _icons = [
    Icons.home_filled,
    Icons.calendar_month,
    Icons.settings,
    Icons.person,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 82,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? theme.cardColor
            : AppColors.navBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(_icons.length + 1, (position) {
            if (position == 2) {
              final isDark = theme.brightness == Brightness.dark;
              return GestureDetector(
                onTap: onAdd,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 65,
                  height: 65,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white : AppColors.dark,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF5A5E68)
                          : AppColors.navBorder,
                      width: 5,
                    ),
                  ),
                  child: Icon(
                    Icons.add,
                    color: isDark ? AppColors.dark : Colors.white,
                    size: 32,
                  ),
                ),
              );
            }

            final tabIndex = position < 2 ? position : position - 1;
            final selected = selectedIndex == tabIndex;
            return InkResponse(
              onTap: () => onSelected(tabIndex),
              radius: 26,
              child: SizedBox(
                height: 56,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _icons[tabIndex],
                      size: 23,
                      color: selected
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 8),
                    if (selected)
                      CircleAvatar(
                        radius: 3,
                        backgroundColor: theme.colorScheme.onSurface,
                      ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
