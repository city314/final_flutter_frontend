class Address {
  final String id;
  final String receiverName;
  final String phone;
  final String address;
  final bool isDefault;

  Address({
    required this.id,
    required this.receiverName,
    required this.phone,
    required this.address,
    required this.isDefault,
  });

  static Address empty() => Address(
    id: '',
    receiverName: '',
    phone: '',
    address: '',
    isDefault: false,
  );

  bool get isEmpty => id.isEmpty;

  factory Address.fromJson(Map<String, dynamic> json) => Address(
    id: json['id'] ?? '',
    receiverName: json['receiver_name'] ?? '',
    phone: json['phone'] ?? '',
    address: json['address'] ?? '',
    isDefault: json['default'] ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'receiver_name': receiverName,
    'phone': phone,
    'address': address,
    'default': isDefault,
  };
}

class User {
  final String? id;
  String avatar;
  String email;
  String name;
  String gender;
  String birthday;
  String phone;
  final List<Address> addresses;
  final String role;
  String status;
  final DateTime timeCreate;

  User({
    this.id,
    required this.avatar,
    required this.email,
    required this.name,
    required this.gender,
    required this.birthday,
    required this.phone,
    required this.addresses,
    required this.role,
    required this.status,
    required this.timeCreate,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['_id'] as String?,
    avatar: json['avatar'] ?? '',
    email: json['email'] ?? '',
    name: json['name'] ?? '',
    gender: json['gender'] ?? '',
    birthday: json['birthday'] ?? '',
    phone: json['phone'] ?? '',
    addresses: (json['address'] as List<dynamic>? ?? [])
        .map((e) => Address.fromJson(e as Map<String, dynamic>))
        .toList(),
    role: json['role'] ?? 'customer',
    status: json['status'] ?? 'active',
    timeCreate: DateTime.tryParse(json['time_create'] ?? '') ?? DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    if (id != null) '_id': id,
    'avatar': avatar,
    'email': email,
    'name': name,
    'gender': gender,
    'birthday': birthday,
    'phone': phone,
    'address': addresses.map((a) => a.toJson()).toList(),
    'role': role,
    'status': status,
    'time_create': timeCreate.toIso8601String(),
  };
}
