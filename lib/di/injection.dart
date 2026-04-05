import 'package:get_it/get_it.dart';

import '../data/chat_repository.dart';
import '../generated/objectbox/objectbox.g.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  final store = await openStore();
  getIt.registerSingleton<ChatRepository>(ChatRepository(store));
}

void disposeDependencies() {
  getIt<ChatRepository>().dispose();
}
