import 'package:cpmad_final/service/UserService.dart';
import 'package:flutter/material.dart';
import '../../models/user.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AdminUserScreen extends StatefulWidget {
  const AdminUserScreen({super.key});

  @override
  State<AdminUserScreen> createState() => _AdminUserScreenState();
}

class _AdminUserScreenState extends State<AdminUserScreen> {
  List<User> users = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  void _loadUsers() async {
    try {
      final result = await UserService.fetchUsers();
      setState(() {
        users = result;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Lỗi fetchUsers: $e');
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lỗi khi tải danh sách người dùng'), backgroundColor: Colors.red),
      );
    }
  }

  void _toggleStatus(User user) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        final isBanning = user.status == 'active';
        return AlertDialog(
          title: Text(isBanning ? 'Xác nhận cấm tài khoản' : 'Xác nhận mở khóa'),
          content: Text(
            isBanning
                ? 'Bạn có chắc muốn cấm tài khoản "${user.name}" không? Người dùng sẽ không thể đăng nhập nữa.'
                : 'Bạn có chắc muốn mở khóa tài khoản "${user.name}" không?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newStatus = isBanning ? 'inactive' : 'active';
                final success = await UserService.updateUserStatus(user.email, newStatus);
                Navigator.pop(dialogContext);

                if (success) {
                  setState(() => user.status = newStatus);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Cập nhật trạng thái thành công FE'), backgroundColor: Colors.green),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi khi cập nhật trạng thái FE'), backgroundColor: Colors.red),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isBanning ? Colors.red : Colors.green,
              ),
              child: Text(isBanning ? 'Cấm' : 'Mở khóa'),
            ),
          ],
        );
      },
    );
  }

  void _viewDetail(User user) {
    final defaultAddr = user.addresses.firstWhere(
          (a) => a.isDefault,
      orElse: () => Address.empty(),
    );

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Thông tin chi tiết'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: CircleAvatar(backgroundImage: NetworkImage(user.avatar), radius: 40)),
                const SizedBox(height: 12),
                Text('Tên: ${user.name}'),
                Text('Email: ${user.email}'),
                Text('Giới tính: ${user.gender}'),
                Text('Ngày sinh: ${user.birthday}'),
                Text('SĐT: ${user.phone}'),
                const SizedBox(height: 8),
                Text('Địa chỉ mặc định:', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(defaultAddr.isEmpty ? 'Chưa có địa chỉ' : defaultAddr.address),
                const SizedBox(height: 8),
                Text('Vai trò: ${user.role == 'admin' ? 'Quản trị' : 'Khách hàng'}'),
                Text('Trạng thái: ${user.status == 'active' ? 'Hoạt động' : 'Đã cấm'}'),
                Text('Ngày tạo: ${user.timeCreate.day}/${user.timeCreate.month}/${user.timeCreate.year}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  void _editUser(User user) {
    final nameController = TextEditingController(text: user.name);
    final emailController = TextEditingController(text: user.email);

    final phoneController = TextEditingController(text: user.phone);

    String selectedGender = user.gender;
    DateTime? selectedBirthday = DateTime.tryParse(user.birthday);

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        final birthdayTextController = TextEditingController(
          text: user.birthday.isNotEmpty
              ? '${selectedBirthday?.day.toString().padLeft(2, '0')}/${selectedBirthday?.month.toString().padLeft(2, '0')}/${selectedBirthday?.year}'
              : '',
        );
        return AlertDialog(
          title: const Text('Chỉnh sửa thông tin'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Tên'),
                ),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                DropdownButtonFormField<String>(
                  value: selectedGender.isNotEmpty ? selectedGender : null,
                  decoration: const InputDecoration(labelText: 'Giới tính'),
                  items: ['Male', 'Female']
                      .map((gender) => DropdownMenuItem(value: gender, child: Text(gender)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) selectedGender = value;
                  },
                ),
                TextFormField(
                  controller: birthdayTextController,
                  readOnly: true,
                  decoration: const InputDecoration(labelText: 'Ngày sinh'),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedBirthday ?? DateTime(2000),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => selectedBirthday = picked);
                      birthdayTextController.text =
                      '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
                    }
                  },
                ),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Số điện thoại'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                setState(() {
                  user.name = nameController.text;
                  user.email = emailController.text;
                  user.gender = selectedGender;
                  user.birthday = selectedBirthday != null
                      ? '${selectedBirthday!.year}-${selectedBirthday!.month.toString().padLeft(2, '0')}-${selectedBirthday!.day.toString().padLeft(2, '0')}'
                      : '';
                  user.phone = phoneController.text;
                });

                final success = await UserService.updateUser(user);
                Navigator.pop(dialogContext);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Cập nhật thành công' : 'Lỗi khi cập nhật người dùng'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              },
              child: const Text('Lưu'),
            )
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (users.isEmpty) {
      return const Center(child: Text('Không có người dùng nào.'));
    }

    if (width < 800) {
      // Mobile or small tablet: List card layout
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: users.length,
        itemBuilder: (_, i) => Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            leading: CircleAvatar(backgroundImage: NetworkImage(users[i].avatar)),
            title: Text(users[i].name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(users[i].email),
                Text('Vai trò: ${users[i].role == 'admin' ? 'Quản trị' : 'Khách hàng'}'),
                Text('Trạng thái: ${users[i].status == 'active' ? 'Hoạt động' : 'Đã cấm'}'),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.more_horiz),
              onPressed: () => _viewDetail(users[i]),
            ),
          ),
        ),
      );
    }

    // Desktop or web: Table view
    return Container(
      width: double.infinity, // full width của phần thân (không sidebar)
      padding: const EdgeInsets.all(16),
      child: DataTable(
        headingRowColor: MaterialStateProperty.all(const Color(0xFFF2F4F7)),
        columnSpacing: 24,
        columns: const [
          DataColumn(label: Text('Tên')),
          DataColumn(label: Text('Email')),
          DataColumn(label: Text('Vai trò')),
          DataColumn(label: Text('Trạng thái')),
          DataColumn(label: Text('Action')),
        ],
        rows: users.map((u) {
          return DataRow(cells: [
            DataCell(Text(u.name)),
            DataCell(Text(u.email)),
            DataCell(Text(u.role == 'admin' ? 'Quản trị' : 'Khách hàng')),
            DataCell(Text(
              u.status == 'active' ? 'Hoạt động' : 'Đã cấm',
              style: TextStyle(color: u.status == 'active' ? Colors.green : Colors.red),
            )),
            DataCell(Row(children: [
              IconButton(icon: const Icon(Icons.visibility, color: Colors.indigo), onPressed: () => _viewDetail(u)),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.orange),
                onPressed: () => _editUser(u),
              ),
              IconButton(
                icon: Icon(
                  u.status == 'active' ? Icons.lock : Icons.lock_open,
                  color: u.status == 'active' ? Colors.red : Colors.green,
                ),
                onPressed: () => _toggleStatus(u),
              ),
            ])),
          ]);
        }).toList(),
      ),
    );
  }
}
