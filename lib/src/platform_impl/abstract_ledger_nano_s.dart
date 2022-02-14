// Dart imports:
import 'dart:typed_data';

// Flutter imports:
import 'package:flutter/foundation.dart';

abstract class AbstractLedgerNanoS extends ChangeNotifier {
  List<int> get response;

  String getLabelFromCode();

  Future<void> connectLedger(Uint8List apdu);

  Future<void> disconnectLedger();
}
