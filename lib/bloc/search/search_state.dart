part of 'search_bloc.dart';

enum SearchStatus { idle, searching, done, empty, error }

class SearchState {
  final String query;
  final List<ChatMessage> results;
  final SearchStatus status;
  final String? errorMessage;

  const SearchState({
    this.query = '',
    this.results = const [],
    this.status = SearchStatus.idle,
    this.errorMessage,
  });

  SearchState copyWith({
    String? query,
    List<ChatMessage>? results,
    SearchStatus? status,
    String? errorMessage,
  }) {
    return SearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
