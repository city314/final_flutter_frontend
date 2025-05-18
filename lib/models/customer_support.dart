import 'message.dart';

class CustomerSupport {
  final String? id;
  final String cusEmail;
  final List<Message> messages;
  final DateTime timeCreate;

  CustomerSupport({
    this.id,
    required this.cusEmail,
    required this.messages,
    required this.timeCreate,
  });

  factory CustomerSupport.fromJson(Map<String, dynamic> json) => CustomerSupport(
    id: json['_id'],
    cusEmail: json['customer_email'],
    messages: (json['messages'] as List<dynamic>)
        .map((m) => Message.fromJson(m as Map<String, dynamic>))
        .toList(),
    timeCreate: DateTime.parse(json['time_create']),
  );

  Map<String, dynamic> toJson() => {
    if (id != null) '_id': id,
    'customer_email': cusEmail,
    'messages': messages.map((m) => m.toJson()).toList(),
    'time_create': timeCreate.toIso8601String(),
  };
}
