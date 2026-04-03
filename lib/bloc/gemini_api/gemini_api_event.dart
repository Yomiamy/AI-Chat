part of 'gemini_api_bloc.dart';

abstract class GeminiApiEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class GeminiApiInitEvent extends GeminiApiEvent {}

class GeminiApiQueryEvent extends GeminiApiEvent {
  final String query;
  final Uint8List? imageBytes;
  final String? mimeType;

  GeminiApiQueryEvent({required this.query, this.imageBytes, this.mimeType});

  @override
  List<Object?> get props => [query, imageBytes, mimeType];
}
