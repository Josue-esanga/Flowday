import 'package:flutter/material.dart';

/// Logo Flowday — marque officielle de l'application (carré sombre
/// arrondi `#1E1E22`, vagues subtiles, halo radial et symbole « F »
/// sculptural avec coche et badge calendrier), dessiné en pur
/// `CustomPaint` d'après la maquette fournie.
///
/// Utilisé au démarrage de l'app (`_Splash`) et comme source de
/// génération de toutes les icônes natives (masters 1024 px).
class FlowdayLogo extends StatelessWidget {
  const FlowdayLogo({
    super.key,
    this.size = 200,
    this.framed = true,
    this.symbolScale = 0.72,
    this.shadow = true,
  });

  /// Côté du carré.
  final double size;

  /// `true` : carré arrondi avec ombre (rendu applicatif) ;
  /// `false` : plein cadre sans arrondi ni ombre (génération d'icônes).
  final bool framed;

  /// Taille du symbole par rapport au carré — 0.72 (maquette) ou
  /// 0.56 (zone sûre des icônes « maskables »).
  final double symbolScale;

  /// Ombre portée (seulement si [framed]).
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final content = Stack(
      alignment: Alignment.center,
      children: [
        // Arrière-plan à vagues texturées.
        Positioned.fill(
          child: CustomPaint(painter: BackgroundWavesPainter()),
        ),
        // Dégradé radial d'ambiance.
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.2),
                radius: 0.9,
                colors: [
                  Colors.white.withValues(alpha: 0.06),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Éléments du logo (« F » stylisé, coche & calendrier).
        SizedBox(
          width: size * symbolScale,
          height: size * symbolScale,
          child: const CustomPaint(painter: StylizedFLogoPainter()),
        ),
      ],
    );

    if (!framed) {
      // Plein cadre : fond uniforme, coins carrés (le masque est appliqué
      // par la plateforme cible).
      return SizedBox(
        width: size,
        height: size,
        child: ColoredBox(color: const Color(0xFF1E1E22), child: content),
      );
    }

    final radius = BorderRadius.circular(size * 0.225);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E22),
        borderRadius: radius,
        boxShadow: [
          if (shadow)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.55),
              blurRadius: size * 0.12,
              offset: Offset(0, size * 0.05),
            ),
        ],
      ),
      child: ClipRRect(borderRadius: radius, child: content),
    );
  }
}

/// Dessine les lignes d'ondes texturées fluides en arrière-plan sombre.
class BackgroundWavesPainter extends CustomPainter {
  const BackgroundWavesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final wavePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      // Trait « 1 px » à l'échelle de référence (280 px) : le tracé reste
      // vectoriel quelle que soit la taille de rendu.
      ..strokeWidth = size.width / 280;

    for (int i = 0; i < 24; i++) {
      final path = Path();
      final double yOffset = size.height * 0.15 + (i * size.height * 0.035);
      path.moveTo(0, yOffset);
      path.cubicTo(
        size.width * 0.3,
        yOffset - size.height * 0.15,
        size.width * 0.7,
        yOffset + size.height * 0.15,
        size.width,
        yOffset,
      );
      canvas.drawPath(path, wavePaint);
    }
  }

  @override
  bool shouldRepaint(covariant BackgroundWavesPainter oldDelegate) => false;
}

