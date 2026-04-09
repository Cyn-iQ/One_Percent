import 'package:flutter/material.dart';

import '../models/primary_attribute.dart';
import '../models/secondary_attribute.dart';
import '../services/app_repository.dart';

class SecondaryEditScreen extends StatefulWidget {
  const SecondaryEditScreen({
    super.key,
    required this.repository,
    required this.primaryType,
    this.secondaryAttribute,
  });

  final AppRepository repository;
  final PrimaryAttributeType primaryType;
  final SecondaryAttribute? secondaryAttribute;

  bool get isEditMode => secondaryAttribute != null;

  @override
  State<SecondaryEditScreen> createState() => _SecondaryEditScreenState();
}

class _SecondaryEditScreenState extends State<SecondaryEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.secondaryAttribute?.name ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.secondaryAttribute?.description ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid || _saving) return;

    setState(() {
      _saving = true;
    });

    try {
      if (widget.isEditMode) {
        await widget.repository.updateSecondaryAttribute(
          id: widget.secondaryAttribute!.id!,
          primaryType: widget.primaryType,
          name: _nameController.text,
          description: _descriptionController.text,
        );
      } else {
        await widget.repository.createSecondaryAttribute(
          primaryType: widget.primaryType,
          name: _nameController.text,
          description: _descriptionController.text,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
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

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.isEditMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? '编辑二级属性' : '新增二级属性'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                '所属一级属性：${widget.primaryType.label}',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '二级属性名称',
                  border: OutlineInputBorder(),
                  hintText: '例如：Flutter / 论文阅读 / 跑步',
                ),
                textInputAction: TextInputAction.next,
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) {
                    return '请输入二级属性名称';
                  }
                  if (text.length > 30) {
                    return '名称不建议超过 30 个字符';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: '说明（可选）',
                  border: OutlineInputBorder(),
                  hintText: '用于解释这个二级属性记录的是什么',
                ),
                maxLines: 4,
                minLines: 3,
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.length > 200) {
                    return '说明不建议超过 200 个字符';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _submit,
                child: Text(_saving ? '保存中...' : '保存'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}