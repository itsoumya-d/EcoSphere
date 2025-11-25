import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;

/// Widget to display milestone celebrations (Level Up, Badge Unlock)
class MilestoneCelebration extends StatefulWidget {
  final String title;
  final String subtitle;
  final String iconUrl; // Emoji or asset path
  final Color color;
  final String? secondaryText;
  final VoidCallback onDismiss;
  final bool isLevelUp;

  const MilestoneCelebration({
    super.key,
    required this.title,
    required this.subtitle,
    required this.iconUrl,
    required this.color,
    required this.onDismiss,
    this.secondaryText,
    this.isLevelUp = false,
  });

  @override
  State<MilestoneCelebration> createState() => _MilestoneCelebrationState();
}

class _MilestoneCelebrationState extends State<MilestoneCelebration> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Dark overlay
        Positioned.fill(
          child: Container(
            color: Colors.black54,
          ).animate().fadeIn(duration: 300.ms),
        ),
        
        // Confetti (simulated with animated particles)
        if (widget.isLevelUp)
          Positioned.fill(
            child: _ConfettiOverlay(),
          ),

        // Main Card
        Center(
          child: Container(
            margin: const EdgeInsets.all(32),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon/Badge with glow
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        widget.color.withOpacity(0.2),
                        widget.color.withOpacity(0),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      widget.iconUrl,
                      style: const TextStyle(fontSize: 64),
                    ),
                  ),
                ).animate()
                 .scale(duration: 600.ms, curve: Curves.elasticOut)
                 .then()
                 .shimmer(duration: 1200.ms, color: Colors.white.withOpacity(0.5)),

                const SizedBox(height: 24),

                // Title
                Text(
                  widget.title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: widget.color,
                      ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),

                const SizedBox(height: 8),

                // Subtitle
                Text(
                  widget.subtitle,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 500.ms),

                if (widget.secondaryText != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.secondaryText!,
                      style: TextStyle(
                        color: widget.color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ).animate().fadeIn(delay: 700.ms).scale(),
                ],

                const SizedBox(height: 32),

                // Button
                FilledButton(
                  onPressed: widget.onDismiss,
                  style: FilledButton.styleFrom(
                    backgroundColor: widget.color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: const Text('Awesome!'),
                ).animate().fadeIn(delay: 900.ms).slideY(begin: 0.5, end: 0),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ConfettiOverlay extends StatefulWidget {
  @override
  State<_ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<_ConfettiOverlay> with SingleTickerProviderStateMixin {
  final List<_Particle> particles = [];
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
    
    // Generate particles
    for (int i = 0; i < 50; i++) {
      particles.add(_Particle());
    }
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
        return CustomPaint(
          painter: _ConfettiPainter(particles, _controller.value),
        );
      },
    );
  }
}

class _Particle {
  double x = math.Random().nextDouble();
  double y = math.Random().nextDouble() - 1.0; // Start above screen
  double speed = math.Random().nextDouble() * 0.01 + 0.005;
  double angle = math.Random().nextDouble() * math.pi * 2;
  double spin = math.Random().nextDouble() * 0.2 - 0.1;
  Color color = Colors.primaries[math.Random().nextInt(Colors.primaries.length)];
  
  void update() {
    y += speed;
    angle += spin;
    if (y > 1.0) {
      y = -0.2; // Reset to top
      x = math.Random().nextDouble();
    }
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double animationValue;

  _ConfettiPainter(this.particles, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      particle.update();
      
      final paint = Paint()..color = particle.color;
      final x = particle.x * size.width;
      final y = particle.y * size.height;
      
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(particle.angle);
      canvas.drawRect(const Rect.fromLTWH(-4, -4, 8, 8), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
