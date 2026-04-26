part of 'gemini_api_bloc.dart';

class GeminiApiState extends Equatable {
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
    bool clearFile = false,
    bool clearChat = false,
  }) {
    return GeminiApiState(
      status: status ?? this.status,
      chatList: clearChat ? null : (chatList ?? this.chatList),
      selectedFileBytes:
          clearFile ? null : (selectedFileBytes ?? this.selectedFileBytes),
      selectedMimeType:
          clearFile ? null : (selectedMimeType ?? this.selectedMimeType),
    );
  }
  
  @override
  List<Object?> get props => [
    status,
    chatList,
    selectedFileBytes,
    selectedMimeType,
  ];
}
