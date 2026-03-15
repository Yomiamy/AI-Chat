import 'dart:typed_data';

import 'package:equatable/equatable.dart';

abstract class GeminiApiEvent extends Equatable {}

class InitEvent extends GeminiApiEvent {
  @override
  List<Object?> get props => [];
}

class QueryEvent extends GeminiApiEvent {
  final String query;
  final Uint8List? imageBytes;
  final String? mimeType;

  QueryEvent({required this.query, this.imageBytes, this.mimeType});

  @override
  List<Object?> get props => [query, imageBytes, mimeType];
}
