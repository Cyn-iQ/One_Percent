import 'package:flutter/material.dart';

import '../models/secondary_attribute.dart';
import '../utils/formatters.dart';

class SecondaryTile extends StatelessWidget {
  const SecondaryTile({
    super.key,
    required this.attribute,
    required this.currentScore,
    this.onTap,
    this.trailing,
  });

  final SecondaryAttribute attribute;
  final double currentScore;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.8,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        onTap: onTap,
        title: Text(
          attribute.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if ((attribute.description ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                attribute.description!.trim(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 6),
            Text(
              attribute.isArchived ? '已归档' : '激活中',
              style: TextStyle(
                fontSize: 12,
                color: attribute.isArchived
                    ? Colors.orange
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        trailing: trailing ??
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  AppFormatters.score(currentScore),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 2),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
      ),
    );
  }
}