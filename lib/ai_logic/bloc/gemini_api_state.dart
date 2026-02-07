import 'status.dart';

class GeminiApiState {
  final Status? status;
  final List<String>? chatList;

  const GeminiApiState({this.status = Status.initial, this.chatList});

  GeminiApiState copyWith({Status? status, List<String>? chatList}) {
    return GeminiApiState(
      status: status ?? this.status,
      chatList: chatList ?? this.chatList,
    );
  }
}
