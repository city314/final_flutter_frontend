import 'package:flutter/material.dart';
import '../../models/category.dart';
import 'component/SectionHeader.dart';
import 'package:cpmad_final/service/ProductService.dart';

class AdminCategoryScreen extends StatefulWidget {
  const AdminCategoryScreen({Key? key}) : super(key: key);

  @override
  _AdminCategoryScreenState createState() => _AdminCategoryScreenState();
}

class _AdminCategoryScreenState extends State<AdminCategoryScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<Category> _categories = [];
  List<Category> _filteredCategories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _searchCtrl.addListener(_applySearch);
  }

  Future<void> _loadCategories() async {
    setState(() => _loading = true);
    try {
      final list = await ProductService.fetchAllCategory();
      setState(() {
        _categories = list;
        _loading = false;
        _filteredCategories = List.from(list);
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi tải danh mục: $e')));
    }
  }


  void _applySearch() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filteredCategories = _categories
          .where((c) => c.name.toLowerCase().contains(q))
          .toList();
    });
  }


  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showEditDialog({Category? category}) {
    final isNew = category == null;
    final _nameCtrl = TextEditingController(text: category?.name ?? '');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(isNew ? 'Tạo danh mục mới' : 'Chỉnh sửa danh mục'),
          content: TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Tên danh mục'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Huỷ')),
            ElevatedButton(
              onPressed: () async {
                final name = _nameCtrl.text.trim();
                if (name.isEmpty) {
                  if (mounted) {
                    Future.microtask(() {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Tên danh mục không được để trống')),
                      );
                    });
                  }
                  return;
                }

                try {
                  if (isNew) {
                    final created = await ProductService.createCategory(name);
                    if (mounted) setState(() => _categories.add(created));
                  } else {
                    final updated = await ProductService.updateCategory(category.id!, name);
                    _loadCategories();
                    if (mounted) {
                      final idx = _categories.indexWhere((c) => c.id == category.id);
                      if (idx != -1) _categories[idx] = updated;
                    }
                  }
                  if (mounted && Navigator.of(ctx).canPop()) Navigator.of(ctx).pop();
                } catch (e) {
                  if (mounted) {
                    Future.microtask(() {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                    });
                  }
                }
              },
              child: Text(isNew ? 'Tạo' : 'Lưu'),
            ),
          ],
        );
      },
    );
  }

  void _deleteCategory(Category c) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xác nhận xoá'),
        content: Text('Bạn có chắc muốn xoá danh mục "${c.name}" không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Huỷ'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              try {
                await ProductService.deleteCategory(c.id!);
                if (!mounted) return;
                setState(() => _categories.removeWhere((x) => x.id == c.id));
              } catch (e) {
                if (!mounted) return;
                Future.microtask(() {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: $e')),
                  );
                });
              }
            },
            child: const Text('Xoá'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditDialog(),
        child: const Icon(Icons.add),
        tooltip: 'Tạo danh mục mới',
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SectionHeader mới
            const SectionHeader('Quản lý Danh mục'),
            const SizedBox(height: 16),
            // —— Thanh Search ——
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm danh mục...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // ListView bọc trong Expanded để tránh overflow
            Expanded(
              child: ListView.separated(
                itemCount: _filteredCategories.length,
                separatorBuilder: (_, __) => const Divider(height: 32),
                itemBuilder: (context, i) {
                  final cat = _filteredCategories[i];
                  return ListTile(
                    title: Text(cat.name,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          tooltip: 'Chỉnh sửa',
                          onPressed: () => _showEditDialog(category: cat),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          tooltip: 'Xoá',
                          onPressed: () => _deleteCategory(cat),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
