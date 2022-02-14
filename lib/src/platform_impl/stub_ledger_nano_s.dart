// Dart imports:
import 'dart:async';
import 'dart:typed_data';

// Project imports:
import 'package:ledger_dart_lib/src/platform_impl/abstract_ledger_nano_s.dart';

class LedgerNanoSImpl extends AbstractLedgerNanoS {
  @override
  List<int> get response {
    throw Exception("Stub implementation");
  }

  @override
  String getLabelFromCode() {
    throw Exception("Stub implementation");
  }

  @override
  Future<void> connectLedger(Uint8List apdu) async {
    throw Exception("Stub implementation");
  }

  @override
  Future<void> disconnectLedger() async {
    throw Exception("Stub implementation");
  }
}
