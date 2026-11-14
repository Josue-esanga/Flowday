import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/l10n/app_localizations.dart';

/// Interrupteur néomorphique clair / sombre de Flowday.
///
/// En mode clair : piste gris très clair, ombre blanche et soleil à droite.
/// En mode sombre : piste anthracite creusée, lune à gauche et bouton relief.
class ThemeModeSwitch extends StatelessWidget {
  const ThemeModeSwitch({
    super.key,
    required this.isDark,
    required this.onChanged,
    this.width = 116,
    this.height = 50,
  });

  final bool isDark;
  final ValueChanged<bool> onChanged;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scale = height / 60;
    final padding = height * 0.1;
    final knobSize = height - padding * 2;
    final iconSize = height * 0.4;

    final background = isDark
        ? const Color(0xFF1E2024)
        : const Color(0xFFF0F2F5);
    final knobColor = isDark ? const Color(0xFF2C3038) : Colors.white;
    final iconColor = Colors.grey[400] ?? const Color(0xFFBDBDBD);

    return Semantics(
      button: true,
      toggled: isDark,
      label: AppLocalizations.of(context).t('Thème sombre'),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onChanged(!isDark);
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          width: width,
          height: height,
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(height / 2),
            boxShadow: isDark
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      offset: Offset(4 * scale, 4 * scale),
                      blurRadius: 10 * scale,
                      spreadRadius: scale,
                    ),
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.04),
                      offset: Offset(-4 * scale, -4 * scale),
                      blurRadius: 10 * scale,
                      spreadRadius: scale,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.white,
                      offset: Offset(-4 * scale, -4 * scale),
                      blurRadius: 10 * scale,
                      spreadRadius: scale,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      offset: Offset(4 * scale, 4 * scale),
                      blurRadius: 10 * scale,
                      spreadRadius: scale,
                    ),
                  ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Icônes fixes : lune à gauche, soleil à droite.
              Padding(
                padding: EdgeInsets.symmetric(horizontal: height * 0.27),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 220),
                      opacity: isDark ? 1 : 0,
                      child: Icon(
                        Icons.nightlight_round,
                        color: iconColor,
                        size: iconSize,
                      ),
                    ),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 220),
                      opacity: isDark ? 0 : 1,
                      child: Icon(
                        Icons.wb_sunny_outlined,
                        color: iconColor,
                        size: iconSize,
                      ),
                    ),
                  ],
                ),
              ),
              // Bouton rond coulissant.
              AnimatedAlign(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                alignment: isDark
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  width: knobSize,
                  height: knobSize,
                  decoration: BoxDecoration(
                    color: knobColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.4 : 0.1,
                        ),
                        blurRadius: 6 * scale,
                        offset: Offset(0, 3 * scale),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