/// Peintre vectoriel du symbole central (« F » sculptural, coche et
/// badge calendrier).
class StylizedFLogoPainter extends CustomPainter {
  const StylizedFLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Ombre portée sous le logo principal (échelle de référence : le
    // painter est exécuté dans une boîte de 0.72 × 280 ≈ 201 px).
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.4)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.06);

    // --- 1. Forme du 'F' stylisé ruban blanc/argenté ---
    final fPath = Path();
    fPath.moveTo(w * 0.26, h * 0.82);
    // Tige gauche montante
    fPath.cubicTo(w * 0.14, h * 0.65, w * 0.15, h * 0.28, w * 0.38, h * 0.16);
    // Barre supérieure droite
    fPath.cubicTo(w * 0.52, h * 0.10, w * 0.85, h * 0.14, w * 0.88, h * 0.18);
    fPath.cubicTo(w * 0.89, h * 0.28, w * 0.58, h * 0.28, w * 0.48, h * 0.28);
    // Intérieur vers le badge
    fPath.cubicTo(w * 0.40, h * 0.28, w * 0.36, h * 0.38, w * 0.36, h * 0.52);
    // Barre médiane
    fPath.lineTo(w * 0.76, h * 0.52);
    fPath.cubicTo(w * 0.82, h * 0.52, w * 0.82, h * 0.64, w * 0.76, h * 0.64);
    fPath.lineTo(w * 0.44, h * 0.64);
    fPath.cubicTo(w * 0.44, h * 0.74, w * 0.36, h * 0.82, w * 0.26, h * 0.82);
    fPath.close();

    // Ombre sous le F
    canvas.drawPath(fPath.shift(Offset(0, h * 0.02)), shadowPaint);

    // Rendu du F avec dégradé subtil métallique
    final fGradient = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFFFFFFF),
        Color(0xFFF0F0F5),
        Color(0xFFD8D9E0),
      ],
      stops: [0.0, 0.45, 1.0],
    ).createShader(Rect.fromLTWH(0, 0, w, h));

    final fPaint = Paint()
      ..shader = fGradient
      ..style = PaintingStyle.fill;
    canvas.drawPath(fPath, fPaint);

    // --- 2. Zone sombre intérieure de la bulle / coche ---
    final darkPocketRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.34, h * 0.28, w * 0.42, h * 0.30),
      Radius.circular(w * 0.08),
    );
    final darkPocketPaint = Paint()..color = const Color(0xFF1D1D21);
    canvas.drawRRect(darkPocketRect, darkPocketPaint);

    // Coche (Checkmark) blanche
    final checkPath = Path();
    checkPath.moveTo(w * 0.44, h * 0.44);
    checkPath.lineTo(w * 0.52, h * 0.52);
    checkPath.lineTo(w * 0.66, h * 0.38);

    final checkPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = w * 0.06;
    canvas.drawPath(checkPath, checkPaint);

    // --- 3. Badge Calendrier au premier plan ---
    final calRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.24, h * 0.52, w * 0.34, h * 0.34),
      Radius.circular(w * 0.075),
    );

    // Ombre du calendrier
    canvas.drawRRect(calRect.shift(Offset(0, h * 0.015)), shadowPaint);

    // Corps du calendrier
    final calBgPaint = Paint()..color = const Color(0xFF23242A);
    canvas.drawRRect(calRect, calBgPaint);

    // Tête / bandeau supérieur du calendrier
    final calHeader = RRect.fromRectAndCorners(
      Rect.fromLTWH(w * 0.24, h * 0.52, w * 0.34, h * 0.09),
      topLeft: Radius.circular(w * 0.075),
      topRight: Radius.circular(w * 0.075),
    );
    final calHeaderPaint = Paint()..color = const Color(0xFF32343E);
    canvas.drawRRect(calHeader, calHeaderPaint);

    // Attaches métalliques supérieures du calendrier
    final ringPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.31, h * 0.495, w * 0.035, h * 0.05),
        Radius.circular(w * 0.015),
      ),
      ringPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.47, h * 0.495, w * 0.035, h * 0.05),
        Radius.circular(w * 0.015),
      ),
      ringPaint,
    );

    // Grille de pastilles / jours du calendrier (2 rangées de 3)
    final dotPaint = Paint()..color = const Color(0xFF8E92A4);
    final dotW = w * 0.045;
    final dotH = h * 0.032;
    final dotRadius = Radius.circular(w * 0.01);

    for (int row = 0; row < 2; row++) {
      for (int col = 0; col < 3; col++) {
        final dx = w * 0.285 + (col * w * 0.09);
        final dy = h * 0.66 + (row * h * 0.07);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(dx, dy, dotW, dotH),
            dotRadius,
          ),
          dotPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant StylizedFLogoPainter oldDelegate) => false;
}
