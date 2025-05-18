class Message {
  final String text;        // Nội dung văn bản của tin nhắn
  final bool isUser;        // True nếu tin nhắn từ người dùng, False nếu từ admin
  final DateTime time;      // Thời gian gửi tin nhắn
  final String image;       // Dữ liệu ảnh dạng base64 (có thể rỗng nếu không gửi ảnh)

  Message({
    required this.text,
    required this.isUser,
    required this.time,
    this.image = '',
  });

  Map<String, dynamic> toJson() => {
    'text': text,
    'isUser': isUser,
    'time': time.toIso8601String(),
    'image': image,
  };

  factory Message.fromJson(Map<String, dynamic> json) => Message(
    text: json['text'],
    isUser: json['isUser'],
    time: DateTime.parse(json['time']),
    image: json['image'] ?? '',
  );
}

