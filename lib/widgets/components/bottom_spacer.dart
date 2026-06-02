import 'package:flutter/material.dart';

/// Un composant réutilisable pour ajouter un espace uniforme au bas des écrans
class BottomSpacer extends StatelessWidget {
  final double height;

  const BottomSpacer({
    Key? key,
    this.height = 80.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: height);
  }
}
