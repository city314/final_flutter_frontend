class ChatOverview {
  final String customerEmail;
  final String avatarUrl;
  final bool isActive;
  final String lastMessage;
  final DateTime lastMessageTime;

  ChatOverview({
    required this.customerEmail,
    required this.avatarUrl,
    required this.isActive,
    required this.lastMessage,
    required this.lastMessageTime,
  });

  factory ChatOverview.fromJson(Map<String, dynamic> json) {
    return ChatOverview(
      customerEmail: json['customerEmail'],
      avatarUrl: json['avatarUrl'],
      isActive: json['isActive'],
      lastMessage: json['lastMessage'],
      lastMessageTime: DateTime.parse(json['lastMessageTime']),
    );
  }
}
