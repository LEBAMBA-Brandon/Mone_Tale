import 'package:flutter/material.dart';
import 'package:tala/core/theme/app_dimensions.dart';

/// Rangée de puces qui défile horizontalement (filtres d'une liste).
/// Une seule ligne : sur un petit écran, on fait glisser du doigt.
class BarrePuces extends StatelessWidget {
  const BarrePuces({super.key, required this.puces});

  final List<Widget> puces;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: puces.length,
        separatorBuilder: (context, index) =>
            const SizedBox(width: AppEspacements.s),
        itemBuilder: (context, index) => Center(child: puces[index]),
      ),
    );
  }
}
