import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cpmad_final/models/variant.dart';

class VariantDetailScreen extends StatefulWidget {
  final String productId;
  final Variant? initialVariant;

  const VariantDetailScreen({
    Key? key,
    required this.productId,
    this.initialVariant,
  }) : super(key: key);

  @override
  State<VariantDetailScreen> createState() => _VariantDetailScreenState();
}

class _VariantDetailScreenState extends State<VariantDetailScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();
  final _attrCtrl = TextEditingController();
  final _importCtrl = TextEditingController();
  final _sellingCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();

  List<PlatformFile> _images = [];

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

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  @override
  void initState() {
    super.initState();
    // Nếu có initialVariant, khởi tạo controller và _images từ nó
    if (widget.initialVariant != null) {
      final v = widget.initialVariant!;
      _nameCtrl.text      = v.variantName;
      _colorCtrl.text     = v.color;
      _attrCtrl.text      = v.attributes;
      _importCtrl.text     = v.importPrice.toString();
      _sellingCtrl.text     = v.sellingPrice.toString();
      _stockCtrl.text     = v.stock.toString();
      _images = v.images.map((img) {
        return PlatformFile(
          name: img['name'] ?? 'image.png',
          bytes: base64Decode(img['base64'] ?? ''),
          size: 0,
        );
      }).toList();
    }
  }

  Future<void> _saveVariant() async {
    if (!_formKey.currentState!.validate()) return;
    final base64Images = await _convertImagesToBase64();

    final variant = Variant(
      id: widget.initialVariant?.id,
      productId: widget.productId,
      variantName: _nameCtrl.text,
      color: _colorCtrl.text,
      attributes: _attrCtrl.text,
      importPrice: double.tryParse(_importCtrl.text) ?? 0,
      sellingPrice: double.tryParse(_sellingCtrl.text) ?? 0,
      stock: int.tryParse(_stockCtrl.text) ?? 0,
      images: base64Images,
      updatedAt: DateTime.now(),
    );

    Navigator.pop(context, variant);
  }

  Future<List<Map<String, String>>> _convertImagesToBase64() async {
    List<Map<String, String>> encoded = [];
    for (var file in _images) {
      Uint8List? bytes = file.bytes ?? await File(file.path!).readAsBytes();
      encoded.add({'name': file.name, 'base64': base64Encode(bytes)});
    }
    return encoded;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
        AppBar( title: Text(
          widget.initialVariant == null ? 'Thêm biến thể' : 'Chỉnh sửa biến thể'
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Tên biến thể'),
                validator: (v) => v!.isEmpty ? 'Không được để trống' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _colorCtrl,
                decoration: const InputDecoration(labelText: 'Màu sắc'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _attrCtrl,
                decoration: const InputDecoration(labelText: 'Thuộc tính'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _importCtrl,
                decoration: const InputDecoration(labelText: 'Giá nhập'),
                keyboardType: TextInputType.number,
                validator: (v) => double.tryParse(v!) == null ? 'Giá không hợp lệ' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _sellingCtrl,
                decoration: const InputDecoration(labelText: 'Giá bán'),
                keyboardType: TextInputType.number,
                validator: (v) => double.tryParse(v!) == null ? 'Giá không hợp lệ' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _stockCtrl,
                decoration: const InputDecoration(labelText: 'Kho'),
                keyboardType: TextInputType.number,
                validator: (v) => int.tryParse(v!) == null ? 'Tồn kho không hợp lệ' : null,
              ),
              const SizedBox(height: 20),
              const Text('Ảnh biến thể', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _images.length + 1,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, index) {
                  if (index < _images.length) {
                    final file = _images[index];
                    Widget img;
                    if (!kIsWeb && file.path != null) {
                      img = Image.file(File(file.path!), fit: BoxFit.cover);
                    } else if (file.bytes != null) {
                      img = Image.memory(file.bytes!, fit: BoxFit.cover);
                    } else {
                      img = const Icon(Icons.broken_image);
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
                            child: const CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.black54,
                              child: Icon(Icons.close, size: 16, color: Colors.white),
                            ),
                          ),
                        )
                      ],
                    );
                  }

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
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _saveVariant,
                icon: const Icon(Icons.save),
                label: const Text('Lưu biến thể'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
