import 'package:get_it/get_it.dart';

import '../data/data.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  final repo = await ChatRepository.create();
  getIt.registerSingleton<ChatRepository>(repo);
}
