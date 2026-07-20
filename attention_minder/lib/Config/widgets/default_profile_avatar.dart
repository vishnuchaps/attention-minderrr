import 'package:flutter/material.dart';

/// Neutral profile artwork used until a user uploads a photo.
///
/// This is intentionally rendered with Flutter primitives so it remains sharp
/// at every avatar size and does not imply a specific age, gender, or identity.
class DefaultProfileAvatar extends StatelessWidget {
  final double size;

  const DefaultProfileAvatar({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'Default profile picture',
      child: SizedBox.square(
        dimension: size,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF1F7FF), Color(0xFFD8EAFE)],
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: size * 0.68,
                height: size * 0.68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.72),
                ),
              ),
              Icon(
                Icons.person_rounded,
                color: const Color(0xFF3979B8),
                size: size * 0.52,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
