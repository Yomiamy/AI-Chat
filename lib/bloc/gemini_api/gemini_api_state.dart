part of 'gemini_api_bloc.dart';

class GeminiApiState {
  final Status? status;
  final List<String>? chatList;
  final Uint8List? selectedFileBytes;
  final String? selectedMimeType;

  const GeminiApiState({
    this.status = Status.initial,
    this.chatList,
    this.selectedFileBytes,
    this.selectedMimeType,
  });

  GeminiApiState copyWith({
    Status? status,
    List<String>? chatList,
    Uint8List? selectedFileBytes,
    String? selectedMimeType,
  }) {
    return GeminiApiState(
      status: status ?? this.status,
      chatList: chatList ?? this.chatList,
      selectedFileBytes: selectedFileBytes,
      selectedMimeType: selectedMimeType,
    );
  }
}
