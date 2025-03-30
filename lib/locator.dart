import 'package:get_it/get_it.dart';
import '/data/db/database.dart';

GetIt locator = GetIt.instance;

void setUp() {
  locator.registerLazySingleton(() => AppDatabase());
}
