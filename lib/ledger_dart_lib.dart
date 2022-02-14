/// Package Ledger aims to provide a easy way to communicate with Ledger devices.
library ledger;

export 'src/platform_impl/stub_ledger_nano_s.dart'
    if (dart.library.html) 'src/platform_impl/web_ledger_nano_s.dart';
export 'src/apdu/transport.dart';
export 'src/apdu/get_app_and_version.dart';
export 'src/apdu/get_app_version.dart';
