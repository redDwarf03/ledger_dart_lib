///   Ledger Dart Library
///   (c) 2022 redDwarf03
///
///  Licensed under the GNU Affero General Public License, Version 3 (the "License");
///  you may not use this file except in compliance with the License.
///  You may obtain a copy of the License at
//
///      https://www.gnu.org/licenses/agpl-3.0.en.html
//
///   Unless required by applicable law or agreed to in writing, software
///   distributed under the License is distributed on an "AS IS" BASIS,
///   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
///   See the License for the specific language governing permissions and
///   limitations under the License.

// Dart imports:
// ignore_for_file: avoid_web_libraries_in_flutter

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
import 'package:ledger_dart_lib/src/platform_impl/abstract_ledger_nano_s.dart';
import 'package:ledger_dart_lib/src/utils.dart';

class LedgerNanoSImpl extends AbstractLedgerNanoS {
  HidDevice? _device;

  List<int> data = List.empty(growable: true);
  List<int> blockParsed = List.empty(growable: true);
  int lastBlockSeqId = -1;
  int dataLength = -1;

  /// Length of a block
  final int blockSize = 64;

  /// Legnth of the command data when the Block Seq Id > 1
  final int blockDataSize = 59;

  /// Legnth of the command data when the Block Seq Id = 1
  /// The first block contains the number of bytes of command data to follow
  final int firstBlockDataSize = 57;

  @override
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
      if (dataLength >= firstBlockDataSize) {
        data.addAll(readBuffer.getUint8List(firstBlockDataSize));
      } else {
        data.addAll(readBuffer.getUint8List(dataLength));
      }
    } else {
      if (dataLength >
          (firstBlockDataSize + (lastBlockSeqId) * blockDataSize)) {
        data.addAll(readBuffer.getUint8List(blockDataSize));
      } else {
        data.addAll(readBuffer.getUint8List(dataLength -
            (firstBlockDataSize + (lastBlockSeqId - 1) * blockDataSize)));
      }
    }
  }

  @override
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

  @override
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
      _apduPart = List<int>.filled(blockSize, 0, growable: false);
      while (remainingLength > 0) {
        if (blockSeqId == 0) {
          if (apdu.length > firstBlockDataSize) {
            _apduPart = apdu.sublist(0, firstBlockDataSize);
          } else {
            _apduPart = concatUint8List(<Uint8List>[
              apdu.sublist(0, apdu.length),
              Uint8List.fromList(
                  List.filled(blockDataSize - remainingLength - 2, 0))
            ]);
          }
        } else {
          if (remainingLength > blockDataSize) {
            _apduPart = apdu.sublist(
                firstBlockDataSize + (blockDataSize * (blockSeqId - 1)),
                firstBlockDataSize + (blockDataSize * blockSeqId));
          } else {
            _apduPart = concatUint8List(<Uint8List>[
              apdu.sublist(
                  firstBlockDataSize + (blockDataSize * (blockSeqId - 1)),
                  firstBlockDataSize +
                      (blockDataSize * (blockSeqId - 1)) +
                      remainingLength),
              Uint8List.fromList(
                  List.filled(blockDataSize - remainingLength, 0))
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

  @override
  Future<void> disconnectLedger() async {
    hid.subscribeDisconnect(allowInterop((event) {}));
  }
}
