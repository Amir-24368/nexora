import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'models/category.dart';
import 'ui/theme.dart';
import 'ui/widgets.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  List<Category> categories = [];
  bool isLoading = true;
  String error = '';

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _editingId;
  String? _selectedParentId;
  final Set<String> _expanded = <String>{};

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final data = await ApiService.getCategoriesTree();
      if (!mounted) return;
      setState(() {
        categories = data;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  void _showDialog({Category? category}) {
    _editingId = category?.id;
    _nameController.text = category?.name ?? '';
    _descriptionController.text = category?.description ?? '';
    _selectedParentId = category?.parentId;
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final flat = _flattenCategories(categories);
          return nxDialog(
            context: dialogContext,
            title: _editingId == null ? 'Add category' : 'Edit category',
            content: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  NxTextField(
                    controller: _nameController,
                    label: 'Category name',
                    validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  NxTextField(controller: _descriptionController, label: 'Description (optional)', maxLines: 2),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedParentId,
                    isExpanded: true,
                    hint: const Text('No parent (root)'),
                    items: [
                      const DropdownMenuItem<String>(value: null, child: Text('None (root)')),
                      ...flat.map((cat) {
                        if (_editingId != null && cat.id == _editingId) return null;
                        return DropdownMenuItem(value: cat.id, child: Text(cat.name, overflow: TextOverflow.ellipsis));
                      }).whereType<DropdownMenuItem<String>>(),
                    ],
                    onChanged: (val) => setDialogState(() => _selectedParentId = val),
                    decoration: _ddDecoration('Parent category'),
                  ),
                ],
              ),
            ),
            actions: [
              NxButton(label: 'Cancel', variant: NxButtonVariant.ghost, onPressed: () => Navigator.pop(dialogContext)),
              NxButton(label: _editingId == null ? 'Add' : 'Update', onPressed: _saveCategory),
            ],
          );
        },
      ),
    );
  }

  InputDecoration _ddDecoration(String label) {
    final palette = nxOf(context);
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: palette.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: palette.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: palette.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: palette.primary, width: 1.4)),
      labelStyle: TextStyle(color: palette.textMuted, fontSize: 14),
    );
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      final data = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'parent': _selectedParentId,
      };
      if (_editingId == null) {
        await ApiService.createCategory(data);
      } else {
        await ApiService.updateCategory(_editingId!, data);
      }
      if (!mounted) return;
      Navigator.pop(context);
      _loadCategories();
      nxSnack(context, 'Category saved');
    } catch (e) {
      String errorMsg = 'Failed to save category';
      final errorString = e.toString();
      if (errorString.contains('IntegrityError') ||
          errorString.contains('unique') ||
          errorString.contains('already exists') ||
          errorString.contains('duplicate') ||
          errorString.contains('A category with this name already exists')) {
        errorMsg = 'A category with this name already exists.';
      } else if (errorString.contains('shop')) {
        errorMsg = 'You must have a shop assigned to create categories.';
      }
      if (!mounted) return;
      nxSnack(context, errorMsg, isError: true);
    }
  }

  /// Flattens the category tree for the parent picker. The API returns a
  /// flat list where children ALSO appear nested in their parent, so the
  /// same category can be reached twice -- dedupe by id or DropdownButton
  /// crashes with "multiple items with the same value".
  List<Category> _flattenCategories(List<Category> cats) {
    final result = <Category>[];
    final ids = <String>{};
    void traverse(List<Category> nodes) {
      for (var cat in nodes) {
        if (ids.add(cat.id)) {
          result.add(cat);
        }
        if (cat.children.isNotEmpty) {
          traverse(cat.children);
        }
      }
    }
    traverse(cats);
    return result;
  }

  int _countAll(List<Category> nodes) {
    var total = 0;
    for (final n in nodes) {
      total += 1 + _countAll(n.children);
    }
    return total;
  }

  Widget _buildCategoryTree(List<Category> nodes, int depth) {
    final palette = nxOf(context);
    return Column(
      children: nodes.map((cat) {
        final hasChildren = cat.children.isNotEmpty;
        final isExpanded = _expanded.contains(cat.id);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(left: depth * 24.0),
              child: NxCard(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  children: [
                    if (hasChildren)
                      NxIconButton(
                        icon: isExpanded ? Icons.expand_more_rounded : Icons.chevron_right_rounded,
                        tooltip: isExpanded ? 'Collapse' : 'Expand',
                        onTap: () => setState(() => isExpanded ? _expanded.remove(cat.id) : _expanded.add(cat.id)),
                      )
                    else
                      NxIconBlock(icon: Icons.label_outline_rounded, color: palette.warning, size: 40),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(cat.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: palette.textPrimary)),
                          if (cat.description != null && cat.description!.isNotEmpty)
                            Text(cat.description!, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: palette.textMuted)),
                          if (hasChildren)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text('${_countAll([cat]) - 1} subcategor${_countAll([cat]) - 1 == 1 ? 'y' : 'ies'}', style: TextStyle(fontSize: 11.5, color: palette.textMuted)),
                            ),
                        ],
                      ),
                    ),
                    NxIconButton(icon: Icons.edit_outlined, tooltip: 'Edit', onTap: () => _showDialog(category: cat)),
                    NxIconButton(icon: Icons.delete_outline_rounded, tooltip: 'Delete', color: palette.danger, onTap: () => _deleteCategory(cat)),
                  ],
                ),
              ),
            ),
            if (hasChildren && isExpanded) _buildCategoryTree(cat.children, depth + 1),
          ],
        );
      }).toList(),
    );
  }

  Future<void> _deleteCategory(Category cat) async {
    final confirmed = await nxConfirm(
      context,
      title: 'Delete category',
      message: 'Delete "${cat.name}"? Subcategories will be deleted too.',
      confirmLabel: 'Delete',
      variant: NxButtonVariant.danger,
    );
    if (!confirmed) return;
    try {
      await ApiService.deleteCategory(cat.id);
      _loadCategories();
      if (!mounted) return;
      nxSnack(context, 'Category deleted');
    } catch (e) {
      if (!mounted) return;
      nxSnack(context, 'Delete failed: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = nxOf(context);

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: const NxBackButton(),
        title: const Text('Categories'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showDialog(),
        backgroundColor: palette.primary,
        foregroundColor: palette.textOnAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New category'),
      ),
      body: isLoading
          ? const NxLoader()
          : error.isNotEmpty
              ? NxErrorView(message: error, onRetry: _loadCategories)
              : categories.isEmpty
                  ? NxEmptyState(
                      icon: Icons.label_outline_rounded,
                      title: 'No categories yet',
                      message: 'Organize your goods into categories to make browsing easier.',
                      actionLabel: 'New category',
                      onAction: () => _showDialog(),
                    )
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 88),
                      child: _buildCategoryTree(categories, 0),
                    ),
    );
  }
}
