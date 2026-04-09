import 'package:flutter/material.dart';

import '../models/primary_attribute.dart';
import '../models/secondary_attribute.dart';
import '../models/score_record.dart';
import '../services/app_repository.dart';
import '../utils/formatters.dart';
import '../widgets/record_tile.dart';
import 'secondary_edit_screen.dart';

class SecondaryDetailScreen extends StatefulWidget {
  const SecondaryDetailScreen({
    super.key,
    required this.repository,
    required this.secondaryAttributeId,
  });

  final AppRepository repository;
  final int secondaryAttributeId;

  @override
  State<SecondaryDetailScreen> createState() => _SecondaryDetailScreenState();
}

class _SecondaryDetailScreenState extends State<SecondaryDetailScreen> {
  final TextEditingController _noteController = TextEditingController();

  SecondaryAttribute? _attribute;
  List<ScoreRecord> _records = [];
  double _currentScore = 0.0;

  bool _loading = true;
  bool _saving = false;
  String? _error;

  double? _selectedDelta;

  static const List<double> presetValues = [0.1, 0.3, 0.5, -0.1, -0.3, -0.5];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final attribute = await widget.repository.getSecondaryAttributeById(
        widget.secondaryAttributeId,
      );

      if (attribute == null) {
        throw Exception('未找到该二级属性');
      }

      final records = await widget.repository.getRecordsBySecondaryAttribute(
        widget.secondaryAttributeId,
      );

      final currentScore = await widget.repository.getSecondaryCurrentScore(
        widget.secondaryAttributeId,
      );

      if (!mounted) return;
      setState(() {
        _attribute = attribute;
        _records = records;
        _currentScore = currentScore;
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

  Future<void> _pickCustomDelta() async {
    final controller = TextEditingController(
      text: _selectedDelta?.toString() ?? '',
    );

    final result = await showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('自定义分值'),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            decoration: const InputDecoration(
              hintText: '输入如 0.2 / -0.4',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                final text = controller.text.trim();
                final value = double.tryParse(text);
                if (value == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('请输入有效数字')),
                  );
                  return;
                }
                Navigator.of(context).pop(value);
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );

    if (result == null) return;

    setState(() {
      _selectedDelta = result;
    });
  }

  Future<void> _saveRecord() async {
    if (_saving) return;

    final attribute = _attribute;
    if (attribute == null) return;

    final delta = _selectedDelta;
    if (delta == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先选择或输入本次加减点数')),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await widget.repository.addScoreRecord(
        secondaryAttributeId: attribute.id!,
        delta: delta,
        note: _noteController.text,
      );

      _noteController.clear();

      if (!mounted) return;
      setState(() {
        _selectedDelta = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('记录已保存')),
      );

      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失败：$e')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _saving = false;
      });
    }
  }

  Future<void> _editAttribute() async {
    final attribute = _attribute;
    if (attribute == null) return;

    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => SecondaryEditScreen(
          repository: widget.repository,
          primaryType: attribute.primaryType,
          secondaryAttribute: attribute,
        ),
      ),
    );

    if (changed == true) {
      await _load();
    }
  }

  Future<void> _archiveAttribute() async {
    final attribute = _attribute;
    if (attribute == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('归档二级属性'),
        content: Text('确认将“${attribute.name}”归档吗？归档后历史记录会保留。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确认归档'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await widget.repository.archiveSecondaryAttributeAndRefresh(attribute.id!);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已归档：${attribute.name}')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('归档失败：$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final attribute = _attribute;

    return Scaffold(
      appBar: AppBar(
        title: Text(attribute?.name ?? '二级属性详情'),
        actions: [
          if (!_loading && attribute != null) ...[
            IconButton(
              onPressed: _editAttribute,
              icon: const Icon(Icons.edit_rounded),
            ),
            IconButton(
              onPressed: _archiveAttribute,
              icon: const Icon(Icons.archive_outlined),
            ),
          ],
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
              : attribute == null
                  ? const Center(child: Text('未找到数据'))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _InfoCard(
                          attribute: attribute,
                          currentScore: _currentScore,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _noteController,
                          maxLines: 4,
                          minLines: 3,
                          decoration: const InputDecoration(
                            labelText: '备注（可选）',
                            hintText: '例如：完成 Flutter 页面开发 / 今天熬夜 / 读完一篇论文',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '快捷加减点',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            for (final value in presetValues)
                              ChoiceChip(
                                label: Text(AppFormatters.delta(value)),
                                selected: _selectedDelta == value,
                                onSelected: (_) {
                                  setState(() {
                                    _selectedDelta = value;
                                  });
                                },
                              ),
                            ActionChip(
                              label: Text(
                                _selectedDelta != null &&
                                        !presetValues.contains(_selectedDelta)
                                    ? '自定义：${AppFormatters.delta(_selectedDelta!)}'
                                    : '自定义',
                              ),
                              onPressed: _pickCustomDelta,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Text(
                                '当前选择：',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              Expanded(
                                child: Text(
                                  _selectedDelta == null
                                      ? '未选择'
                                      : AppFormatters.delta(_selectedDelta!),
                                  textAlign: TextAlign.end,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: _selectedDelta == null
                                        ? Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant
                                        : _selectedDelta! > 0
                                            ? Colors.green
                                            : _selectedDelta! < 0
                                                ? Colors.red
                                                : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _saving ? null : _saveRecord,
                          child: Text(_saving ? '保存中...' : '保存记录'),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                '历史记录',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Text(
                              '${_records.length} 条',
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (_records.isEmpty)
                          const Card(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Text('还没有记录。'),
                            ),
                          )
                        else
                          ..._records.map((record) => RecordTile(record: record)),
                      ],
                    ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.attribute,
    required this.currentScore,
  });

  final SecondaryAttribute attribute;
  final double currentScore;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.1,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              attribute.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '所属一级属性：${attribute.primaryType.label}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if ((attribute.description ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(attribute.description!.trim()),
            ],
            const SizedBox(height: 16),
            Text(
              AppFormatters.score(currentScore),
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
