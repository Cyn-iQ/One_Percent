import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../services/app_repository.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.repository,
  });

  final AppRepository repository;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _busy = false;
  String _status = '尚未执行操作';

  Future<void> _exportData() async {
    if (_busy) return;

    setState(() {
      _busy = true;
      _status = '正在导出数据...';
    });

    try {
      final json = await widget.repository.exportAllToJsonString();
      final fileName = await widget.repository.buildExportFileName();

      // 改为临时目录，避免部分安卓设备/版本上 path_provider 文档目录异常
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');

      await file.writeAsString(json);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: '成长系统数据备份',
        subject: fileName,
      );

      if (!mounted) return;
      setState(() {
        _status = '导出完成：${file.path}';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = '导出失败：$e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导出失败：$e')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _busy = false;
      });
    }
  }

  Future<void> _importData() async {
    if (_busy) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('覆盖导入'),
        content: const Text(
          '导入会覆盖当前本地全部数据，且无法撤销。确认继续吗？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确认导入'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _busy = true;
      _status = '正在选择并导入文件...';
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: false,
      );

      if (result == null || result.files.isEmpty) {
        if (!mounted) return;
        setState(() {
          _status = '已取消导入';
        });
        return;
      }

      final path = result.files.single.path;
      if (path == null) {
        throw Exception('无法读取所选文件路径');
      }

      final file = File(path);
      final jsonString = await file.readAsString();
      await widget.repository.replaceAllDataFromJsonString(jsonString);

      if (!mounted) return;
      setState(() {
        _status = '导入成功：$path';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('导入成功，当前数据已覆盖')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = '导入失败：$e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导入失败：$e')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _busy = false;
      });
    }
  }

  Future<void> _clearAllData() async {
    if (_busy) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空全部数据'),
        content: const Text(
          '这会删除所有二级属性、记录和每日快照，且无法恢复。确认继续吗？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确认清空'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _busy = true;
      _status = '正在清空数据...';
    });

    try {
      await widget.repository.clearAllData();

      if (!mounted) return;
      setState(() {
        _status = '已清空全部数据';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('全部数据已清空')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = '清空失败：$e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('清空失败：$e')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.upload_file_rounded),
                  title: const Text('导出备份'),
                  subtitle: const Text('导出当前全部本地数据为 JSON 文件'),
                  trailing: _busy
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                  onTap: _busy ? null : _exportData,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.download_rounded),
                  title: const Text('导入备份'),
                  subtitle: const Text('从 JSON 文件覆盖导入全部数据'),
                  trailing: _busy
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                  onTap: _busy ? null : _importData,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_forever_rounded),
                  title: const Text('清空全部数据'),
                  subtitle: const Text('删除全部二级属性、记录和每日快照'),
                  trailing: _busy
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                  onTap: _busy ? null : _clearAllData,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _status,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: DefaultTextStyle(
                style: TextStyle(
                  color: onSurfaceVariant,
                  height: 1.5,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '说明',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text('1. 导出内容包含二级属性、历史记录、每日快照和版本信息。'),
                    const Text('2. 当前导入方式为覆盖导入，不做合并。'),
                    const Text('3. 归档不是删除，归档数据会被正常导出。'),
                    const Text('4. 导出文件会先写入临时目录，再调用系统分享。'),
                    const Text('5. 若系统清理缓存，临时目录中的备份文件可能被删除，因此导出后建议立即保存到其他位置。'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}