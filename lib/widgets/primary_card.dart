import 'package:flutter/material.dart';

import '../models/primary_attribute.dart';
import '../utils/formatters.dart';

class PrimaryCard extends StatelessWidget {
  const PrimaryCard({
    super.key,
    required this.attribute,
    this.onTap,
  });

  final PrimaryAttribute attribute;
  final VoidCallback? onTap;

  IconData _iconOf(PrimaryAttributeType type) {
    switch (type) {
      case PrimaryAttributeType.strength:
        return Icons.fitness_center;
      case PrimaryAttributeType.knowledge:
        return Icons.menu_book_rounded;
      case PrimaryAttributeType.virtue:
        return Icons.favorite_rounded;
      case PrimaryAttributeType.social:
        return Icons.people_alt_rounded;
      case PrimaryAttributeType.skill:
        return Icons.build_rounded;
      case PrimaryAttributeType.spirit:
        return Icons.psychology_rounded;
    }
  }

  Color _colorOf(BuildContext context, PrimaryAttributeType type) {
    switch (type) {
      case PrimaryAttributeType.strength:
        return Colors.redAccent;
      case PrimaryAttributeType.knowledge:
        return Colors.blueAccent;
      case PrimaryAttributeType.virtue:
        return Colors.pinkAccent;
      case PrimaryAttributeType.social:
        return Colors.teal;
      case PrimaryAttributeType.skill:
        return Colors.deepPurpleAccent;
      case PrimaryAttributeType.spirit:
        return Colors.orangeAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorOf(context, attribute.type);

    return Card(
      elevation: 1.5,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: color.withOpacity(0.12),
                child: Icon(
                  _iconOf(attribute.type),
                  color: color,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      attribute.type.label,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '基础值 ${AppFormatters.score(PrimaryAttribute.baseScore)}  ·  贡献 ${AppFormatters.delta(attribute.secondaryContribution)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    AppFormatters.score(attribute.currentScore),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}