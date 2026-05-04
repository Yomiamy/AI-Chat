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
  /// Called when photo permission is permanently denied,
  /// so the widget layer can show the appropriate dialog.
  final VoidCallback? onPermissionDenied;

  GeminiApiPickImageEvent({this.onPermissionDenied});

  @override
  List<Object?> get props => [];
}

class GeminiApiRemoveFileEvent extends GeminiApiEvent {}

class GeminiApiNewChatEvent extends GeminiApiEvent {}

class GeminiApiClearAllEvent extends GeminiApiEvent {}
