import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/services/backup_service.dart';
import '../../core/services/biometric_service.dart';
import '../../core/services/haptic_service.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/app_settings.dart';
import '../providers/app_providers.dart';
import '../widgets/floating_top_bar.dart';
import '../widgets/glass_card.dart';
import 'ai_export_dialog.dart';

class SettingsScreen extends ConsumerWidget {
  final bool isNavVisible;

  const SettingsScreen({super.key, this.isNavVisible = true});

  void _showPinDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set 4-Digit PIN'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          maxLength: 4,
          obscureText: true,
          decoration: const InputDecoration(hintText: 'Enter 4 digits'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.length == 4) {
                final hash = BiometricService.hashPin(controller.text);
                await ref.read(settingsProvider.notifier).setPin(hash);
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Save PIN'),
          ),
        ],
      ),
    );
  }

  void _showDecoyPinDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Custom Decoy PIN'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          maxLength: 4,
          obscureText: true,
          decoration: const InputDecoration(hintText: 'Enter 4-digit decoy PIN'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.length == 4) {
                final hash = BiometricService.hashPin(controller.text);
                await ref.read(settingsProvider.notifier).setDecoyPin(hash);
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Save Decoy PIN'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportBackup(BuildContext context, WidgetRef ref) async {
    HapticService.mediumImpact();
    final logs = ref.read(logsProvider);
    final jsonStr = BackupService.exportToJson(logs);

    final tempDir = await getTemporaryDirectory();
    final fileName = 'nutmate_backup_${DateTime.now().millisecondsSinceEpoch}.json';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsString(jsonStr);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backup ready ($fileName). Choose folder/app to save...')),
      );
    }

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Nutmate Backup File',
      subject: fileName,
    );
  }

  Future<void> _importBackup(BuildContext context, WidgetRef ref) async {
    HapticService.mediumImpact();
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null && result.files.single.path != null) {
      try {
        final filePath = result.files.single.path!;
        final jsonStr = await File(filePath).readAsString();
        final logs = BackupService.importFromJson(jsonStr);

        for (var log in logs) {
          await ref.read(logsProvider.notifier).addLog(log);
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Imported ${logs.length} logs successfully!')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Import failed: ${e.toString()}'), backgroundColor: Colors.redAccent),
          );
        }
      }
    }
  }

  void _showResetConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Database?'),
        content: const Text('This will permanently delete all session logs and reset all statistics. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              HapticService.heavyImpact();
              await ref.read(logsProvider.notifier).clearAll();
              await ref.read(settingsProvider.notifier).updateEdgeCount(0);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Reset Everything'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final accentColor = AppTheme.getAccentColor(settings.accentColor);

    return Scaffold(
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.only(top: 90, left: 16, right: 16, bottom: 90),
            children: [
              GlassCard(
                color: theme.colorScheme.primary.withOpacity(0.2),
                onTap: () {
                  HapticService.selectionClick();
                  showDialog(context: context, builder: (_) => const AiExportDialog());
                },
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
                      child: const Icon(Icons.auto_awesome, color: Colors.black, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Analyze & Export AI Report', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          const Text('Export structured Markdown, CSV, or HTML for LLMs', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.white54),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Text('Stealth & Privacy', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              GlassCard(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Stealth App Title Mode'),
                      subtitle: Text(settings.stealthMode ? 'Camouflaged as "Daily Notes"' : 'Standard "Nutmate" Branding'),
                      value: settings.stealthMode,
                      onChanged: (val) {
                        HapticService.selectionClick();
                        ref.read(settingsProvider.notifier).setStealthMode(val);
                      },
                    ),
                    SwitchListTile(
                      title: const Text('PIN Lock'),
                      subtitle: Text(settings.pinEnabled ? 'PIN Lock Active' : 'Disabled'),
                      value: settings.pinEnabled,
                      onChanged: (val) {
                        HapticService.selectionClick();
                        if (val) {
                          _showPinDialog(context, ref);
                        } else {
                          ref.read(settingsProvider.notifier).setPin(null);
                        }
                      },
                    ),
                    const Divider(color: Colors.white10),
                    SwitchListTile(
                      title: const Text('Custom Decoy PIN'),
                      subtitle: Text(settings.decoyPinEnabled ? 'Custom Decoy PIN Configured' : 'Default Decoy PIN ("0000")'),
                      value: settings.decoyPinEnabled,
                      onChanged: (val) {
                        HapticService.selectionClick();
                        if (val) {
                          _showDecoyPinDialog(context, ref);
                        } else {
                          ref.read(settingsProvider.notifier).setDecoyPin(null);
                        }
                      },
                    ),
                    const Divider(color: Colors.white10),
                    SwitchListTile(
                      title: const Text('Biometric Unlock'),
                      subtitle: const Text('Use Fingerprint / Face ID to open app'),
                      value: settings.biometricEnabled,
                      onChanged: (val) async {
                        HapticService.selectionClick();
                        if (val) {
                          final available = await BiometricService.isBiometricsAvailable();
                          if (!available && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Biometric authentication is not supported or configured on this device'),
                                backgroundColor: Colors.orangeAccent,
                              ),
                            );
                            return;
                          }
                        }
                        ref.read(settingsProvider.notifier).setBiometric(val);
                      },
                    ),
                    const Divider(color: Colors.white10),
                    SwitchListTile(
                      title: const Text('Anonymize AI Exports'),
                      subtitle: const Text('Scrub custom notes before exporting reports'),
                      value: settings.anonymizeExports,
                      onChanged: (val) {
                        HapticService.selectionClick();
                        ref.read(settingsProvider.notifier).setAnonymizeExports(val);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Text('Habit Management & Widget', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              GlassCard(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Streak Freeze Mode'),
                      subtitle: const Text('Pause streak timer during travel, illness, or medical recovery'),
                      value: settings.streakFrozen,
                      onChanged: (val) {
                        HapticService.selectionClick();
                        ref.read(settingsProvider.notifier).setStreakFrozen(val);
                      },
                    ),
                    const Divider(color: Colors.white10),
                    ListTile(
                      title: const Text('Widget Update Frequency'),
                      subtitle: Text('Updates widget streak every ${settings.widgetUpdateIntervalMinutes} minutes'),
                      trailing: DropdownButton<int>(
                        value: settings.widgetUpdateIntervalMinutes,
                        dropdownColor: theme.colorScheme.surface,
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(value: 5, child: Text('5 Min (Default)')),
                          DropdownMenuItem(value: 10, child: Text('10 Min')),
                          DropdownMenuItem(value: 15, child: Text('15 Min')),
                          DropdownMenuItem(value: 30, child: Text('30 Min')),
                          DropdownMenuItem(value: 60, child: Text('60 Min')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            HapticService.selectionClick();
                            ref.read(settingsProvider.notifier).setWidgetUpdateIntervalMinutes(val);
                          }
                        },
                      ),
                    ),
                    const Divider(color: Colors.white10),
                    SwitchListTile(
                      title: const Text('Compact Timeline Layout'),
                      subtitle: const Text('Use space-saving compact rows on Timeline tab'),
                      value: settings.compactTimeline,
                      onChanged: (val) {
                        HapticService.selectionClick();
                        ref.read(settingsProvider.notifier).setCompactTimeline(val);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),


              Text('Appearance & Accent Palette', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      title: const Text('Dark Mode'),
                      leading: Radio<AppThemeMode>(
                        value: AppThemeMode.dark,
                        groupValue: settings.themeMode,
                        onChanged: (val) {
                          if (val != null) ref.read(settingsProvider.notifier).setThemeMode(val);
                        },
                      ),
                    ),
                    ListTile(
                      title: const Text('AMOLED Pure Black'),
                      leading: Radio<AppThemeMode>(
                        value: AppThemeMode.amoled,
                        groupValue: settings.themeMode,
                        onChanged: (val) {
                          if (val != null) ref.read(settingsProvider.notifier).setThemeMode(val);
                        },
                      ),
                    ),
                    const Divider(color: Colors.white10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text('Accent Color Preset', style: theme.textTheme.titleMedium),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildAccentCircle(AppAccentColor.cyan, AppTheme.secondaryCyan, settings, ref),
                        _buildAccentCircle(AppAccentColor.violet, AppTheme.primaryViolet, settings, ref),
                        _buildAccentCircle(AppAccentColor.gold, AppTheme.goldAccent, settings, ref),
                        _buildAccentCircle(AppAccentColor.emerald, AppTheme.emeraldAccent, settings, ref),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Text('Data Backup & Recovery', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              GlassCard(
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.download, color: accentColor),
                      title: const Text('Export Database (JSON)'),
                      onTap: () => _exportBackup(context, ref),
                    ),
                    const Divider(color: Colors.white10),
                    ListTile(
                      leading: const Icon(Icons.upload, color: AppTheme.primaryViolet),
                      title: const Text('Import Database (JSON)'),
                      onTap: () => _importBackup(context, ref),
                    ),
                    const Divider(color: Colors.white10),
                    ListTile(
                      leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
                      title: const Text('Reset Database', style: TextStyle(color: Colors.redAccent)),
                      onTap: () => _showResetConfirmation(context, ref),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(settings.stealthMode ? 'About Daily Notes v1.0.0' : 'About Nutmate v1.0.0', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    const Text(
                      'Nutmate is a respectful, privacy-first wellness tracker focused on masturbation and edging habits using a harm-reduction approach. No clouds, no servers, zero shame, 100% offline local storage.',
                      style: TextStyle(color: Colors.white60, fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: FloatingTopBar(
              title: settings.stealthMode ? 'Daily Notes Settings' : 'Settings & Privacy',
              isVisible: isNavVisible,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccentCircle(AppAccentColor colorEnum, Color colorVal, AppSettings settings, WidgetRef ref) {
    final isSelected = settings.accentColor == colorEnum;
    return GestureDetector(
      onTap: () {
        HapticService.selectionClick();
        ref.read(settingsProvider.notifier).setAccentColor(colorEnum);
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: colorVal,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 3,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(color: colorVal.withOpacity(0.5), blurRadius: 10, spreadRadius: 2),
                ]
              : [],
        ),
      ),
    );
  }
}
