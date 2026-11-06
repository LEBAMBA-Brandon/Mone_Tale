import 'package:flutter/material.dart';
import 'package:mono/core/theme/couleurs_mono.dart';

/// Point bleu "Vous êtes ici", avec un halo qui pulse doucement
/// (comme sur Google Maps).
///
/// Si le téléphone a l'option "Réduire les animations", le halo reste fixe.
class MarqueurUtilisateur extends StatefulWidget {
  const MarqueurUtilisateur({super.key, this.taille = 20});

  /// Diamètre du point central (le halo fait 3 fois cette taille).
  final double taille;

  @override
  State<MarqueurUtilisateur> createState() => _MarqueurUtilisateurState();
}

class _MarqueurUtilisateurState extends State<MarqueurUtilisateur>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Respect du réglage d'accessibilité "Réduire les animations".
    if (MediaQuery.disableAnimationsOf(context)) {
      _animation.stop();
    } else if (!_animation.isAnimating) {
      _animation.repeat();
    }
  }

  @override
  void dispose() {
    _animation.dispose(); // toujours libérer une animation
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final couleur = context.couleurs.positionUtilisateur;
    final taille = widget.taille;

    return Semantics(
      label: 'Votre position',
      child: SizedBox.square(
        dimension: taille * 3,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Halo qui grandit en s'effaçant.
            AnimatedBuilder(
              animation: _animation,
              builder: (context, _) {
                final v = _animation.isAnimating ? _animation.value : 0.5;
                return Container(
                  width: taille * (1 + 2 * v),
                  height: taille * (1 + 2 * v),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: couleur.withValues(alpha: 0.35 * (1 - v)),
                  ),
                );
              },
            ),
            // Point central.
            Container(
              width: taille,
              height: taille,
              decoration: BoxDecoration(
                color: couleur,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: const [
                  BoxShadow(color: Color(0x44000000), blurRadius: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
