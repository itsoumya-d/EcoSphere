import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class ResourceMap extends StatelessWidget {
  const ResourceMap({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          color: Colors.grey[200],
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.map, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Map View',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Example Pins
        Positioned(
          top: 150,
          left: 100,
          child: _buildPin(context, Icons.store),
        ),
        Positioned(
          top: 300,
          right: 80,
          child: _buildPin(context, Icons.recycling),
        ),
        Positioned(
          bottom: 200,
          left: 50,
          child: _buildPin(context, Icons.electric_car),
        ),
      ],
    );
  }

  Widget _buildPin(BuildContext context, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                blurRadius: 8,
                color: Colors.black26,
                offset: Offset(0, 4),
              )
            ],
          ),
          child: Icon(icon, color: AppColors.primary, size: 24),
        ),
        Icon(Icons.arrow_drop_down, color: Colors.white.withOpacity(0.8), size: 32),
      ],
    );
  }
}
