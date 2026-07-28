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
import '../widgets/glass_card.dart';

enum AiExportRange { week, month, threeMonths, sixMonths, year, all }

class AiExportDialog extends ConsumerStatefulWidget {
  const AiExportDialog({super.key});

  @override
  ConsumerState<AiExportDialog> createState() => _AiExportDialogState();
}

class _AiExportDialogState extends ConsumerState<AiExportDialog> {
  AiExportRange _range = AiExportRange.month;

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

  Future<void> _copyToClipboard() async {
    HapticService.selectionClick();
    final logs = ref.read(logsProvider);
    final report = AiExportService.generateReport(
      logs: logs,
      startDate: _startDate,
      endDate: DateTime.now(),
    );
    await Clipboard.setData(ClipboardData(text: report));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AI Report copied to clipboard!')),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _exportFile(String extension) async {
    HapticService.mediumImpact();
    final logs = ref.read(logsProvider);
    late String content;
    if (extension == 'csv') {
      content = AiExportService.generateCsv(logs);
    } else if (extension == 'html') {
      content = AiExportService.generateHtml(logs);
    } else {
      content = AiExportService.generateReport(
        logs: logs,
        startDate: _startDate,
        endDate: DateTime.now(),
      );
    }

    final tempDir = await getTemporaryDirectory();
    final fileName = 'nutmate_export_${DateTime.now().millisecondsSinceEpoch}.$extension';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsString(content);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export ready ($fileName). Choose folder/app to save...'),
          duration: const Duration(seconds: 3),
        ),
      );
    }

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Nutmate Habit Report',
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
          Text('Analyze & Export', style: theme.textTheme.titleLarge),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Generates privacy-preserving Markdown, CSV, or HTML reports for LLMs and spreadsheets.', style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 16),
            Text('Select Date Range:', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: [
                _buildRangeChip('Last Week', AiExportRange.week),
                _buildRangeChip('Last Month', AiExportRange.month),
                _buildRangeChip('3 Months', AiExportRange.threeMonths),
                _buildRangeChip('6 Months', AiExportRange.sixMonths),
                _buildRangeChip('Year', AiExportRange.year),
                _buildRangeChip('All Time', AiExportRange.all),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary),
                  onPressed: () => _exportFile('md'),
                  icon: const Icon(Icons.code, size: 16),
                  label: const Text('.MD Report'),
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
          label: const Text('Copy Text'),
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
