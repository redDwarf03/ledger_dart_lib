[![Pub](https://img.shields.io/pub/v/ledger_dart_lib.svg)](https://pub.dartlang.org/packages/ledger_dart_lib) [![Platform](https://img.shields.io/badge/Platform-Flutter-02569B?logo=flutter)](https://flutter.dev) [![CodeFactor](https://www.codefactor.io/repository/github/reddwarf03/ledger_dart_lib/badge)](https://www.codefactor.io/repository/github/reddwarf03/ledger_dart_lib)

# ledger_dart_lib
Ledger dart library for Flutter. This library aims to provide a easy way to communicate with Ledger devices.

## Informations 
Library under construction.

## Status (2022/03/02)
- For the moment, only Nano S is considered by this library
- The interaction with Nano S is ok in web mode (WebLedgerNanoSImpl)
-- Based on the library Web_HID (https://pub.dev/packages/web_hid)
- The interaction with Nano S is under construction for desktop (LedgerNanoSImpl)
-- Based on the library hid (https://pub.dev/packages/hid)
-- With an example that works: https://gist.github.com/minhnn-mvn/d87b153679134a07a3580da4933b3b33
-- we will need to import this file (from hid) https://github.com/rustui/hid/blob/main/hid_macos/lib/generated_bindings.dart
- Issue with HID Desktop
-- When I copied the example in HID project (hid/example/lib folder) and when i execute this, it works
```
void main() {
  Uint8List transport(
    int cla,
    int ins,
    int p1,
    int p2, [
    Uint8List? payload,
  ]) {
    payload ??= Uint8List.fromList([]);
    return Uint8List.fromList([cla, ins, p1, p2, ...payload]);
  }

  LedgerTransportHidapi ledgerTransportHidapi = LedgerTransportHidapi();
  ledgerTransportHidapi.open(0x1011);

  LedgerTransportResult ledgerTransportResult = ledgerTransportHidapi.exchange(
      transport(0xe0, 0x02, 0x00, 0x00, Uint8List.fromList(hex.decode('00'))));

  print(ledgerTransportResult.data);
}
```
BUT, when i copied your files (with generated_bindings.dart) in a new project, it doesn't work.
```
flutter: pointer = Pointer<hid_device_info>: address=0x600000a23ec0
[ERROR:flutter/lib/ui/ui_dart_state.cc(209)] Unhandled Exception: Exception: Cannot open the Ledger device!  Please check to make sure your Ledger is plugged properly, your Ledger is not locked, the Radix app (in your Ledger) is opening and showing message 'Radix is ready'.
#0      LedgerTransportHidapi.open
package:hid_sse/ledger_transport_hidapi.dart:109
#1      main
package:hid_sse/ledger_transport_hidapi.dart:303
#2      main
.dart_tool/flutter_build/generated_main.dart:80
#3      _runMainZoned.<anonymous closure>.<anonymous closure> (dart:ui/hooks.dart:128:38)
```
in the first case, i'm in the hid environment (= hid project from github) with all dart files... perhaps should i import other files in my new project... 
The author of the example said
"if you use the hid library, you will also have native C implementation of hidapi
if you do not use hid library, you need to add C code to your project
specifically, for macOS you need to add https://github.com/libusb/hidapi/blob/master/mac/hid.c"

I welcome contributions from anyone and is grateful for even the smallest of improvement.

## Todo
- [ ] Migrate project to plugin architecture with multiplatforms management
- [ ] Fix the integration of desktop HID method
- [ ] Test with windows, linux after macOS implementation
- [ ] Explore Nano X implementation



