import 'package:capes_for_you/core/models/chat.dart';
import 'package:capes_for_you/core/models/chat_messages.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GenerativeModel _model;
  static const uuid = Uuid();

  ChatService(String apiKey)
      : _model = GenerativeModel(
          model: 'gemini-1.5-flash-latest',
          apiKey: apiKey,
        );

  Future<Chat> createChat(String userId) async {
    final chat = Chat(
      id: uuid.v4(),
      userId: userId,
      title: 'Nova conversa',
      createdAt: DateTime.now(),
    );

    await _firestore.collection('chats').doc(chat.id).set(chat.toMap());

    return chat;
  }

  Future<void> addMessage(String chatId, String content, String role) async {
    final message = ChatMessage(
      id: uuid.v4(),
      content: content,
      role: role,
      timestamp: DateTime.now(),
    );

    await _firestore.collection('chats').doc(chatId).update({
      'messages': FieldValue.arrayUnion([message.toMap()])
    });
  }

  Stream<List<ChatMessage>> getMessages(String chatId) {
    return _firestore.collection('chats').doc(chatId).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) return [];

      final chat = Chat.fromMap({...data, 'id': doc.id});
      return chat.messages;
    });
  }

  Future<String> generateResponse(String prompt) async {
    final content = [Content.text(prompt)];
    final response = await _model.generateContent(content);
    return response.text ?? 'Desculpe, não consegui gerar uma resposta.';
  }
}
