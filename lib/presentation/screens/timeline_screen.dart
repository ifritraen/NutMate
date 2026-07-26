import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/models/log_entry.dart';
import '../providers/app_providers.dart';
import '../widgets/floating_top_bar.dart';
import '../widgets/glass_card.dart';
import '../widgets/log_detail_modal.dart';
import 'add_log_screen.dart';

class TimelineScreen extends ConsumerStatefulWidget {
  final bool isNavVisible;

  const TimelineScreen({super.key, this.isNavVisible = true});

  @override
  ConsumerState<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends ConsumerState<TimelineScreen> {
  String _searchQuery = '';
  SessionType? _typeFilter;
  DateTime? _selectedDate;

  String _getIntervalText(LogEntry currentLog, List<LogEntry> allLogs) {
    final sorted = List<LogEntry>.from(allLogs)..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final index = sorted.indexWhere((e) => (e.id != null && e.id == currentLog.id) || (e.createdAt == currentLog.createdAt && e.type == currentLog.type));
    if (index <= 0) {
      return '⏱️ First Entry';
    }
    final prevLog = sorted[index - 1];
    final diff = currentLog.createdAt.difference(prevLog.createdAt);
    if (diff.isNegative) return '⏱️ First Entry';

    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final mins = diff.inMinutes % 60;

    final parts = <String>[];
    if (days > 0) parts.add('${days}d');
    if (hours > 0 || days > 0) parts.add('${hours}h');
    parts.add('${mins}m');

    return '⏱️ +${parts.join(' ')} since prev session';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final allLogs = ref.watch(logsProvider);

    final filteredLogs = allLogs.where((log) {
      if (_typeFilter != null && log.type != _typeFilter) return false;

      if (_selectedDate != null) {
        final sameDay = log.createdAt.year == _selectedDate!.year && log.createdAt.month == _selectedDate!.month && log.createdAt.day == _selectedDate!.day;
        if (!sameDay) return false;
      }

      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchReason = log.reason.toLowerCase().contains(query);
        final matchTrigger = log.trigger.toLowerCase().contains(query);
        final matchStimulus = log.stimulus.toLowerCase().contains(query);
        final matchMood = log.mood.toLowerCase().contains(query);
        final matchBefore = log.beforeNotes.toLowerCase().contains(query);
        final matchLocation = log.location.toLowerCase().contains(query);
        final matchTags = log.tags.any((t) => t.toLowerCase().contains(query));
        return matchReason || matchTrigger || matchStimulus || matchMood || matchBefore || matchLocation || matchTags;
      }

      return true;
    }).toList();

    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');

    return Scaffold(
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 80),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Search tags, notes, triggers...',
                            hintStyle: const TextStyle(color: Colors.white38),
                            prefixIcon: const Icon(Icons.search, color: Colors.white38),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.05),
                            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (val) => setState(() => _searchQuery = val),
                        ),
                      ),
                      const SizedBox(width: 8),
                      PopupMenuButton<SessionType?>(
                        icon: Icon(Icons.filter_list, color: AppTheme.getAccentColor(settings.accentColor)),
                        onSelected: (val) => setState(() => _typeFilter = val),
                        itemBuilder: (_) => [
                          const PopupMenuItem(value: null, child: Text('All Types')),
                          const PopupMenuItem(value: SessionType.masturbation, child: Text('💦 Masturbation')),
                          const PopupMenuItem(value: SessionType.edging, child: Text('⚡ Edging')),
                          const PopupMenuItem(value: SessionType.arousal, child: Text('🔥 Arousal')),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: filteredLogs.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.history_toggle_off, size: 64, color: Colors.white.withOpacity(0.2)),
                              const SizedBox(height: 16),
                              Text('No session logs found', style: theme.textTheme.titleMedium?.copyWith(color: Colors.white54)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 90),
                          itemCount: filteredLogs.length,
                          itemBuilder: (context, index) {
                            final log = filteredLogs[index];
                            final iconEmoji = log.type == SessionType.masturbation ? '💦' : (log.type == SessionType.edging ? '⚡' : '🔥');
                            final badgeLabel = log.type == SessionType.masturbation ? '💦 Masturbation' : (log.type == SessionType.edging ? '⚡ Edging' : '🔥 Arousal');
                            final badgeBg = log.type == SessionType.masturbation ? theme.colorScheme.primary.withOpacity(0.3) : (log.type == SessionType.edging ? Colors.amber.withOpacity(0.3) : Colors.deepOrange.withOpacity(0.3));
                            final badgeTextColor = log.type == SessionType.masturbation ? Colors.purpleAccent : (log.type == SessionType.edging ? Colors.amberAccent : Colors.orangeAccent);
                            final intervalStr = _getIntervalText(log, allLogs);

                            if (settings.compactTimeline) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: InkWell(
                                  onTap: () => LogDetailModal.show(context, log, intervalStr),
                                  borderRadius: BorderRadius.circular(16),
                                  child: GlassCard(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    child: Row(
                                      children: [
                                        Text(iconEmoji, style: const TextStyle(fontSize: 18)),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(dateFormat.format(log.createdAt), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                                              Text('${log.durationMinutes.toStringAsFixed(0)} mins • Urge: ${log.urge}/10 • ${log.location}', style: const TextStyle(color: Colors.white60, fontSize: 11)),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.edit, color: Colors.white38, size: 18),
                                          onPressed: () {
                                            Navigator.push(context, MaterialPageRoute(builder: (_) => AddLogScreen(existingLog: log)));
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: InkWell(
                                onTap: () => LogDetailModal.show(context, log, intervalStr),
                                borderRadius: BorderRadius.circular(16),
                                child: GlassCard(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: badgeBg,
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              badgeLabel,
                                              style: TextStyle(color: badgeTextColor, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          if (log.location.isNotEmpty) Text('• ${log.location}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                          const Spacer(),
                                          Text(dateFormat.format(log.createdAt), style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                          PopupMenuButton<String>(
                                            icon: const Icon(Icons.more_vert, color: Colors.white38, size: 20),
                                            onSelected: (val) async {
                                              if (val == 'view') {
                                                LogDetailModal.show(context, log, intervalStr);
                                              } else if (val == 'edit') {
                                                Navigator.push(context, MaterialPageRoute(builder: (_) => AddLogScreen(existingLog: log)));
                                              } else if (val == 'delete') {
                                                if (log.id != null) {
                                                  await ref.read(logsProvider.notifier).deleteLog(log.id!);
                                                }
                                              }
                                            },
                                            itemBuilder: (_) => [
                                              const PopupMenuItem(value: 'view', child: Text('View Details')),
                                              const PopupMenuItem(value: 'edit', child: Text('Edit Log')),
                                              const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.redAccent))),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      // Prominent Interval Badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppTheme.secondaryCyan.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          intervalStr,
                                          style: const TextStyle(color: AppTheme.secondaryCyan, fontSize: 11, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Text('Duration: ${log.durationMinutes.toStringAsFixed(0)} mins', style: const TextStyle(color: Colors.white70)),
                                          const SizedBox(width: 16),
                                          Text('Urge: ${log.urge}/10', style: const TextStyle(color: Colors.white70)),
                                          const SizedBox(width: 16),
                                          Text('Method: ${log.method}', style: const TextStyle(color: Colors.white60)),
                                        ],
                                      ),
                                      if (log.tags.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 4,
                                          children: log.tags.map((t) => Text(t, style: const TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.w600))).toList(),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: FloatingTopBar(
              title: settings.stealthMode ? 'Daily Notes Feed' : 'Session Timeline',
              isVisible: widget.isNavVisible,
              actions: [
                IconButton(
                  icon: Icon(settings.compactTimeline ? Icons.view_headline : Icons.view_agenda, color: AppTheme.getAccentColor(settings.accentColor)),
                  onPressed: () {
                    ref.read(settingsProvider.notifier).setCompactTimeline(!settings.compactTimeline);
                  },
                ),
                IconButton(
                  icon: Icon(Icons.calendar_today, color: _selectedDate != null ? AppTheme.getAccentColor(settings.accentColor) : Colors.white),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => _selectedDate = picked);
                    }
                  },
                ),
                if (_selectedDate != null || _typeFilter != null || _searchQuery.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear_all, color: Colors.amber),
                    onPressed: () {
                      setState(() {
                        _selectedDate = null;
                        _typeFilter = null;
                        _searchQuery = '';
                      });
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
