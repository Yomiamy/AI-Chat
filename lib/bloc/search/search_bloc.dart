import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';
import '../../data/chat_message.dart';
import '../../data/chat_repository.dart';

part 'search_event.dart';
part 'search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final ChatRepository _repository;

  SearchBloc({required ChatRepository repository})
    : _repository = repository,
      super(const SearchState()) {
    on<SearchQueryChanged>(
      _onSearchQueryChanged,
      transformer: _debounce(const Duration(milliseconds: 300)),
    );
    on<SearchCleared>(_onSearchCleared);
  }

  EventTransformer<T> _debounce<T>(Duration duration) {
    return (events, mapper) => events.debounceTime(duration).flatMap(mapper);
  }

  Future<void> _onSearchQueryChanged(
    SearchQueryChanged event,
    Emitter<SearchState> emit,
  ) async {
    final query = event.query.trim();
    if (query.isEmpty) {
      emit(const SearchState());
      return;
    }

    emit(state.copyWith(query: query, status: SearchStatus.searching));

    try {
      final results = _repository.searchMessages(query);
      if (results.isEmpty) {
        emit(state.copyWith(results: [], status: SearchStatus.empty));
      } else {
        emit(state.copyWith(results: results, status: SearchStatus.done));
      }
    } catch (e) {
      emit(
        state.copyWith(status: SearchStatus.error, errorMessage: e.toString()),
      );
    }
  }

  void _onSearchCleared(SearchCleared event, Emitter<SearchState> emit) {
    emit(const SearchState());
  }
}
