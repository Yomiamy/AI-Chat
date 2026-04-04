part of 'gemini_api_bloc.dart';

abstract class GeminiApiEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class GeminiApiInitEvent extends GeminiApiEvent {}

class GeminiApiQueryEvent extends GeminiApiEvent {
  final String query;

  GeminiApiQueryEvent({required this.query});

  @override
  List<Object?> get props => [query];
}

class GeminiApiPickFileEvent extends GeminiApiEvent {}

class GeminiApiPickImageEvent extends GeminiApiEvent {
  final dynamic context; // for context in PermissionManager
  
  GeminiApiPickImageEvent({this.context});
}

class GeminiApiRemoveFileEvent extends GeminiApiEvent {}
