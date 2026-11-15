import 'package:flutter/material.dart';

/// Logo Flowday — marque officielle de l'application : carte noire
/// dégradée arrondie, lignes d'ondes décoratives, « F » blanc
/// sculptural avec coche et badge calendrier, dessiné en pur
/// `CustomPaint` d'après la maquette fournie.
///
/// Utilisé au démarrage de l'app (`_Splash`) et comme source de
/// génération de toutes les icônes natives (masters 1024 px).
class FlowdayLogo extends StatelessWidget {
  const FlowdayLogo({
    super.key,
    this.size = 200,
    this.framed = true,
    this.symbolScale = 1.0,
  });

  /// Côté du carré.
  final double size;

  /// `true` : carte arrondie avec ombre portée (rendu applicatif) ;
  /// `false` : plein cadre sans arrondi ni ombre (génération d'icônes,
  /// le masque étant appliqué par la plateforme cible).
  final bool framed;

  /// Échelle du symbole (F + calendrier) par rapport à la maquette —
  /// 1.0 (design d'origine) ou 0.56 (zone sûre des icônes « maskables »).
  final double symbolScale;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: FlowdayLogoPainter(framed: framed, symbolScale: symbolScale),
      ),
    );
  }
}

class FlowdayLogoPainter extends CustomPainter {
  const FlowdayLogoPainter({this.framed = true, this.symbolScale = 1.0});

  /// Voir [FlowdayLogo.framed].
  final bool framed;

  /// Voir [FlowdayLogo.symbolScale].
  final double symbolScale;

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width / 500;

    canvas.save();
    canvas.scale(s);

    // ==========================================
    // 1. FOND NOIR ARRONDI (ou plein cadre pour les icônes)
    // ==========================================
    final background = framed
        ? RRect.fromRectAndRadius(
            const Rect.fromLTWH(5, 5, 490, 490),
            const Radius.circular(100),
          )
        : RRect.fromRectAndRadius(
            const Rect.fromLTWH(0, 0, 500, 500),
            Radius.zero,
          );

    const bounds = Rect.fromLTWH(5, 5, 490, 490);

    if (framed) {
      canvas.drawRRect(
        background.shift(const Offset(0, 10)),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
      );
    }

