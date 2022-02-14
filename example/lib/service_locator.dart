// Package imports:
import 'package:get_it/get_it.dart';
import 'package:ledger_dart_lib/ledger_dart_lib.dart';

GetIt sl = GetIt.instance;

Future<void> setupServiceLocator() async {
  if (sl.isRegistered<LedgerNanoSImpl>()) {
    sl.unregister<LedgerNanoSImpl>();
  }
  sl.registerLazySingleton<LedgerNanoSImpl>(() => LedgerNanoSImpl());
}
