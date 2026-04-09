import 'package:flutter/material.dart';

import '../models/primary_attribute.dart';
import '../models/secondary_attribute.dart';
import '../services/app_repository.dart';
import '../utils/formatters.dart';
import '../widgets/secondary_tile.dart';
import 'secondary_detail_screen.dart';
import 'secondary_edit_screen.dart';

class PrimaryDetailScreen extends StatefulWidget {
  const PrimaryDetailScreen({
    super.key,
    required this.repository,
    required this.primaryType,
  });

  final AppRepository repository;
  final PrimaryAttributeType primaryType;

  @override
  State<PrimaryDetailScreen> createState() => _PrimaryDetailScreenState();
}

class _PrimaryDetailScreenState extends State<PrimaryDetailScreen> {
  bool _loading = true;
  String? _error;

  List<SecondaryAttribute> _activeItems = [];
  List<SecondaryAttribute> _archivedItems = [];
  Map<int, double> _scores = {};
  double _primaryContribution = 0.0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final activeItems = await widget.repository.getSecondaryAttributesByPrimary(
        widget.primaryType,
      );
      final archivedItems =
          await widget.repository.getArchivedSecondaryAttributesByPrimary(
        widget.primaryType,
      );
      final contribution =
          await widget.repository.getPrimaryContribution(widget.primaryType);

      final scoreMap = <int, double>{};
      for (final item in [...activeItems, ...archivedItems]) {
        if (item.id != null) {
          scoreMap[item.id!] =
              await widget.repository.getSecondaryCurrentScore(item.id!);
        }
      }

      if (!mounted) return;
      setState(() {
        _activeItems = activeItems;
        _archivedItems = archivedItems;
        _scores = scoreMap;
        _primaryContribution = contribution;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  double get _currentScore => PrimaryAttribute.baseScore + _primaryContribution;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.primaryType.label),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('加载失败：$_error'),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _HeaderCard(
                        title: widget.primaryType.label,
                        currentScore: _currentScore,
                        contribution: _primaryContribution,
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              '激活中的二级属性',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          FilledButton.icon(
                            onPressed: () async {
                              final changed = await Navigator.of(context).push<bool>(
                                MaterialPageRoute(
                                  builder: (_) => SecondaryEditScreen(
                                    repository: widget.repository,
                                    primaryType: widget.primaryType,
                                  ),
                                ),
                              );

                              if (changed == true) {
                                await _load();
                              }
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('新增'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (_activeItems.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('当前还没有二级属性。'),
                          ),
                        )
                      else
                      ..._activeItems.map(
                        (item) => GestureDetector(
                          onLongPress: () async {
                            final action = await showModalBottomSheet<String>(
                              context: context,
                              builder: (context) => SafeArea(
                                child: Wrap(
                                  children: [
                                    ListTile(
                                      leading: const Icon(Icons.open_in_new_rounded),
                                      title: const Text('进入详情'),
                                      onTap: () => Navigator.of(context).pop('detail'),
                                    ),
                                    ListTile(
                                      leading: const Icon(Icons.edit_rounded),
                                      title: const Text('编辑'),
                                      onTap: () => Navigator.of(context).pop('edit'),
                                    ),
                                    ListTile(
                                      leading: const Icon(Icons.archive_outlined),
                                      title: const Text('归档'),
                                      onTap: () => Navigator.of(context).pop('archive'),
                                    ),
                                  ],
                                ),
                              ),
                            );

                            if (!mounted || action == null) return;

                            if (action == 'detail') {
                              await Navigator.of(context).push<bool>(
                                MaterialPageRoute(
                                  builder: (_) => SecondaryDetailScreen(
                                    repository: widget.repository,
                                    secondaryAttributeId: item.id!,
                                  ),
                                ),
                              );
                              await _load();
                            } else if (action == 'edit') {
                              final changed = await Navigator.of(context).push<bool>(
                                MaterialPageRoute(
                                  builder: (_) => SecondaryEditScreen(
                                    repository: widget.repository,
                                    primaryType: widget.primaryType,
                                    secondaryAttribute: item,
                                  ),
                                ),
                              );
                              if (changed == true) {
                                await _load();
                              }
                            } else if (action == 'archive') {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('归档二级属性'),
                                  content: Text('确认归档“${item.name}”吗？历史记录会保留。'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(false),
                                      child: const Text('取消'),
                                    ),
                                    FilledButton(
                                      onPressed: () => Navigator.of(context).pop(true),
                                      child: const Text('确认'),
                                    ),
                                  ],
                                ),
                              );

                              if (confirmed == true) {
                                try {
                                  await widget.repository
                                      .restoreSecondaryAttributeAndRefresh(
                                    item.id!,
                                  );
                                  await _load();
                                } catch (e) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('归档失败：$e')),
                                  );
                                }
                              }
                            }
                          },
                          child: SecondaryTile(
                            attribute: item,
                            currentScore: _scores[item.id!] ?? 0.0,
                            onTap: () async {
                              await Navigator.of(context).push<bool>(
                                MaterialPageRoute(
                                  builder: (_) => SecondaryDetailScreen(
                                    repository: widget.repository,
                                    secondaryAttributeId: item.id!,
                                  ),
                                ),
                              );
                              await _load();
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        childrenPadding: EdgeInsets.zero,
                        title: Text(
                          '已归档属性（${_archivedItems.length}）',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        children: [
                          if (_archivedItems.isEmpty)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 12),
                              child: Card(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text('暂无已归档属性。'),
                                ),
                              ),
                            )
                          else
                            ..._archivedItems.map(
                              (item) => SecondaryTile(
                                attribute: item,
                                currentScore: _scores[item.id!] ?? 0.0,
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      AppFormatters.score(
                                        _scores[item.id!] ?? 0.0,
                                      ),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    OutlinedButton(
                                      onPressed: () async {
                                        try {
                                          await widget.repository
                                              .restoreSecondaryAttribute(
                                            item.id!,
                                          );
                                          if (!mounted) return;
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content:
                                                  Text('已恢复：${item.name}'),
                                            ),
                                          );
                                          await _load();
                                        } catch (e) {
                                          if (!mounted) return;
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text('恢复失败：$e'),
                                            ),
                                          );
                                        }
                                      },
                                      child: const Text('恢复'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.title,
    required this.currentScore,
    required this.contribution,
  });

  final String title;
  final double currentScore;
  final double contribution;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.2,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              AppFormatters.score(currentScore),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _InfoChip(
                  label: '基础值',
                  value: AppFormatters.score(PrimaryAttribute.baseScore),
                ),
                _InfoChip(
                  label: '二级属性贡献',
                  value: AppFormatters.delta(contribution),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label：$value',
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}