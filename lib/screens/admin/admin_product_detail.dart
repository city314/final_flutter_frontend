import 'dart:convert';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cpmad_final/models/product.dart';
import 'package:cpmad_final/models/category.dart';
import 'package:cpmad_final/models/brand.dart';
import 'package:cpmad_final/models/variant.dart';
import 'package:go_router/go_router.dart';
import '../../service/ProductService.dart';
import '../../utils/format_utils.dart';

// TODO: replace with dynamic data sources

class AdminProductDetail extends StatefulWidget {
  final Product product;
  final ValueChanged<Product> onEdit;
  final VoidCallback onDelete;
  final bool isNew;
  const AdminProductDetail({
    Key? key,
    required this.product,
    required this.onEdit,
    required this.onDelete,
    this.isNew = false,
  }) : super(key: key);

  @override
  _AdminProductDetailState createState() => _AdminProductDetailState();
}

class _AdminProductDetailState extends State<AdminProductDetail> {
  final _formKey = GlobalKey<FormState>();
  final List<Category> categories = [];
  final List<Brand> brands = [];
  List<Variant> _variants = [];
  int get _totalStock => _variants.fold(0, (sum, v) => sum + (v.stock ?? 0));
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;

  late Category _selectedCategory;
  late Brand _selectedBrand;
  List<PlatformFile> _images = [];
  List<PlatformFile> _editingVariantImages = [];
  int? _editingIndex;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    try {
      final cats = await ProductService.fetchAllCategory();
      final brs = await ProductService.fetchAllBrand();
      final p = widget.product;

      final fetchedVariants = p.id != null
          ? await ProductService.fetchVariantsByProduct(p.id!)
          : <Variant>[];

      setState(() {
        categories
          ..clear()
          ..addAll(cats);
        brands
          ..clear()
          ..addAll(brs);

        _nameCtrl = TextEditingController(text: p.name);
        _descCtrl = TextEditingController(text: p.description);

        _variants = fetchedVariants; // ✅ chỉ dùng kết quả fetch

        _selectedCategory = categories.firstWhere(
              (c) => c.id == p.categoryId,
          orElse: () => categories.first,
        );
        _selectedBrand = brands.firstWhere(
              (b) => b.id == p.brandId,
          orElse: () => brands.first,
        );

        if (p.images.isNotEmpty) {
          _images = p.images.map((img) => PlatformFile(
            name: img['name'] ?? 'image.png',
            bytes: base64Decode(img['base64'] ?? ''),
            size: 0,
          )).toList();
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi tải dữ liệu: $e')));
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  List<String> _getImageUrls() {
    return _images.map((f) => f.path ?? '').where((path) => path.isNotEmpty).toList();
  }

  Future<void> _pickImages() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: kIsWeb,
    );
    if (result != null) {
      setState(() {
        _images.addAll(result.files);
      });
    }
  }

  void _navigateToEditVariantPage(int index) async {
    final old = _variants[index];
    final result = await context.push<Variant>('/admin/variant-detail', extra: {
      'productId': widget.product.id ?? '',
      'initialVariant': old,
    });
    if (result != null) {
      setState(() {
        _variants[index] = result;  // cập nhật lại list
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  void _showVariantDetails(Variant variant) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: SizedBox(
            width: 600, // hoặc double.infinity
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Chi tiết biến thể', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Text('Tên: ${variant.variantName}'),
                    const SizedBox(height: 8),
                    Text('Màu: ${variant.color}'),
                    const SizedBox(height: 8),
                    Text('Thuộc tính: ${variant.attributes}'),
                    const SizedBox(height: 8),
                    Text('Giá nhập: ${formatPrice(variant.importPrice)}'),
                    const SizedBox(height: 8),
                    Text('Giá bán: ${formatPrice(variant.sellingPrice)}'),
                    const SizedBox(height: 8),
                    Text('Tồn kho: ${variant.stock}'),
                    const SizedBox(height: 16),
                    const Text('Ảnh sản phẩm', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 1,
                      ),
                      itemCount: _images.length + 1,
                      itemBuilder: (context, index) {
                        if (index < _images.length) {
                          // hiện thumbnail ảnh đã chọn
                          return _buildImageTile(index);
                        }
                        // nút thêm ảnh
                        return GestureDetector(
                          onTap: _pickImages,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey),
                            ),
                            child: const Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => context.pop(),
                        child: const Text('Đóng'),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageTile(int index) {
    final file = _images[index];
    Widget img;
    if (!kIsWeb && file.path != null) {
      img = Image.file(File(file.path!), fit: BoxFit.cover);
    } else if (file.bytes != null) {
      img = Image.memory(file.bytes!, fit: BoxFit.cover);
    } else {
      img = const Icon(Icons.broken_image, size: 40, color: Colors.grey);
    }
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            color: Colors.grey[200],
            child: AspectRatio(aspectRatio: 1, child: img),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removeImage(index),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(4),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Future<List<Map<String, String>>> _convertImagesToBase64(List<PlatformFile> images) async {
    List<Map<String, String>> encoded = [];
    for (var file in images) {
      Uint8List? bytes;
      if (file.bytes != null) {
        bytes = file.bytes!;
      } else if (file.path != null) {
        bytes = await File(file.path!).readAsBytes();
      }

      if (bytes != null) {
        String base64Image = base64Encode(bytes);
        encoded.add({'name': file.name, 'base64': base64Image});
      }
    }
    return encoded;
  }


  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final imageBase64List = await _convertImagesToBase64(_images);

    final updated = Product(
      id: widget.product.id,
      name: _nameCtrl.text.trim(),
      categoryId: _selectedCategory.id!,
      brandId: _selectedBrand.id!,
      stock: _totalStock,
      description: _descCtrl.text.trim(),
      images: imageBase64List,
      timeAdd: widget.product.timeAdd,
    );

    try {
      if (widget.isNew) {
        final createdProduct = await ProductService.createProduct(updated);

        // Thêm toàn bộ biến thể
        for (final v in _variants) {
          final updatedVariant = v.copyWith(productId: createdProduct.id!);
          await ProductService.createVariant(updatedVariant);
        }

        widget.onEdit(createdProduct);
        if (mounted) context.pop(createdProduct);
      } else {
        final updatedProduct = await ProductService.updateProduct(widget.product.id!, updated);

        final oldVariants = await ProductService.fetchVariantsByProduct(widget.product.id!);
        final oldIds = oldVariants.map((v) => v.id).toSet();

        final newIds = _variants.where((v) => v.id != null).map((v) => v.id!).toSet();
        final toDelete = oldIds.difference(newIds);

        // Xoá biến thể đã bị loại bỏ
        for (final id in toDelete) {
          await ProductService.deleteVariant(id!);
        }

        // Thêm hoặc cập nhật các biến thể mới
        for (final v in _variants) {
          if (v.id == null) {
            await ProductService.createVariant(v.copyWith(productId: widget.product.id!));
          } else {
            await ProductService.updateVariant(v.id!, v);
          }
        }

        widget.onEdit(updatedProduct);
        if (mounted) context.pop(updatedProduct);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi lưu sản phẩm: $e')));
    }
  }

  void _navigateToAddVariantPage() async {
    final result = await context.push<Variant>(
      '/admin/variant-detail',
      extra: {
        'productId': widget.product.id ?? '',
        'initialVariant': null,
      },
    );

    if (result != null) {
      setState(() => _variants.add(result));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty || brands.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final titleText = widget.isNew || widget.product.id == null
        ? 'Thêm sản phẩm'
        : 'Chỉnh sửa sản phẩm';
    return Scaffold(
      appBar: AppBar(
        title: Text((widget.product.id?.isEmpty ?? true) ? 'Thêm sản phẩm' : 'Chỉnh sửa sản phẩm'),
        actions: [
          if (!widget.isNew) // chỉ hiện nút Delete khi không phải add mới
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: widget.onDelete,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ListView(
                  children: [
                    // Basic Info
                    const Text('Thông tin cơ bản', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Tên sản phẩm',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? 'Tên không được để trống' : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<Category>(
                            value: _selectedCategory,
                            decoration: const InputDecoration(
                              labelText: 'Danh mục',
                              border: OutlineInputBorder(),
                            ),
                            items: categories
                                .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                                .toList(),
                            onChanged: (c) => setState(() => _selectedCategory = c!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<Brand>(
                            value: _selectedBrand,
                            decoration: const InputDecoration(
                              labelText: 'Thương hiệu',
                              border: OutlineInputBorder(),
                            ),
                            items: brands
                                .map((b) => DropdownMenuItem(value: b, child: Text(b.name)))
                                .toList(),
                            onChanged: (b) => setState(() => _selectedBrand = b!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Image Picker
                    const Text('Ảnh sản phẩm', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _images.length + 1,     // +1 để hiển thị nút "thêm ảnh"
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 1,
                      ),
                      itemBuilder: (context, index) {
                        if (index < _images.length) {
                          return _buildImageTile(index);
                        }
                        // nút thêm ảnh
                        return GestureDetector(
                          onTap: _pickImages,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey),
                            ),
                            child: const Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    // Description
                    const Text('Mô tả chi tiết', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descCtrl,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Nhập mô tả...',
                      ),
                      maxLines: 5,
                    ),
                    const SizedBox(height: 40),
                    const Text('Variants', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ListView.builder(
                      itemCount: _variants.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        final v = _variants[index];

                        if (_editingIndex == index) {
                          final nameCtrl = TextEditingController(text: v.variantName);
                          final colorCtrl = TextEditingController(text: v.color);
                          final attrCtrl = TextEditingController(text: v.attributes);
                          final stockCtrl = TextEditingController(text: v.stock.toString());

                          _editingVariantImages = v.images.map((img) {
                            return PlatformFile(
                              name: img['name'] ?? 'image.png',
                              bytes: base64Decode(img['base64'] ?? ''),
                              size: 0,
                            );
                          }).toList();

                          return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              color: Colors.grey[100],
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  children: [
                                    Row(children: [
                                      Expanded(
                                        child: TextField(
                                          controller: nameCtrl,
                                          decoration: const InputDecoration(labelText: 'Tên biến thể'),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextField(
                                          controller: colorCtrl,
                                          decoration: const InputDecoration(labelText: 'Màu sắc'),
                                        ),
                                      ),
                                    ]),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: attrCtrl,
                                      decoration: const InputDecoration(labelText: 'Thuộc tính'),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(children: [
                                      Expanded(
                                        child: TextField(
                                          controller: stockCtrl,
                                          decoration: const InputDecoration(labelText: 'Tồn kho'),
                                          keyboardType: TextInputType.number,
                                        ),
                                      ),
                                    ]),
                                    const SizedBox(height: 8),
                                    const Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text('Ảnh biến thể', style: TextStyle(fontWeight: FontWeight.bold))),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      height: 120,  // hoặc tuỳ nhu cầu
                                      child: GridView.builder(
                                        itemCount: _editingVariantImages.length + 1,
                                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 5,
                                          crossAxisSpacing: 8,
                                          mainAxisSpacing: 8,
                                          childAspectRatio: 1,
                                        ),
                                        physics: const BouncingScrollPhysics(),
                                        itemBuilder: (context, i) {
                                          if (i < _editingVariantImages.length) {
                                            final file = _editingVariantImages[i];
                                            Widget img;
                                            if (!kIsWeb && file.path != null) {
                                              img = Image.file(File(file.path!), fit: BoxFit.cover);
                                            } else if (file.bytes != null) {
                                              img = Image.memory(file.bytes!, fit: BoxFit.cover);
                                            } else {
                                              img = const Icon(Icons.broken_image, size: 40);
                                            }

                                            return Stack(
                                              children: [
                                                ClipRRect(
                                                  borderRadius: BorderRadius.circular(8),
                                                  child: Container(
                                                    color: Colors.grey[200],
                                                    child: AspectRatio(aspectRatio: 1, child: img),
                                                  ),
                                                ),
                                                Positioned(
                                                  top: 4,
                                                  right: 4,
                                                  child: GestureDetector(
                                                    onTap: () {
                                                      WidgetsBinding.instance.addPostFrameCallback((_) {
                                                        setState(() => _editingVariantImages.removeAt(i));
                                                      });
                                                    },
                                                    child: Container(
                                                      decoration: const BoxDecoration(
                                                        color: Colors.black54,
                                                        shape: BoxShape.circle,
                                                      ),
                                                      padding: const EdgeInsets.all(4),
                                                      child: const Icon(Icons.close, size: 16, color: Colors.white),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          }

                                          // Add button
                                          return GestureDetector(
                                            onTap: () async {
                                              final result = await FilePicker.platform.pickFiles(
                                                type: FileType.image,
                                                allowMultiple: true,
                                                withData: kIsWeb,
                                              );
                                              if (result != null && result.files.isNotEmpty) {
                                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                                  setState(() => _editingVariantImages.addAll(result.files));
                                                });
                                              }
                                            },
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.grey[200],
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: Colors.grey),
                                              ),
                                              child: const Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
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

                        // Hiển thị tile mặc định khi không chỉnh
                        return Card(
                          child: ListTile(
                            title: Text(v.variantName.isNotEmpty ? v.variantName : '(Chưa đặt tên)'),
                            subtitle: Text('Giá: ${formatPrice(v.sellingPrice)}  •  Kho: ${v.stock}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.info_outline, color: Colors.grey),
                                  tooltip: 'Xem chi tiết',
                                  onPressed: () => _showVariantDetails(v),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  tooltip: 'Chỉnh sửa',
                                  onPressed: () => _navigateToEditVariantPage(index),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  tooltip: 'Xoá',
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: const Text('Xác nhận xoá'),
                                        content: Text('Xoá biến thể "${v.variantName}"?'),
                                        actions: [
                                          TextButton(onPressed: () => context.pop(false), child: const Text('Huỷ')),
                                          ElevatedButton(onPressed: () => context.pop(true), child: const Text('Xoá')),
                                        ],
                                      ),
                                    );

                                    if (confirm == true && v.id != null) {
                                      try {
                                        await ProductService.deleteVariant(v.id!);
                                        setState(() => _variants.removeAt(index));
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xoá biến thể')));
                                      } catch (e) {
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi xoá: $e')));
                                      }
                                    }
                                  },
                                ),

                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Thêm variant'),
                        onPressed: _navigateToAddVariantPage,
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save),
                  label: const Text('Lưu sản phẩm'),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