    canvas.drawRRect(
      background,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF27272E), Color(0xFF191920), Color(0xFF0B0B10)],
        ).createShader(bounds),
    );

    canvas.save();
    canvas.clipRRect(background);

    // Halo lumineux en haut à gauche et lueur violette en bas à droite.
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.85, -0.9),
          radius: 1.1,
          colors: [
            Colors.white.withValues(alpha: 0.07),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(bounds),
    );

    canvas.drawRect(
      bounds,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.9, 0.95),
          radius: 0.95,
          colors: [
            const Color(0xFF7A6BFF).withValues(alpha: 0.12),
            const Color(0xFF7A6BFF).withValues(alpha: 0),
          ],
        ).createShader(bounds),
    );

    // ==========================================
    // 2. VAGUES DECORATIVES
    // ==========================================
    final wavePaint = Paint()
      ..color = const Color(0xFFB7B7C8).withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    for (int i = 0; i < 16; i++) {
      final path = Path();
      final y = 30.0 + i * 17;

      path.moveTo(-10, y + 40);

      path.cubicTo(95, y - 60, 165, y - 48, 240, y + 34);

      path.cubicTo(315, y + 116, 385, y + 80, 510, y + 12);

      canvas.drawPath(path, wavePaint);
    }

    // ==========================================
    // Symbole (F + calendrier) — échelle de zone sûre si demandée
    // ==========================================
    canvas.save();
    if (symbolScale != 1.0) {
      canvas
        ..translate(250, 250)
        ..scale(symbolScale)
        ..translate(-250, -250);
    }

    // ==========================================
    // 3. RUBAN PRINCIPAL DU F
    //    (hampe + bras supérieur + pied balayé)
    // ==========================================
    final fPath = Path()
      ..moveTo(120, 176)
      ..cubicTo(120, 126, 146, 101, 192, 101) // coin supérieur gauche
      ..lineTo(380, 101) // bord supérieur
      ..cubicTo(390, 101, 395, 106, 395, 116) // coin supérieur droit
      ..cubicTo(395, 138, 377, 154, 356, 160) // bout droit qui retombe
      ..lineTo(232, 162) // bord inférieur du bras
      ..cubicTo(211, 162, 195, 169, 195, 184) // courbe intérieure
      ..lineTo(195, 330) // côté droit de la hampe
      ..lineTo(286, 368) // pointe du pied (derrière le calendrier)
      ..cubicTo(268, 388, 236, 397, 200, 401)
      ..cubicTo(168, 405, 140, 412, 124, 414)
      ..cubicTo(121, 413, 120, 402, 120, 392)
      ..close();

    // Ombre portée du ruban
    canvas.drawPath(
      fPath.shift(const Offset(3, 9)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    // Dégradé du ruban
    canvas.drawPath(
      fPath,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFF4F3FC), Color(0xFFDFDDEF)],
        ).createShader(const Rect.fromLTWH(118, 94, 290, 330)),
    );

    // Pli du ruban : ombre douce + face légèrement lavande
    canvas.save();
    canvas.clipPath(fPath);
    canvas.drawPath(
      Path()
        ..moveTo(256, 99)
        ..lineTo(292, 99)
        ..lineTo(256, 172)
        ..lineTo(198, 172)
        ..close(),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.33)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 11),
    );
    canvas.drawPath(
      Path()
        ..moveTo(272, 90)
        ..lineTo(400, 90)
        ..lineTo(400, 172)
        ..lineTo(222, 172)
        ..close(),
      Paint()..color = const Color(0xFFB9BAD8).withValues(alpha: 0.30),
    );
    // Ombre du bras sur la hampe
    canvas.drawPath(
      Path()
        ..moveTo(196, 200)
        ..lineTo(212, 200)
        ..lineTo(158, 360)
        ..lineTo(120, 360)
        ..close(),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.42)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
    );
    canvas.restore();

    // ==========================================
    // 4. COCHE BLANCHE
    // ==========================================
    final check = Path()
      ..moveTo(241, 213)
      ..lineTo(266, 253)
      ..lineTo(313, 188);

    canvas.drawPath(
      check,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7)
        ..strokeWidth = 22
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );

    canvas.drawPath(
      check,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFEDEBFA)],
        ).createShader(const Rect.fromLTWH(232, 186, 90, 70))
        ..strokeWidth = 21
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );

    // ==========================================
    // 5. BRAS MÉDIAN FLOTTANT (ruban / drapeau)
    // ==========================================
    final middleArm = Path()
      ..moveTo(262, 276) // pointe gauche
      ..lineTo(364, 251) // bord supérieur
      ..cubicTo(374, 249, 377, 261, 373, 274) // coin droit
      ..lineTo(369, 289) // bord droit
      ..cubicTo(365, 303, 349, 312, 329, 316) // coin inférieur droit
      ..cubicTo(306, 319, 284, 301, 262, 276) // retour à la pointe
      ..close();

    canvas.drawPath(
      middleArm.shift(const Offset(-5, 11)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );

    canvas.drawPath(
      middleArm,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFF6F5FE), Color(0xFFC2C2D8)],
        ).createShader(const Rect.fromLTWH(259, 247, 130, 72)),
    );

    // ==========================================
    // 6. CALENDRIER : OMBRE
    // ==========================================
    final calendar = RRect.fromRectAndRadius(
      const Rect.fromLTWH(169, 304, 118, 88),
      const Radius.circular(36),
    );

    canvas.drawRRect(
      calendar.shift(const Offset(-3, 8)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.32)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    // ==========================================
    // 7. CORPS DU CALENDRIER
    // ==========================================
    canvas.drawRRect(
      calendar,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFF6F6FD), Color(0xFFE7E6F4)],
        ).createShader(const Rect.fromLTWH(169, 304, 118, 88)),
    );

    // ==========================================
    // 8. ANNEAUX DU CALENDRIER
    // ==========================================
    final ringPaint = Paint()
      ..color = const Color(0xFFFBFAFF)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(const Offset(203, 272), const Offset(203, 310), ringPaint);

    canvas.drawLine(const Offset(251, 272), const Offset(251, 310), ringPaint);

    // ==========================================
    // 9. PETITS CARRÉS DU CALENDRIER
    // ==========================================
    final dotPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFAEADC6), Color(0xFF9B9AB6)],
      ).createShader(const Rect.fromLTWH(190, 322, 76, 50));

    const dots = [
      Offset(203, 331),
      Offset(229, 331),
      Offset(255, 331),
      Offset(203, 357),
      Offset(229, 357),
      Offset(255, 357),
    ];

    for (final point in dots) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: point, width: 15, height: 15),
          const Radius.circular(4),
        ),
        dotPaint,
      );
    }

    // ==========================================
    // FIN
    // ==========================================
    canvas.restore(); // échelle du symbole
    canvas.restore(); // découpe du fond
    canvas.restore(); // échelle du canvas
  }

  @override
  bool shouldRepaint(covariant FlowdayLogoPainter oldDelegate) =>
      oldDelegate.framed != framed || oldDelegate.symbolScale != symbolScale;
}
