import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Account Section
          _buildSectionHeader(context, 'Account'),
          ListTile(
            leading: Icon(Icons.person, color: colorScheme.primary),
            title: const Text('Account'),
            subtitle: Text(currentUser?.email ?? 'Not signed in'),
            trailing: const Icon(Icons.chevron_right),
          ),
          ListTile(
            leading: Icon(Icons.privacy_tip, color: colorScheme.primary),
            title: const Text('Privacy'),
            subtitle: const Text('Control your data and privacy'),
            trailing: const Icon(Icons.chevron_right),
          ),
          const Divider(),

          // Preferences Section
          _buildSectionHeader(context, 'Preferences'),
          SwitchListTile(
            secondary: Icon(Icons.notifications, color: colorScheme.primary),
            title: const Text('Notifications'),
            subtitle: const Text('Receive updates and reminders'),
            value: true,
            onChanged: (value) {
              // TODO: Implement notification toggle
            },
          ),
          ListTile(
            leading: Icon(Icons.straighten, color: colorScheme.primary),
            title: const Text('Units'),
            subtitle: Text(currentUser?.preferredUnits ?? 'Metric'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Show units picker
            },
          ),
          const Divider(),

          // About Section
          _buildSectionHeader(context, 'About'),
          ListTile(
            leading: Icon(Icons.info, color: colorScheme.primary),
            title: const Text('About EcoSphere'),
            subtitle: const Text('Version 1.0.0'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showAboutDialog(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.description, color: colorScheme.primary),
            title: const Text('Terms of Service'),
            trailing: const Icon(Icons.chevron_right),
          ),
          ListTile(
            leading: Icon(Icons.shield, color: colorScheme.primary),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.chevron_right),
          ),
          const Divider(),

          // Data Section
          _buildSectionHeader(context, 'Data'),
          ListTile(
            leading: Icon(Icons.download, color: colorScheme.primary),
            title: const Text('Export Data'),
            subtitle: const Text('Download your data'),
            trailing: const Icon(Icons.chevron_right),
          ),
          ListTile(
            leading: Icon(Icons.delete_sweep, color: colorScheme.error),
            title: Text(
              'Delete Account',
              style: TextStyle(color: colorScheme.error),
            ),
            subtitle: const Text('Permanently delete your account'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showDeleteAccountDialog(context, ref);
            },
          ),
          const SizedBox(height: 16),

          // Sign Out Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.tonalIcon(
              onPressed: () {
                _showSignOutDialog(context, ref);
              },
              icon: const Icon(Icons.logout),
              label: const Text('Sign Out'),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'EcoSphere',
      applicationVersion: '1.0.0',
      applicationIcon: Icon(
        Icons.eco,
        size: 48,
        color: Theme.of(context).colorScheme.primary,
      ),
      children: const [
        Text(
          'EcoSphere helps you track and reduce your carbon footprint through gamification and community engagement.',
        ),
      ],
    );
  }

  void _showSignOutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).signOut();
              if (context.mounted) {
                Navigator.pop(context);
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to permanently delete your account? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account deletion feature coming soon'),
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
