import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/review.dart';

class WebSocketService {
  late IO.Socket socket;

  void connect(void Function(Review) onNewReview) {
    socket = IO.io('http://localhost:3002', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    socket.onConnect((_) => print('Connected to socket'));
    socket.on('newReview', (data) {
      final review = Review.fromJson(data);
      onNewReview(review);
    });

    socket.onDisconnect((_) => print('Disconnected from socket'));
  }

  void sendReview(Review review) {
    socket.emit('sendReview', review.toJson());
  }

  void disconnect() {
    socket.dispose();
  }
}
