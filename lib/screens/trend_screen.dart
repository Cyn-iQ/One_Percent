import 'package:flutter/material.dart';

import '../models/daily_snapshot.dart';
import '../models/primary_attribute.dart';
import '../services/app_repository.dart';
import '../utils/formatters.dart';
import '../widgets/trend_chart.dart';

class TrendScreen extends StatefulWidget {
  const TrendScreen({
    super.key,
    required this.repository,
  });

  final AppRepository repository;

  @override
  State<TrendScreen> createState() => _TrendScreenState();
}

class _TrendScreenState extends State<TrendScreen> {
  bool _loading = true;
  String? _error;
  int _days = 7;
  List<DailySnapshot> _snapshots = [];

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
      final snapshots = await widget.repository.getTrendSnapshots(days: _days);
      if (!mounted) return;
      setState(() {
        _snapshots = snapshots;
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

  List<String> get _labels {
    return _snapshots.map((e) => e.date.substring(5)).toList();
  }

  List<double> get _totalValues {
    return _snapshots.map((e) => e.totalScore).toList();
  }

  List<double> _primaryValues(PrimaryAttributeType type) {
    return _snapshots.map((e) => e.scoreOf(type)).toList();
  }

  double? get _periodChangeValue {
    if (_snapshots.length < 2) return null;
    return _snapshots.last.totalScore - _snapshots.first.totalScore;
  }

  double? get _averageDailyChange {
    if (_snapshots.length < 2) return null;
    final delta = _snapshots.last.totalScore - _snapshots.first.totalScore;
    return delta / (_snapshots.length - 1);
  }

  _PrimaryChangeStat? get _maxIncrease {
    if (_snapshots.length < 2) return null;

    _PrimaryChangeStat? best;
    for (final type in PrimaryAttributeType.values) {
      final first = _snapshots.first.scoreOf(type);
      final last = _snapshots.last.scoreOf(type);
      final change = last - first;
      final stat = _PrimaryChangeStat(type: type, change: change);

      if (best == null || stat.change > best.change) {
        best = stat;
      }
    }
    return best;
  }

  _PrimaryChangeStat? get _maxDecrease {
    if (_snapshots.length < 2) return null;

    _PrimaryChangeStat? best;
    for (final type in PrimaryAttributeType.values) {
      final first = _snapshots.first.scoreOf(type);
      final last = _snapshots.last.scoreOf(type);
      final change = last - first;
      final stat = _PrimaryChangeStat(type: type, change: change);

      if (best == null || stat.change < best.change) {
        best = stat;
      }
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    final increase = _maxIncrease;
    final decrease = _maxDecrease;

    return Scaffold(
      appBar: AppBar(
        title: const Text('趋势分析'),
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
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              '观察区间',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          SegmentedButton<int>(
                            segments: const [
                              ButtonSegment<int>(
                                value: 7,
                                label: Text('7天'),
                              ),
                              ButtonSegment<int>(
                                value: 30,
                                label: Text('30天'),
                              ),
                            ],
                            selected: {_days},
                            onSelectionChanged: (values) async {
                              final selected = values.first;
                              if (selected == _days) return;
                              setState(() {
                                _days = selected;
                              });
                              await _load();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _OverviewCard(
                        snapshotCount: _snapshots.length,
                        periodChangeValue: _periodChangeValue,
                        averageDailyChange: _averageDailyChange,
                        maxIncrease: increase,
                        maxDecrease: decrease,
                      ),
                      const SizedBox(height: 16),
                      TrendChart(
                        title: '总点数趋势',
                        values: _totalValues,
                        labels: _labels,
                      ),
                      const SizedBox(height: 16),
                      ...PrimaryAttributeType.values.map(
                        (type) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: TrendChart(
                            title: '${type.label}趋势',
                            values: _primaryValues(type),
                            labels: _labels,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.snapshotCount,
    required this.periodChangeValue,
    required this.averageDailyChange,
    required this.maxIncrease,
    required this.maxDecrease,
  });

  final int snapshotCount;
  final double? periodChangeValue;
  final double? averageDailyChange;
  final _PrimaryChangeStat? maxIncrease;
  final _PrimaryChangeStat? maxDecrease;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: snapshotCount < 2
            ? const Text('当前快照不足，至少记录 2 天后才能形成有效趋势。')
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '区间统计',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _StatChip(
                        label: '区间变化',
                        value: periodChangeValue == null
                            ? '暂无'
                            : AppFormatters.delta(periodChangeValue!),
                      ),
                      _StatChip(
                        label: '平均每日变化',
                        value: averageDailyChange == null
                            ? '暂无'
                            : AppFormatters.delta(averageDailyChange!),
                      ),
                      _StatChip(
                        label: '增长最多',
                        value: maxIncrease == null
                            ? '暂无'
                            : '${maxIncrease!.type.label} ${AppFormatters.delta(maxIncrease!.change)}',
                      ),
                      _StatChip(
                        label: '下降最多',
                        value: maxDecrease == null
                            ? '暂无'
                            : '${maxDecrease!.type.label} ${AppFormatters.delta(maxDecrease!.change)}',
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 130),
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

class _PrimaryChangeStat {
  const _PrimaryChangeStat({
    required this.type,
    required this.change,
  });

  final PrimaryAttributeType type;
  final double change;
}