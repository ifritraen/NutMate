import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/services/ai_export_service.dart';
import '../../core/services/haptic_service.dart';
import '../../core/theme/app_theme.dart';
import '../providers/app_providers.dart';

enum AiExportRange { week, month, threeMonths, sixMonths, year, all }
enum AiExportMode { fullHistory, summary }

class AiExportDialog extends ConsumerStatefulWidget {
  const AiExportDialog({super.key});

  @override
  ConsumerState<AiExportDialog> createState() => _AiExportDialogState();
}

class _AiExportDialogState extends ConsumerState<AiExportDialog> {
  AiExportRange _range = AiExportRange.month;
  AiExportMode _mode = AiExportMode.fullHistory;

  DateTime get _startDate {
    final now = DateTime.now();
    switch (_range) {
      case AiExportRange.week:
        return now.subtract(const Duration(days: 7));
      case AiExportRange.month:
        return now.subtract(const Duration(days: 30));
      case AiExportRange.threeMonths:
        return now.subtract(const Duration(days: 90));
      case AiExportRange.sixMonths:
        return now.subtract(const Duration(days: 180));
      case AiExportRange.year:
        return now.subtract(const Duration(days: 365));
      case AiExportRange.all:
        return DateTime(2020);
    }
  }

  String _generateContent(String format) {
    final logs = ref.read(logsProvider);
    final watchLogs = ref.read(watchLogsProvider);
    if (format == 'csv') {
      return AiExportService.generateCsv(logs, watchLogs);
    } else if (format == 'html') {
      return AiExportService.generateHtml(logs, watchLogs);
    } else {
      if (_mode == AiExportMode.fullHistory) {
        return AiExportService.generateFullHistoryReport(
          logs: logs,
          watchLogs: watchLogs,
          startDate: _startDate,
          endDate: DateTime.now(),
        );
      } else {
        return AiExportService.generateReport(
          logs: logs,
          watchLogs: watchLogs,
          startDate: _startDate,
          endDate: DateTime.now(),
        );
      }
    }
  }

  Future<void> _copyToClipboard() async {
    HapticService.selectionClick();
    final report = _generateContent('md');
    await Clipboard.setData(ClipboardData(text: report));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_mode == AiExportMode.fullHistory
              ? 'Comprehensive Full History Report copied to clipboard!'
              : 'Summary Analytics Report copied to clipboard!'),
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _exportFile(String extension) async {
    HapticService.mediumImpact();
    final content = _generateContent(extension);

    final tempDir = await getTemporaryDirectory();
    final modePrefix = _mode == AiExportMode.fullHistory ? 'full_history' : 'summary';
    final fileName = 'nutmate_${modePrefix}_export_${DateTime.now().millisecondsSinceEpoch}.$extension';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsString(content);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export ready ($fileName). Choose app/location to save...'),
          duration: const Duration(seconds: 3),
        ),
      );
    }

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'NutMate Habit & Activity Report',
      subject: fileName,
    );

    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          Icon(Icons.psychology, color: AppTheme.secondaryCyan),
          const SizedBox(width: 10),
          Text('AI Analysis & Export', style: theme.textTheme.titleLarge),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Export comprehensive habit histories, execution methods, lifestyle factors, and notes tailored for AI prompts, spreadsheets, or offline archiving.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 16),

            Text('Export Mode:', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  avatar: const Icon(Icons.history_edu, size: 18),
                  label: const Text('Full History (All Data)', style: TextStyle(fontWeight: FontWeight.bold)),
                  selected: _mode == AiExportMode.fullHistory,
                  onSelected: (val) {
                    if (val) {
                      HapticService.selectionClick();
                      setState(() => _mode = AiExportMode.fullHistory);
                    }
                  },
                ),
                ChoiceChip(
                  avatar: const Icon(Icons.analytics_outlined, size: 18),
                  label: const Text('Summary Analytics'),
                  selected: _mode == AiExportMode.summary,
                  onSelected: (val) {
                    if (val) {
                      HapticService.selectionClick();
                      setState(() => _mode = AiExportMode.summary);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              _mode == AiExportMode.fullHistory
                  ? 'Includes every detail: Dates, Methods, Stimulus, Positions, Counts, Pre/Post habits, & Notes.'
                  : 'Includes aggregated averages, top triggers, key stats, and recent session highlights.',
              style: TextStyle(color: AppTheme.secondaryCyan.withOpacity(0.85), fontSize: 12),
            ),
            const SizedBox(height: 16),

            Text('Select Date Range:', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _buildRangeChip('Last Week', AiExportRange.week),
                _buildRangeChip('Last Month', AiExportRange.month),
                _buildRangeChip('3 Months', AiExportRange.threeMonths),
                _buildRangeChip('6 Months', AiExportRange.sixMonths),
                _buildRangeChip('Year', AiExportRange.year),
                _buildRangeChip('All Time', AiExportRange.all),
              ],
            ),
            const SizedBox(height: 20),

            Text('Export Format:', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary),
                  onPressed: () => _exportFile('md'),
                  icon: const Icon(Icons.code, size: 16),
                  label: const Text('.MD for AI'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                  onPressed: () => _exportFile('csv'),
                  icon: const Icon(Icons.table_chart, size: 16),
                  label: const Text('.CSV Data'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                  onPressed: () => _exportFile('html'),
                  icon: const Icon(Icons.html, size: 16),
                  label: const Text('.HTML Report'),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: _copyToClipboard,
          icon: const Icon(Icons.copy, size: 18),
          label: const Text('Copy to Clipboard'),
        ),
      ],
    );
  }

  Widget _buildRangeChip(String label, AiExportRange range) {
    final isSelected = _range == range;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: isSelected,
      onSelected: (val) {
        if (val) {
          HapticService.selectionClick();
          setState(() => _range = range);
        }
      },
    );
  }
}
