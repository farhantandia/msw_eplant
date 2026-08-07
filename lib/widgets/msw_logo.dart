import 'package:flutter/material.dart';

class MswLogo extends StatelessWidget {
  final double size;
  const MswLogo({super.key, this.size = 28});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.26),
      child: Image.asset(
        'asset/logo_login.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }
}
