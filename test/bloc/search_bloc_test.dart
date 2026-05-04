import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ai_chat/bloc/search/search.dart';
import 'package:ai_chat/data/data.dart';

class MockChatRepository extends Mock implements ChatRepository {}

void main() {
  late SearchBloc searchBloc;
  late MockChatRepository mockRepository;

  setUp(() {
    mockRepository = MockChatRepository();
    searchBloc = SearchBloc(repository: mockRepository);
  });

  tearDown(() {
    searchBloc.close();
  });

  final mockResults = [
    ChatMessage(content: 'Flutter is awesome', timestamp: 1000, role: 'prompt'),
  ];

  group('SearchBloc', () {
    test('initial state is idle', () {
      expect(searchBloc.state.status, SearchStatus.idle);
      expect(searchBloc.state.results, isEmpty);
    });

    blocTest<SearchBloc, SearchState>(
      'emits [searching, done] when query matches',
      build: () {
        when(
          () => mockRepository.searchMessages('flutter'),
        ).thenAnswer((_) async => mockResults);
        return searchBloc;
      },
      act: (bloc) => bloc.add(const SearchQueryChanged('flutter')),
      wait: const Duration(milliseconds: 400),
      expect: () => [
        isA<SearchState>().having(
          (s) => s.status,
          'status',
          SearchStatus.searching,
        ),
        isA<SearchState>()
            .having((s) => s.status, 'status', SearchStatus.done)
            .having((s) => s.results, 'results', mockResults),
      ],
    );

    blocTest<SearchBloc, SearchState>(
      'emits [searching, empty] when query has no results',
      build: () {
        when(
          () => mockRepository.searchMessages('unknown'),
        ).thenAnswer((_) async => []);
        return searchBloc;
      },
      act: (bloc) => bloc.add(const SearchQueryChanged('unknown')),
      wait: const Duration(milliseconds: 400),
      expect: () => [
        isA<SearchState>().having(
          (s) => s.status,
          'status',
          SearchStatus.searching,
        ),
        isA<SearchState>().having(
          (s) => s.status,
          'status',
          SearchStatus.empty,
        ),
      ],
    );

    blocTest<SearchBloc, SearchState>(
      'emits idle when query is empty',
      build: () => searchBloc,
      act: (bloc) => bloc.add(const SearchQueryChanged('')),
      wait: const Duration(milliseconds: 400),
      expect: () => [const SearchState()],
    );

    blocTest<SearchBloc, SearchState>(
      'emits idle when search is cleared',
      build: () => searchBloc,
      act: (bloc) => bloc.add(const SearchCleared()),
      expect: () => [const SearchState()],
    );
  });
}
