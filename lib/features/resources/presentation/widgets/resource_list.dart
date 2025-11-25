import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class ResourceList extends StatelessWidget {
  const ResourceList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                index % 2 == 0 ? Icons.store : Icons.recycling,
                color: AppColors.primary,
                size: 32,
              ),
            ),
            title: Text(
              index % 2 == 0 ? 'Green Grocer' : 'Community Recycling',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              index % 2 == 0 ? 'Organic & Local Produce • 0.5 mi' : 'Electronics & Glass • 1.2 mi',
              style: TextStyle(color: AppColors.textSecondaryLight),
            ),
            trailing: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.directions, color: AppColors.primary),
            ),
          ),
        );
      },
    );
  }
}
