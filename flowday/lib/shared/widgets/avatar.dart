import 'dart:convert';

import 'package:flutter/material.dart';

/// Source d'affichage d'une photo de profil :
/// - URL **Supabase Storage** (`https://…`) — cas normal depuis que les
///   photos sont stockées en ligne ;
/// - ancienne photo locale `data:image/…;base64,…` (comptes migrés).
///
/// Renvoie `null` si la valeur est absente ou illisible (→ initiales).
ImageProvider? decodeAvatarImage(String? source) {
  if (source == null || source.isEmpty) return null;
  if (source.startsWith('http://') || source.startsWith('https://')) {
    return NetworkImage(source);
  }
  if (!source.startsWith('data:')) return null;
  try {
    final comma = source.indexOf(',');
    if (comma < 0) return null;
    return MemoryImage(base64Decode(source.substring(comma + 1)));
  } catch (_) {
    return null;
  }
}

/// Avatar circulaire : **photo de profil dynamique** si le compte en
/// possède une (l'en-tête se met à jour dès le changement), sinon
/// initiales sur fond de couleur (design de référence).
class Avatar extends StatelessWidget {
  const Avatar({
    super.key,
    required this.initials,
    required this.color,
    this.size = 42,
    this.image,
  });

  final String initials;
  final Color color;
  final double size;

  /// Photo de profil (URL Supabase Storage ou ancienne data-URL) —
  /// `null` → initiales.
  final String? image;

  @override
  Widget build(BuildContext context) {
    final photo = decodeAvatarImage(image);

    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: SizedBox.expand(
          child: photo != null
              ? Image(
                  image: photo,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  filterQuality: FilterQuality.high,
                  gaplessPlayback: true,
                  // Photo corrompue → retombe sur les initiales.
                  errorBuilder: (_, _, _) => _fallback(),
                  frameBuilder:
                      (context, child, frame, wasSynchronouslyLoaded) {
                        return wasSynchronouslyLoaded || frame != null
                            ? child
                            : _fallback();
                      },
                )
              : _fallback(),
        ),
      ),
    );
  }

  Widget _fallback() => ColoredBox(color: color, child: _initials());

  Widget _initials() {
    return Center(
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.38,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
