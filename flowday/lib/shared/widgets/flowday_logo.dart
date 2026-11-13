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
            const Radius.circular(65),
          )
        : RRect.fromRectAndRadius(
            const Rect.fromLTWH(0, 0, 500, 500),
            Radius.zero,
          );

    if (framed) {
      canvas.drawRRect(
        background.shift(const Offset(0, 8)),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15),
      );
    }

    canvas.drawRRect(
      background,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF292930),
            Color(0xFF17171D),
            Color(0xFF08080D),
          ],
        ).createShader(const Rect.fromLTWH(5, 5, 490, 490)),
    );

    canvas.save();
    canvas.clipRRect(background);

    // ==========================================
    // 2. VAGUES DECORATIVES
    // ==========================================
    final wavePaint = Paint()
      ..color = const Color(0xFFA5A5B9).withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;

    for (int i = 0; i < 15; i++) {
      final path = Path();
      final y = 45.0 + i * 16;

      path.moveTo(0, y + 35);

      path.cubicTo(
        100,
        y - 55,
        160,
        y - 45,
        235,
        y + 30,
      );

      path.cubicTo(
        310,
        y + 110,
        380,
        y + 75,
        500,
        y + 15,
      );

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
    // 3. FORME PRINCIPALE DU F
    // ==========================================
    final fPath = Path()
      // Partie supérieure
      ..moveTo(138, 151)
      ..cubicTo(138, 105, 168, 76, 215, 76)
      ..lineTo(375, 76)
      ..cubicTo(375, 106, 350, 133, 319, 133)
      ..lineTo(243, 133)

      // Courbe intérieure
      ..cubicTo(216, 133, 203, 151, 203, 178)
      ..lineTo(203, 283)

      // Partie inférieure du F
      ..cubicTo(203, 332, 181, 363, 138, 381)
      ..lineTo(138, 151)
      ..close();

    // Ombre du F
    canvas.drawPath(
      fPath.shift(const Offset(5, 7)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // Dégradé principal
    canvas.drawPath(
      fPath,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFF2F0FF), Color(0xFFDAD8ED)],
        ).createShader(const Rect.fromLTWH(130, 70, 260, 320)),
    );

    // ==========================================
    // 4. BRANCHE HORIZONTALE DU F
    // ==========================================
    final middleArm = Path()
      ..moveTo(180, 245)
      ..lineTo(354, 245)
      ..cubicTo(351, 270, 341, 290, 318, 300)
      ..lineTo(242, 300)
      ..cubicTo(218, 300, 203, 314, 188, 337)
      ..lineTo(180, 245)
      ..close();

    canvas.drawPath(
      middleArm,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFE2E0F6), Color(0xFFB5AED8)],
        ).createShader(const Rect.fromLTWH(180, 245, 175, 100)),
    );

    // ==========================================
    // 5. INTÉRIEUR SOMBRE DU LOGO
    // ==========================================
    final inner = Path()
      ..moveTo(203, 178)
      ..cubicTo(203, 151, 221, 137, 247, 137)
      ..lineTo(333, 137)
      ..cubicTo(346, 165, 332, 202, 303, 222)
      ..lineTo(260, 247)
      ..lineTo(203, 247)
      ..close();

    canvas.drawPath(
      inner,
      Paint()..color = const Color(0xFF15151B),
    );

    // ==========================================
    // 6. COCHE BLANCHE
    // ==========================================
    final check = Path()
      ..moveTo(242, 218)
      ..lineTo(267, 242)
      ..lineTo(311, 198);

    canvas.drawPath(
      check,
      Paint()
        ..color = const Color(0xFF08080D)
        ..strokeWidth = 25
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );

    canvas.drawPath(
      check,
      Paint()
        ..shader = const LinearGradient(
          colors: [Colors.white, Color(0xFFE4E1F8)],
        ).createShader(const Rect.fromLTWH(240, 190, 75, 55))
        ..strokeWidth = 17
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );

    // ==========================================
    // 7. CALENDRIER : OMBRE
    // ==========================================
    final calendar = RRect.fromRectAndRadius(
      const Rect.fromLTWH(180, 278, 104, 101),
      const Radius.circular(23),
    );

    canvas.drawRRect(
      calendar.shift(const Offset(3, 6)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
    );

    // ==========================================
    // 8. CORPS DU CALENDRIER
    // ==========================================
    canvas.drawRRect(
      calendar,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Color(0xFFE5E4F1)],
        ).createShader(const Rect.fromLTWH(180, 278, 104, 101)),
    );

    // En-tête noir
    final header = RRect.fromRectAndCorners(
      const Rect.fromLTWH(180, 278, 104, 28),
      topLeft: const Radius.circular(17),
      topRight: const Radius.circular(17),
    );

    canvas.drawRRect(
      header,
      Paint()..color = const Color(0xFF19191F),
    );

    // ==========================================
    // 9. ANNEAUX DU CALENDRIER
    // ==========================================
    final ringPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      const Offset(210, 265),
      const Offset(210, 286),
      ringPaint,
    );

    canvas.drawLine(
      const Offset(251, 265),
      const Offset(251, 286),
      ringPaint,
    );

    // ==========================================
    // 10. PETITS CARRÉS DU CALENDRIER
    // ==========================================
    final dotPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFA7A6C0), Color(0xFF87869F)],
      ).createShader(const Rect.fromLTWH(195, 312, 75, 45));

    const dots = [
      Offset(210, 326),
      Offset(237, 326),
      Offset(264, 326),
      Offset(210, 354),
      Offset(237, 354),
      Offset(264, 354),
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
