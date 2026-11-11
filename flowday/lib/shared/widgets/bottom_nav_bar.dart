import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

/// Barre de navigation inférieure avec bouton flottant (+) central.
///
/// Quatre destinations (README §3) : Accueil, Calendrier, Paramètres,
/// Profil. Le bouton (+) dépasse de la barre comme sur la maquette.
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

  static const List<_NavItem> _items = [
    _NavItem(Icons.home_outlined, Icons.home, 'Accueil'),
    _NavItem(Icons.calendar_today_outlined, Icons.calendar_today, 'Calendrier'),
    _NavItem(Icons.settings_outlined, Icons.settings, 'Paramètres'),
    _NavItem(Icons.person_outline, Icons.person, 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.navBar,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: Row(
                children: [
                  for (var i = 0; i < _items.length; i++)
                    Expanded(
                      child: InkResponse(
                        onTap: () => onSelected(i),
                        radius: 28,
                        child: SizedBox(
                          height: 44,
                          child: Icon(
                            i == selectedIndex
                                ? _items[i].selectedIcon
                                : _items[i].icon,
                            size: 25,
                            color: i == selectedIndex
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        // Bouton flottant (+) centré, au-dessus de la barre.
        Positioned(
          top: -26,
          left: 0,
          right: 0,
          child: Center(
            child: GestureDetector(
              onTap: onAdd,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.4),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.add, size: 30, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NavItem {
  const _NavItem(this.icon, this.selectedIcon, this.label);

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}
