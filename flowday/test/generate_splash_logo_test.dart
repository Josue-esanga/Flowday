import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flowday/shared/widgets/flowday_logo.dart';

/// Génère les PNG du logo de l'écran de démarrage natif :
/// Android (une taille par densité → 140 dp partout) et iOS (1x/2x/3x
/// → 140 pt). Le même rendu `CustomPaint` que dans l'application.
///
/// Exécution (regénère les assets) :
/// `flutter test test/generate_splash_logo_test.dart --dart-define=GENERATE_SPLASH_LOGO=true`
/// Sans le drapeau, le test ne fait rien (les PNG sont déjà versionnés).
void main() {
  const generate = bool.fromEnvironment('GENERATE_SPLASH_LOGO');

  const targets = <String, double>{
    // Android : 140 dp aux densités mdpi/hdpi/xhdpi/xxhdpi/xxxhdpi.
    'android/app/src/main/res/drawable-mdpi/launch_logo.png': 140,
    'android/app/src/main/res/drawable-hdpi/launch_logo.png': 210,
    'android/app/src/main/res/drawable-xhdpi/launch_logo.png': 280,
    'android/app/src/main/res/drawable-xxhdpi/launch_logo.png': 420,
    'android/app/src/main/res/drawable-xxxhdpi/launch_logo.png': 560,
    // iOS : 140 pt en 1x / 2x / 3x.
    'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png': 140,
    'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@2x.png': 280,
    'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png': 420,
  };

  testWidgets('génère les logos de splash', (tester) async {
    if (!generate) return; // assets déjà versionnés : rien à faire

    const key = Key('splash-logo');

    for (final entry in targets.entries) {
      final size = entry.value;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: RepaintBoundary(
              key: key,
              child: SizedBox(
                width: size,
                height: size,
                child: FlowdayLogo(size: size),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final bytes = await tester.runAsync(() async {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(key),
        );
        final image = await boundary.toImage(pixelRatio: 1);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        return data?.buffer.asUint8List();
      });

      expect(bytes, isNotNull, reason: entry.key);
      File(entry.key)
        ..parent.createSync(recursive: true)
        ..writeAsBytesSync(bytes!);
      // ignore: avoid_print
      print('${entry.key} : ${bytes.length} octets');
    }
  });
}
