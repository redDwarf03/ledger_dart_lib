// Package imports:
import 'package:get_it/get_it.dart';
import 'package:ledger_dart_lib/ledger_lib_dart.dart';

GetIt sl = GetIt.instance;

Future<void> setupServiceLocator() async {
  if (sl.isRegistered<LedgerNanoSModel>()) {
    sl.unregister<LedgerNanoSModel>();
  }
  sl.registerLazySingleton<LedgerNanoSModel>(() => LedgerNanoSModel());
}
