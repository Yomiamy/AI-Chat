part of 'gemini_api_bloc.dart';

abstract class GeminiApiEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class InitEvent extends GeminiApiEvent {}

class QueryEvent extends GeminiApiEvent {
  final String query;
  final Uint8List? imageBytes;
  final String? mimeType;

  QueryEvent({required this.query, this.imageBytes, this.mimeType});

  @override
  List<Object?> get props => [query, imageBytes, mimeType];
}
