import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../models/user.dart';
import 'package:cpmad_final/service/UserService.dart';
import 'package:cpmad_final/pattern/current_user.dart';

class ManageAddressesScreen extends StatefulWidget {
  const ManageAddressesScreen({super.key});

  @override
  State<ManageAddressesScreen> createState() => _ManageAddressesScreenState();
}

class _ManageAddressesScreenState extends State<ManageAddressesScreen> {
  List<Address> addresses = [];
  final email = CurrentUser().email ?? 'thonglinhiq@gmail.com';

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    try {
      final data = await UserService.fetchAddresses(email);
      setState(() {
        addresses = data;
      });
    } catch (e) {
      print('Lỗi tải địa chỉ: $e');
    }
  }

  void _addAddress() async {
    final newAddress = await _showAddressDialog();
    if (newAddress != null) {
      try {
        await UserService.addAddress(email, newAddress);
        await _loadAddresses();
      } catch (e) {
        print('Lỗi thêm địa chỉ: $e');
      }
    }
  }

  void _editAddress(int index) async {
    final edited = await _showAddressDialog(initial: addresses[index]);
    if (edited != null) {
      try {
        await UserService.updateAddress(email, edited);
        await _loadAddresses();
      } catch (e) {
        print('Lỗi cập nhật: $e');
      }
    }
  }

  void _deleteAddress(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xoá địa chỉ'),
        content: const Text('Bạn có chắc muốn xoá địa chỉ này không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Huỷ')),
          TextButton(
            onPressed: () async {
              try {
                await UserService.deleteAddress(email, addresses[index].id);
                await _loadAddresses();
                Navigator.pop(context);
              } catch (e) {
                print('Lỗi xoá địa chỉ: $e');
              }
            },
            child: const Text('Xoá', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<Address?> _showAddressDialog({Address? initial}) {
    final nameController = TextEditingController(text: initial?.receiverName ?? '');
    final phoneController = TextEditingController(text: initial?.phone ?? '');
    final streetController = TextEditingController(text: initial?.address ?? '');

    return showDialog<Address>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(initial == null ? 'Thêm địa chỉ' : 'Chỉnh sửa địa chỉ'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Tên người nhận'),
              ),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Số điện thoại'),
                keyboardType: TextInputType.phone,
              ),
              TextField(
                controller: streetController,
                decoration: const InputDecoration(labelText: 'Địa chỉ'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Huỷ')),
          TextButton(
            onPressed: () {
              final newAddress = Address(
                id: initial?.id ?? const Uuid().v4(),
                receiverName: nameController.text.trim(),
                phone: phoneController.text.trim(),
                address: streetController.text.trim(),
                isDefault: initial?.isDefault ?? false,
              );
              Navigator.pop(context, newAddress);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý địa chỉ'),
        backgroundColor: Colors.blueAccent,
      ),
      body: addresses.isEmpty
          ? const Center(child: Text('Chưa có địa chỉ'))
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: addresses.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, index) {
          final address = addresses[index];
          final isDefault = address.isDefault;

          return ListTile(
            leading: const Icon(Icons.location_on),
            title: Text(address.receiverName),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SĐT: ${address.phone}'),
                Text('Địa chỉ: ${address.address}'),
                if (isDefault)
                  const Text('Địa chỉ mặc định', style: TextStyle(color: Colors.green)),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'edit') _editAddress(index);
                if (value == 'delete') _deleteAddress(index);
                if (value == 'default') {
                  await UserService.setDefaultAddress(email, address.id);
                  await _loadAddresses();
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Chỉnh sửa')),
                const PopupMenuItem(value: 'delete', child: Text('Xoá')),
                if (!isDefault)
                  const PopupMenuItem(value: 'default', child: Text('Đặt làm mặc định')),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addAddress,
        child: const Icon(Icons.add),
      ),
    );
  }
}

extension on Address {
  Address copyWith({
    String? id,
    String? receiverName,
    String? phoneNumber,
    String? streetDetail,
    bool? isDefault,
  }) {
    return Address(
      id: id ?? this.id,
      receiverName: receiverName ?? this.receiverName,
      phone: phoneNumber ?? this.phone,
      address: streetDetail ?? this.address,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
