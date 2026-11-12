import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../shared/widgets/wave_painter.dart';

// ======================================================================
// PALETTE DU DESIGN D'AUTHENTIFICATION
// ======================================================================

abstract class AuthColors {
  /// Fond des écrans d'authentification.
  static const bg = Color(0xFFF8F9FD);

  /// Encre : texte principal et bouton primaire.
  static const ink = Color(0xFF17181C);

  /// Libellés de champs.
  static const label = Color(0xFF75777E);

  /// Textes d'indicatif des champs.
  static const hint = Color(0xFFB0B2B8);

  /// Bordures des cartes.
  static const border = Color(0xFFE5E7EB);

  /// Texte secondaire (séparateur, liens discrets).
  static const muted = Color(0xFF909298);
}

// ======================================================================
// EN-TÊTE ANTHRACITE ORGANIQUE (continuité avec le dashboard)
// ======================================================================

/// En-tête sombre **identique à celui du dashboard** : carte anthracite
/// (`AppColors.dark`) à coins inférieurs arrondis, lignes d'ondes
/// fluides (`WavePainter`) et typographie géométrique blanche affirmée
/// (marque, accroche, titre, bénéfice).
class FlowdayHeader extends StatelessWidget {
  const FlowdayHeader({
    super.key,
    required this.subtitleBadge,
    required this.title,
    required this.description,
  });

  final String subtitleBadge;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(22, topPadding + 35, 22, 30),
      decoration: const BoxDecoration(
        color: AppColors.dark,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Stack(
        children: [
          // Lignes d'ondes fluides (mêmes vagues que le dashboard).
          const Positioned.fill(child: CustomPaint(painter: WavePainter())),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Marque de l'application.
              const Text(
                'Flowday',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 14),

              // Accroche contextuelle (position du « Hey … » du dashboard).
              Text(
                subtitleBadge,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 14),

              // Titre de l'écran (même échelle que le dashboard).
              Text(
                title,
                style: const TextStyle(
                  fontSize: 25,
                  height: 1.2,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 8),

              // Bénéfice utilisateur.
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    fontWeight: FontWeight.w400,
                    color: Colors.white70,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ======================================================================
// CHAMP DE SAISIE À LIBELLÉ FLOTTANT (carte en relief)
// ======================================================================

/// Champ moderne : carte blanche en relief, libellé flottant, indicatif,
/// icône préfixe et (optionnel) suffixe (œil du mot de passe). Supporte
/// la validation du formulaire.
class FloatingInputField extends StatelessWidget {
  const FloatingInputField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.hintText,
    required this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction,
    this.validator,
    this.enabled = true,
    this.autofillHints,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final IconData prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final bool enabled;
  final Iterable<String>? autofillHints;
  final void Function(String)? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AuthColors.border, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        validator: validator,
        enabled: enabled,
        autofillHints: autofillHints,
        onFieldSubmitted: onFieldSubmitted,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AuthColors.ink,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          labelText: labelText,
          labelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AuthColors.label,
          ),
          floatingLabelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AuthColors.ink,
          ),
          hintText: hintText,
          hintStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AuthColors.hint,
          ),
          prefixIcon: Icon(prefixIcon, color: AuthColors.ink, size: 20),
          suffixIcon: suffixIcon,
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
          errorStyle: const TextStyle(
            fontSize: 12.5,
            color: Color(0xFFD93025),
          ),
          errorMaxLines: 2,
        ),
      ),
    );
  }
}

// ======================================================================
// BOUTON PRIMAIRE NOIR (texte + flèche)
// ======================================================================

class PrimaryFlowButton extends StatelessWidget {
  const PrimaryFlowButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.busy = false,
  });

  final String text;
  final VoidCallback onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: busy ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AuthColors.ink,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AuthColors.ink.withValues(alpha: 0.55),
        elevation: 4,
        shadowColor: const Color(0x3317181C),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      child: busy
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, size: 18),
              ],
            ),
    );
  }
}

// ======================================================================
// SÉPARATEUR « OU … AVEC »
// ======================================================================

class DividerWithLabel extends StatelessWidget {
  const DividerWithLabel({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Divider(color: AuthColors.border, thickness: 1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: AuthColors.muted,
            ),
          ),
        ),
        const Expanded(
          child: Divider(color: AuthColors.border, thickness: 1),
        ),
      ],
    );
  }
}

// ======================================================================
// BOUTONS SOCIAUX (Google / Apple) SURÉLEVÉS
// ======================================================================

class SocialAuthButton extends StatelessWidget {
  const SocialAuthButton({
    super.key,
    required this.label,
    required this.isGoogle,
    this.onTap,
  });

  final String label;
  final bool isGoogle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AuthColors.border, width: 1.2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            isGoogle
                ? const _GoogleGIcon()
                : const Icon(
                    Icons.apple,
                    color: AuthColors.ink,
                    size: 24,
                  ),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AuthColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Logo Google vectoriel (arcs quadricolores).
class _GoogleGIcon extends StatelessWidget {
  const _GoogleGIcon();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final redPaint = Paint()..color = const Color(0xFFEA4335);
    final bluePaint = Paint()..color = const Color(0xFF4285F4);
    final greenPaint = Paint()..color = const Color(0xFF34A853);
    final yellowPaint = Paint()..color = const Color(0xFFFBBC05);

    final center = Offset(w / 2, h / 2);
    final radius = w / 2;

    // Arcs colorés.
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -0.4,
      1.8,
      true,
      bluePaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      1.4,
      1.4,
      true,
      greenPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      2.8,
      1.2,
      true,
      yellowPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      4.0,
      1.8,
      true,
      redPaint,
    );

    // Découpe intérieure + barre centrale.
    canvas.drawCircle(center, radius * 0.58, Paint()..color = Colors.white);
    final barRect = Rect.fromLTWH(w * 0.45, h * 0.40, w * 0.55, h * 0.22);
    canvas.drawRRect(RRect.fromRectXY(barRect, 2, 2), bluePaint);
  }

  @override
  bool shouldRepaint(covariant _GoogleLogoPainter oldDelegate) => false;
}

// ======================================================================
// MESSAGE D'ERREUR
// ======================================================================

class AuthErrorBox extends StatelessWidget {
  const AuthErrorBox({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFD93025).withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFD93025).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline,
            size: 18,
            color: Color(0xFFD93025),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AuthColors.ink,
                fontSize: 13.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
