part of 'search_bloc.dart';

sealed class SearchEvent {
  const SearchEvent();
}

class SearchQueryChanged extends SearchEvent {
  final String query;
  const SearchQueryChanged(this.query);
}

class SearchCleared extends SearchEvent {
  const SearchCleared();
}
