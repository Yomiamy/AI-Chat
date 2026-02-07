import 'package:equatable/equatable.dart';

abstract class GeminiApiEvent extends Equatable {}

class InitEvent extends GeminiApiEvent {
  @override
  List<Object?> get props => [];
}

class QueryEvent extends GeminiApiEvent {
  final String query;

  QueryEvent({required this.query});

  @override
  List<Object?> get props => [query];
}
