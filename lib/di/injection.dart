import 'package:get_it/get_it.dart';
import '../data/chat_repository.dart';
import '../data/chat_repository_impl.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  final repo = await ObjectBoxChatRepository.create();
  getIt.registerSingleton<ChatRepository>(repo);
}
