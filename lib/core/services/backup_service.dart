import 'dart:convert';

import '../../domain/models/log_entry.dart';

class BackupService {
  static String exportToJson(List<LogEntry> logs) {
    final list = logs.map((e) => e.toJson()).toList();
    final data = {
      'app': 'Nutmate',
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'logs': list,
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  static List<LogEntry> importFromJson(String jsonStr) {
    final Map<String, dynamic> decoded = jsonDecode(jsonStr);
    if (!decoded.containsKey('logs')) {
      throw const FormatException('Invalid Nutmate backup JSON format.');
    }
    final List<dynamic> logsList = decoded['logs'];
    return logsList.map((e) => LogEntry.fromJson(Map<String, dynamic>.from(e))).toList();
  }
}
