import 'package:flutter/material.dart';

import '../models/dashboard_data.dart';
import '../models/primary_attribute.dart';
import '../services/app_repository.dart';
import '../utils/formatters.dart';
import '../widgets/primary_card.dart';
import '../widgets/record_tile.dart';
import 'primary_detail_screen.dart';
import 'trend_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.repository,
  });

  final AppRepository repository;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DashboardData? _dashboardData;
  bool _loading = true;
  String? _error;

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
      final data = await widget.repository.getDashboardData();
      if (!mounted) return;
      setState(() {
        _dashboardData = data;
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

  Color _changeColor(double? value, BuildContext context) {
    if (value == null) return Theme.of(context).colorScheme.onSurfaceVariant;
    if (value > 0) return Colors.green;
    if (value < 0) return Colors.red;
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }

  Future<void> _openPrimaryDetail(PrimaryAttributeType type) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PrimaryDetailScreen(
          repository: widget.repository,
          primaryType: type,
        ),
      ),
    );

    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final data = _dashboardData;

    return Scaffold(
              appBar: AppBar(
                title: const Text('成长系统'),
                actions: [
                  IconButton(
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => TrendScreen(repository: widget.repository),
                        ),
                      );
                      await _load();
                    },
                    icon: const Icon(Icons.show_chart_rounded),
                    tooltip: '趋势分析',
                  ),
                  IconButton(
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SettingsScreen(repository: widget.repository),
                        ),
                      );
                      await _load();
                    },
                    icon: const Icon(Icons.settings_rounded),
                    tooltip: '设置',
                  ),
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
              : data == null
                  ? const Center(child: Text('暂无数据'))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _SummaryCard(data: data),
                          const SizedBox(height: 18),
                          const Text(
                            '一级属性',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ...data.primaryAttributes.map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: PrimaryCard(
                                attribute: item,
                                onTap: () => _openPrimaryDetail(item.type),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  '最近记录',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              Text(
                                '${data.recentRecords.length} 条',
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (data.recentRecords.isEmpty)
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  '还没有记录。下一阶段接入二级属性详情页后，你就可以在这里看到加点/扣点历史。',
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                ),
                              ),
                            )
                          else
                            ...data.recentRecords.map(
                              (record) => RecordTile(record: record),
                            ),
                          const SizedBox(height: 20),
                          Text(
                            '当前阶段说明：本页已接通仓库层；新增二级属性、编辑、记分、归档恢复将在下一阶段接入。',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final changeValue = data.yesterdayChangeValue;
    final changePercentage = data.yesterdayChangePercentage;
    final changeColor = changeValue == null
        ? Theme.of(context).colorScheme.onSurfaceVariant
        : changeValue > 0
            ? Colors.green
            : changeValue < 0
                ? Colors.red
                : Theme.of(context).colorScheme.onSurfaceVariant;

    return Card(
      elevation: 1.5,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '当前总点数',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppFormatters.score(data.totalScore),
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: changeColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    changeValue == null
                        ? Icons.remove
                        : changeValue > 0
                            ? Icons.trending_up_rounded
                            : changeValue < 0
                                ? Icons.trending_down_rounded
                                : Icons.trending_flat_rounded,
                    color: changeColor,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      changeValue == null
                          ? '较昨日：暂无对比'
                          : '较昨日：${AppFormatters.delta(changeValue)}'
                            '${changePercentage == null ? '' : ' (${AppFormatters.percentage(changePercentage)})'}',
                      style: TextStyle(
                        color: changeColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}