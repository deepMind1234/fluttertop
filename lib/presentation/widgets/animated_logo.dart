import 'dart:math' as math;
import 'package:flutter/material.dart';

class AnimatedLogo extends StatefulWidget {
  const AnimatedLogo({super.key});

  @override
  State<AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<AnimatedLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // A 1.5-second looping animation for the bouncy effect
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Sine wave for bouncing effect
        final bounce1 = math.sin(_controller.value * 2 * math.pi);
        // Out of phase bounce for the second letter
        final bounce2 = math.sin((_controller.value + 0.3) * 2 * math.pi);

        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Bubbly 'F'
            Transform.translate(
              offset: Offset(0, -4 * bounce1),
              child: Transform.scale(
                scale: 1.0 + (0.15 * bounce1),
                child: const Text(
                  'F',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.cyanAccent,
                    shadows: [Shadow(color: Colors.cyan, blurRadius: 12)],
                  ),
                ),
              ),
            ),
            // 'lutter' part
            const Text(
              'lutter',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            // Bubbly 'T'
            Transform.translate(
              offset: Offset(0, -4 * bounce2),
              child: Transform.scale(
                scale: 1.0 + (0.15 * bounce2),
                child: const Text(
                  'T',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.pinkAccent,
                    shadows: [Shadow(color: Colors.pink, blurRadius: 12)],
                  ),
                ),
              ),
            ),
            // 'op' part
            const Text(
              'op',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        );
      },
    );
  }
}
