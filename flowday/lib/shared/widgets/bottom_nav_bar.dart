import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

/// Barre de navigation inférieure du design de référence :
/// 4 destinations + bouton (+) central en cercle sombre cerclé de clair.
///
/// Destinations : Accueil, Calendrier, [+] Ajouter, Paramètres, Profil.
/// L'onglet actif est en sombre avec une pastille dessous.
class BottomNavBar extends StatelessWidget {
  const BottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    required this.onAdd,
  });

  /// Index de l'onglet actif (0 à 3, le bouton + n'est pas un onglet).
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
    return Container(
      height: 82,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.navBg,
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
            // Position 2 : bouton d'ajout central.
            if (position == 2) {
              return GestureDetector(
                onTap: onAdd,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 65,
                  height: 65,
                  decoration: BoxDecoration(
                    color: AppColors.dark,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.navBorder,
                      width: 5,
                    ),
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              );
            }

            // Les autres positions : 0, 1, 3, 4 -> onglets 0..3.
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
                          ? AppColors.dark
                          : AppColors.navIconInactive,
                    ),
                    const SizedBox(height: 8),
                    if (selected)
                      const CircleAvatar(
                        radius: 3,
                        backgroundColor: AppColors.dark,
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
