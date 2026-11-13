import 'dart:convert';

import 'package:flutter/material.dart';

/// Décode une photo de profil stockée en `data:image/…;base64,…`.
/// Renvoie `null` si l'URL est absente ou illisible (→ initiales).
ImageProvider? decodeAvatarImage(String? dataUrl) {
  if (dataUrl == null || dataUrl.isEmpty) return null;
  try {
    final comma = dataUrl.indexOf(',');
    final base64Part = comma >= 0 ? dataUrl.substring(comma + 1) : dataUrl;
    return MemoryImage(base64Decode(base64Part));
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

  /// Photo de profil (`data:image/…;base64,…`) — `null` → initiales.
  final String? image;

  @override
  Widget build(BuildContext context) {
    final photo = decodeAvatarImage(image);

    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: photo != null
          ? Image(
              image: photo,
              fit: BoxFit.cover,
              width: size,
              height: size,
              // Photo corrompue → retombe sur les initiales.
              errorBuilder: (_, _, _) => _initials(),
            )
          : _initials(),
    );
  }

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
