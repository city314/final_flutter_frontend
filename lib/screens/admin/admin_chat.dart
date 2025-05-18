import 'dart:convert';
import 'package:cpmad_final/pattern/current_user.dart';
import 'package:cpmad_final/service/UserService.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:go_router/go_router.dart';

class CustomerSupportScreen extends StatefulWidget {
  final String email;
  const CustomerSupportScreen({super.key, required this.email});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<CustomerSupportScreen> {
  late IO.Socket socket;
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _picker = ImagePicker();
  final FocusNode _inputFocusNode = FocusNode();
  final currentUserRole = CurrentUser().role ?? 'admin';
  String? chatId;

  List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _connectSocket();
  }

  void _connectSocket() {
    socket = IO.io('http://localhost:3001', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    socket.onConnect((_) {
      print('🟢 Connected to socket');
    });

    socket.on('receive_message', (data) {
      final currentEmail = CurrentUser().email ?? '';

      // Chỉ nhận tin nhắn nếu là cuộc trò chuyện của user đó
      if (data['customer_email'] == (currentUserRole == 'customer' ? currentEmail : widget.email)) {
        setState(() {
          _messages.add({
            'text': data['text'],
            'image': data['image'],
            'isUser': data['isUser'],
            'senderEmail': data['senderEmail'], // <- mới thêm
            'time': DateTime.parse(data['time']),
          });
        });

        _scrollController.jumpTo(_scrollController.position.maxScrollExtent + 100);
      }
    });

    socket.onDisconnect((_) => print('🔴 Disconnected from socket'));
  }

  void _loadMessages() async {
    final String email = currentUserRole == 'customer'
        ? (CurrentUser().email ?? '')
        : widget.email;

    final messages = await UserService.getMessages(email);
    setState(() {
      _messages = messages;
    });

    await Future.delayed(Duration(milliseconds: 100));
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  }

  void _sendMessage({String? text, String? imageBase64}) {
    if ((text == null || text.trim().isEmpty) && imageBase64 == null) return;

    final String senderEmail = CurrentUser().email ?? '';

    final msg = {
      'text': text ?? '',
      'image': imageBase64 ?? '',
      'isUser': currentUserRole == 'customer',
      'senderEmail': senderEmail,
      'customer_email': currentUserRole == 'customer'
          ? senderEmail
          : widget.email,
    };

    socket.emit('send_message', msg);

    _controller.clear();
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent + 100);
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      final base64Image = base64Encode(bytes);
      _sendMessage(imageBase64: base64Image);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color themeColor = const Color(0xFF3F51B5); // Indigo
    final Color accentColor = const Color(0xFFFFC107); // Amber
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final goRouter = GoRouter.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: themeColor,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.grey[300],
              child: Icon(Icons.person, color: themeColor),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(widget.email),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (goRouter.canPop()) {
              // Nếu còn stack thì quay lại màn trước
              goRouter.pop();
            } else {
              // Nếu không còn stack, điều hướng theo role
              if (currentUserRole == 'customer') {
                goRouter.goNamed('home');  // tên route home customer
              } else if (currentUserRole == 'admin') {
                goRouter.goNamed('admin_support');  // tên route admin support
              } else {
                goRouter.goNamed('login');         // fallback về login
              }
            }
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final data = _messages[index];
                final isMe = (data['isUser'] && currentUserRole == 'customer') ||
                    (!data['isUser'] && currentUserRole == 'admin');
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isMe
                          ? themeColor.withValues(alpha: 0.85)
                          : (isDark ? Colors.grey[700] : Colors.grey[300]),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: data['image'] != ''
                        ? GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => Dialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            child: Container(
                              padding: EdgeInsets.all(10),
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.8,
                                maxHeight: MediaQuery.of(context).size.height * 0.8,
                              ),
                              child: Image.memory(
                                base64Decode(data['image']),
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        );
                      },
                      child: Image.memory(
                        base64Decode(data['image']),
                        width: MediaQuery.of(context).size.width * 0.6,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    )
                        : Text(
                      data['text'] ?? '',
                      style: TextStyle(color: isMe ? Colors.white : Colors.black87),
                    ),
                  ),
                );
              },
            ),
          ),
          Divider(height: 1),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: isDark ? Colors.grey[850] : Colors.white,
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.image, color: accentColor),
                  onPressed: _pickImage,
                ),
                Expanded(
                  child: RawKeyboardListener(
                    focusNode: _inputFocusNode,
                    onKey: (event) {
                      if (event is RawKeyDownEvent) {
                        if (event.isShiftPressed && event.logicalKey == LogicalKeyboardKey.enter) {
                          final text = _controller.text;
                          final selection = _controller.selection;
                          final newText = text.replaceRange(selection.start, selection.end, '');
                          _controller.text = newText;
                          _controller.selection = TextSelection.fromPosition(
                            TextPosition(offset: selection.start),
                          );
                        } else if (event.logicalKey == LogicalKeyboardKey.enter) {
                          // Chặn xuống dòng mặc định và gửi
                          _sendMessage(text: _controller.text.trim());
                          _controller.clear();
                          // Không cho xuống dòng
                          FocusScope.of(context).requestFocus(_inputFocusNode);
                        }
                      }
                    },
                    child: TextField(
                      controller: _controller,
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: themeColor,
                  child: IconButton(
                    icon: Icon(Icons.send, color: Colors.white),
                    onPressed: () {
                      _sendMessage(text: _controller.text.trim());
                      _controller.clear();
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
