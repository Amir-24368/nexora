import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'models/category.dart';

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

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final data = await ApiService.getCategoriesTree();
      setState(() {
        categories = data;
        isLoading = false;
      });
    } catch (e) {
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
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          final allCategories = _flattenCategories(categories);
          return AlertDialog(
            title: Text(_editingId == null ? 'Add Category' : 'Edit Category'),
            content: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Category Name'),
                    validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: 'Description (optional)'),
                    maxLines: 2,
                  ),
                  DropdownButtonFormField<String>(
                    value: _selectedParentId,
                    hint: const Text('No parent (root)'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('None (Root)')),
                      ...allCategories.map((cat) {
                        if (_editingId != null && cat.id == _editingId) return null;
                        return DropdownMenuItem(
                          value: cat.id,
                          child: Text(cat.name),
                        );
                      }).whereType<DropdownMenuItem<String>>(),
                    ],
                    onChanged: (val) => setDialogState(() => _selectedParentId = val),
                    decoration: const InputDecoration(labelText: 'Parent Category'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: _saveCategory,
                child: Text(_editingId == null ? 'Add' : 'Update'),
              ),
            ],
          );
        },
      ),
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
      Navigator.pop(context);
      _loadCategories();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category saved'), backgroundColor: Colors.green),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
      );
    }
  }

  List<Category> _flattenCategories(List<Category> cats) {
    List<Category> result = [];
    for (var cat in cats) {
      result.add(cat);
      result.addAll(_flattenCategories(cat.children));
    }
    return result;
  }

  Widget _buildCategoryTree(List<Category> nodes, int depth) {
    return Column(
      children: nodes.map((cat) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(left: depth * 20.0),
              child: Card(
                margin: const EdgeInsets.symmetric(vertical: 2),
                child: ListTile(
                  title: Text(cat.name),
                  subtitle: cat.description != null && cat.description!.isNotEmpty
                      ? Text(cat.description!)
                      : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showDialog(category: cat),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteCategory(cat.id),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (cat.children.isNotEmpty)
              _buildCategoryTree(cat.children, depth + 1),
          ],
        );
      }).toList(),
    );
  }

  Future<void> _deleteCategory(String id) async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Category'),
        content: const Text('Are you sure? (Subcategories will be deleted too)'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              try {
                await ApiService.deleteCategory(id);
                Navigator.pop(context);
                _loadCategories();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Category Management'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showDialog(),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error.isNotEmpty
              ? Center(child: Text('Error: $error'))
              : categories.isEmpty
                  ? const Center(child: Text('No categories yet. Tap + to add.'))
                  : SingleChildScrollView(
                      child: _buildCategoryTree(categories, 0),
                    ),
    );
  }
}