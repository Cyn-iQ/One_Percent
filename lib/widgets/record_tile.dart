import 'package:flutter/material.dart';

import '../models/primary_attribute.dart';
import '../models/score_record.dart';
import '../utils/formatters.dart';

class RecordTile extends StatelessWidget {
  const RecordTile({
    super.key,
    required this.record,
  });

  final ScoreRecord record;

  @override
  Widget build(BuildContext context) {
    final deltaColor = record.delta > 0
        ? Colors.green
        : record.delta < 0
            ? Colors.red
            : Theme.of(context).colorScheme.onSurface;

    return Card(
      elevation: 0.6,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Text(
          record.secondaryNameSnapshot,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${record.primaryType.label} · ${AppFormatters.dateTime(record.createdAt)}'
          '${(record.note ?? '').trim().isEmpty ? '' : '\n${record.note!.trim()}'}',
        ),
        isThreeLine: (record.note ?? '').trim().isNotEmpty,
        trailing: Text(
          AppFormatters.delta(record.delta),
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: deltaColor,
          ),
        ),
      ),
    );
  }
}
