// Project imports:
import 'package:ledger_dart_lib/src/apdu/transport.dart';

final getAppVersion = transport(0xe0, 0x01, 0x00, 0x00);
