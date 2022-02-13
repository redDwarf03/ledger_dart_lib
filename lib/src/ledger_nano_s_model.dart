// Dart imports:
import 'dart:async';
import 'dart:js' show allowInterop;
import 'dart:js_util' show getProperty;
import 'dart:math';
import 'dart:typed_data';

// Flutter imports:
import 'package:flutter/foundation.dart';

// Package imports:
import 'package:convert/convert.dart';
import 'package:web_hid/web_hid.dart';

// Project imports:
import 'package:ledger_dart_lib/src/utils.dart';

class LedgerNanoSModel extends ChangeNotifier {
  HidDevice? _device;

  List<int> data = List.empty(growable: true);
  List<int> blockParsed = List.empty(growable: true);
  int lastBlockSeqId = -1;
  int dataLength = -1;

  List<int> get response => blockParsed;

  Uint8List _makeBlock(Uint8List apdu, int blockSeqId, int totalLengthApdu) {
    final channel = Random().nextInt(0xffff);
    const tag = 0x05;

    var apduBuffer = WriteBuffer();
    if (blockSeqId == 0) {
      apduBuffer.putUint16(totalLengthApdu, endian: Endian.big);
    }
    apduBuffer.putUint8List(apdu);
    var apduData = apduBuffer.done();

    var writeBuffer = WriteBuffer();
    writeBuffer.putUint16(channel, endian: Endian.big);
    writeBuffer.putUint8(tag);
    writeBuffer.putUint16(blockSeqId, endian: Endian.big);
    writeBuffer.putUint8List(apduData.buffer.asUint8List());
    return writeBuffer.done().buffer.asUint8List();
  }

  void _parseBlock(ByteData block) {
    var readBuffer = ReadBuffer(block);

    readBuffer.getUint16(endian: Endian.big);
    readBuffer.getUint8();
    lastBlockSeqId = readBuffer.getUint16(endian: Endian.big);

    if (lastBlockSeqId == 0) {
      dataLength = readBuffer.getUint16(endian: Endian.big);
      if (dataLength >= 57) {
        data.addAll(readBuffer.getUint8List(57));
      } else {
        data.addAll(readBuffer.getUint8List(dataLength));
      }
    } else {
      if (dataLength > (57 + (lastBlockSeqId) * 59)) {
        data.addAll(readBuffer.getUint8List(59));
      } else {
        data.addAll(readBuffer
            .getUint8List(dataLength - (57 + (lastBlockSeqId - 1) * 59)));
      }
    }
  }

  String getLabelFromCode() {
    String labelResponse = '';
    String blockParsedHex = hex.encode(blockParsed);
    if (kDebugMode) {
      print(blockParsedHex);
    }

    if (blockParsedHex.length >= 4) {
      switch (blockParsedHex.substring(blockParsedHex.length - 4)) {
        case '6d00':
          labelResponse = 'Invalid parameter received';
          break;
        case '670A':
          labelResponse = 'Lc is 0x00 whereas an application name is required';
          break;
        case '6807':
          labelResponse = 'The requested application is not present';
          break;
        case '6985':
          labelResponse = 'Cancel the operation';
          break;
        case '9000':
          labelResponse = 'Success of the operation';
          break;
        case '0000':
          labelResponse = 'Success of the operation';
          break;
        default:
          labelResponse = blockParsedHex.substring(blockParsedHex.length - 4);
      }
    }
    return labelResponse;
  }

  Future<void> connectLedger(Uint8List apdu) async {
    blockParsed = List.empty(growable: true);
    if (_device != null) {
      if (_device!.opened) {
        _device!.close().then((value) {}).catchError((error) {});
      }
    }

    hid.subscribeConnect(allowInterop((event) {}));

    List<HidDevice> requestDevice = await hid.requestDevice(RequestOptions(
      filters: [
        RequestOptionsFilter(
          vendorId: 0x2c97,
        )
      ],
    ));
    _device = requestDevice[0];
    await _device!.open();

    _device!.subscribeInputReport(allowInterop((event) {
      ByteData blockData = getProperty(event, 'data');
      _parseBlock(blockData);
      blockParsed = data.toList();
      if (kDebugMode) {
        print('blockParsed' + blockParsed.toString());
        print('blockParsed (length) = ' + blockParsed.length.toString());
      }
      if (blockParsed.length >= dataLength) {
        if (kDebugMode) {
          print('blockParsedfinal' + blockParsed.toString());
        }
        notifyListeners();
        data = List.empty(growable: true);
        lastBlockSeqId = -1;
        dataLength = -1;
      }
    }));

    List<int> _apduPart;
    int remainingLength = apdu.length;
    int blockSeqId = 0;

    while (remainingLength > 0) {
      _apduPart = List<int>.filled(64, 0, growable: false);
      while (remainingLength > 0) {
        if (blockSeqId == 0) {
          if (apdu.length > 57) {
            _apduPart = apdu.sublist(0, 57);
          } else {
            _apduPart = concatUint8List(<Uint8List>[
              apdu.sublist(0, apdu.length),
              Uint8List.fromList(List.filled(59 - remainingLength - 2, 0))
            ]);
          }
        } else {
          if (remainingLength > 59) {
            _apduPart = apdu.sublist(
                57 + (59 * (blockSeqId - 1)), 57 + (59 * blockSeqId));
          } else {
            _apduPart = concatUint8List(<Uint8List>[
              apdu.sublist(57 + (59 * (blockSeqId - 1)),
                  57 + (59 * (blockSeqId - 1)) + remainingLength),
              Uint8List.fromList(List.filled(59 - remainingLength, 0))
            ]);
          }
        }

        Uint8List blockBytes =
            _makeBlock(Uint8List.fromList(_apduPart), blockSeqId, apdu.length);
        if (kDebugMode) {
          print('apduPart: ' + _apduPart.toString());
          print('apduPartHex: ' + hex.encode(_apduPart));
          print('apduPartLength: ' + _apduPart.length.toString());
          print('blockBytes: ' + blockBytes.toString());
          print('blockBytes length: ' + blockBytes.length.toString());
        }

        await _device?.sendReport(0, blockBytes);
        blockSeqId++;

        remainingLength = remainingLength - _apduPart.length;
      }
    }
  }

  Future<void> disconnectLedger() async {
    hid.subscribeDisconnect(allowInterop((event) {}));
  }
}
