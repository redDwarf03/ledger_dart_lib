import 'dart:math';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:flutter/foundation.dart';
import 'package:ledger_dart_lib/src/hidapi/hidapi_service.dart';
import 'package:ledger_dart_lib/src/hidapi/hidapi_service_mac.dart';
import 'package:ledger_dart_lib/src/platform_impl/abstract_ledger_nano_s.dart';

final HidapiService _hidapiService = HidapiServiceMac();

class LedgerTransportResult {
  int statusWord;
  Uint8List data;
  LedgerTransportResult({required this.statusWord, required this.data});
}

class LedgerNanoSImpl extends AbstractLedgerNanoS {
  LedgerTransportResult? ledgerTransportResult;
  static const int kLedgerVendorId = 0x2c97;
  static const int kLedgerProductIdAny = 0x00;
  static const int kLedgerProductIdNanoS = 0x1011;
  static const int kLedgerProductIdNanoX = 0x4011;
  static const int kPackageSize = 64;
  static const int kChannelByte1 = 0x01;
  static const int kChannelByte2 = 0x01;
  static const int kTag = 0x05;
  static const String kErrorHelp =
      "Please check to make sure your Ledger is plugged properly, your Ledger is not locked, the Radix app (in your Ledger) is opening and showing message 'Radix is ready'.";

  bool _isOpen = false;
  HidapiDevice? _device;

  String _appendErrorMessage(String message) {
    String? error = _device?.hidError();
    if (error != null) {
      // macOS does not implement method hid_error()
      if (error != 'hid_error is not implemented yet') {
        message += ' Error = $error';
      }
    }
    return message;
  }

  void _open(int productId) {
    if (_isOpen) {
      throw Exception('This LedgerTransportHidapi has already been opened!');
    }

    final devices = _hidapiService.hidEnumerate(
      vendorId: kLedgerVendorId,
      productId: productId,
    );
    for (var device in devices) {
      // on macOS, usagePage = 0xffa0 mean the correct Ledger
      if (device.interfaceNumber == 0 || device.usagePage == 0xffa0) {
        //device.printDebugInfo();
        _device = device;
        break; // we will use the first device
      }
    }
    if (_device == null) {
      throw Exception(
          'Cannot find Ledger device with vendor_id 0x${kLedgerVendorId.toRadixString(16)} . $kErrorHelp');
    }

    bool result = _device!.hidOpenPath();
    if (result == false) {
      String msg =
          _appendErrorMessage('Cannot open the Ledger device!  $kErrorHelp');
      _device = null;
      throw Exception(msg);
    }

    _isOpen = true;
    _device!.hidSetNonblocking(true);
  }

  void _close() {
    print('LedgerTransportHidapi.close()');
    if (_isOpen) {
      _device?.hidClose();
      _device = null;
      _isOpen = false;
    }
  }

  int _send(Uint8List data) {
    if (_isOpen == false) {
      throw Exception(
          'You need to open LedgerTransportHidapi before sending data!');
    }
    if (_device == null) {
      throw Exception(
          'Bad state in Transport, device must not be null for an opened Transport!');
    }
    if (data.isEmpty) {
      throw Exception('Cannot send empty data!');
    }
    print('=> ${hex.encode(data)}');

    // first, add length (2 bytes) before the data
    var bufferData = WriteBuffer();
    bufferData.putUint16(data.length, endian: Endian.big);
    bufferData.putUint8List(data);
    final doneData = bufferData.done();
    data = doneData.buffer.asUint8List(0, doneData.lengthInBytes);

    int seqIdx = 0; // big endian
    int offset = 0;
    int length = 0;

    const kHeaderSize = 5;
    const kBlockSize = kPackageSize - kHeaderSize; // 59

    while (offset < data.length) {
      // Header: channel (0x0101), tag (0x05), sequence index (2 bytes)
      var bufferHeader = WriteBuffer();
      bufferHeader.putUint8(kChannelByte1);
      bufferHeader.putUint8(kChannelByte2);
      bufferHeader.putUint8(kTag);
      bufferHeader.putUint16(seqIdx, endian: Endian.big);
      final doneHeader = bufferHeader.done();
      Uint8List header = doneHeader.buffer
          .asUint8List(0, doneHeader.lengthInBytes); // length = 5
      assert(header.length == kHeaderSize);

      int remainBytes = data.length - offset;
      int bytesInThisPackage = min(remainBytes, kBlockSize);
      int paddingSize = kBlockSize - bytesInThisPackage;
      Uint8List dataInThisPackage =
          Uint8List.sublistView(data, offset, offset + bytesInThisPackage);
      Uint8List paddingInThisPackage =
          Uint8List.fromList(List.filled(paddingSize, 0));
      Uint8List dataChunk = Uint8List.fromList([
        ...header,
        ...dataInThisPackage,
        ...paddingInThisPackage,
      ]);
      assert(dataChunk.length == kPackageSize);

      //print('dataChunk = ${hex.encode(dataChunk)}');

      int wrote = _device!.hidWrite(Uint8List.fromList([0x00, ...dataChunk]));
      if (wrote < 0) {
        String msg = _appendErrorMessage(
            'Cannot send data to your Ledger!  $kErrorHelp');
        throw Exception(msg);
      }
      // make sure that wrote should equal (dataChunk.length + 1)
      if (wrote != dataChunk.length + 1) {
        throw Exception(
            'Expect wrote ${dataChunk.length + 1} but only $wrote bytes written to Ledger!');
      }

      seqIdx += 1;
      offset += kBlockSize;
      length += dataChunk.length + 1;
    }

    return length;
  }

  /// Blocking IO.
  LedgerTransportResult _receive() {
    if (_isOpen == false) {
      throw Exception(
          'You need to open LedgerTransportHidapi before receiving data!');
    }
    if (_device == null) {
      throw Exception(
          'Bad state in Transport, device must not be null for an opened Transport!');
    }

    int seqIdx = 0;
    _device!.hidSetNonblocking(false); // we need to check return value
    Uint8List? dataChunk = _device!.hidRead(kPackageSize + 1);
    _device!.hidSetNonblocking(true); // we need to check return value

    if (dataChunk == null) {
      String msg =
          _appendErrorMessage('Failed to read Ledger device!  $kErrorHelp');
      throw Exception(msg);
    }

    //print('receive() dataChunk = ${hex.encode(dataChunk)}');

    assert(dataChunk[0] == kChannelByte1,
        'Failed to assert channel (first byte)!');
    assert(dataChunk[1] == kChannelByte2,
        'Failed to assert channel (second byte)!');
    assert(dataChunk[2] == kTag, 'Failed to assert tag!');
    assert(
        dataChunk[3] == 0x00, 'Failed to assert sequence index (first byte)!');
    assert(dataChunk[4] == seqIdx,
        'Failed to assert sequence index (second byte)!');

    int dataLength = dataChunk.buffer.asByteData().getUint16(5, Endian.big);
    //print('dataLength = $dataLength');

    // dataLength must be at least 2 bytes because Status Word is 2 bytes
    if (dataLength < 2) {
      throw Exception(
          'The read data is not correct, expect minimum dataLength = 2 but we get value = $dataLength');
    }

    List<int> data = [];
    data.addAll(dataChunk.sublist(7));
    //print('data = ${hex.encode(data)}');

    while (data.length < dataLength) {
      seqIdx++;
      Uint8List? readBytes = _device!.hidReadTimeout(kPackageSize + 1, 1000);
      if (readBytes == null) {
        String msg = _appendErrorMessage(
            'Failed to read Ledger device for seq_idx = $seqIdx !  $kErrorHelp');
        throw Exception(msg);
      }
      assert(readBytes[0] == kChannelByte1,
          'Failed to assert channel (first byte)!');
      assert(readBytes[1] == kChannelByte2,
          'Failed to assert channel (second byte)!');
      assert(readBytes[2] == kTag, 'Failed to assert tag!');
      assert(readBytes[3] == 0x00,
          'Failed to assert sequence index (first byte)!');
      assert(readBytes[4] == seqIdx,
          'Failed to assert sequence index (second byte)!');

      //print('For seqIdx = $seqIdx readBytes = ${hex.encode(readBytes)}');
      data.addAll(readBytes.sublist(5));
    }

    int sw = Uint8List.fromList(data)
        .buffer
        .asByteData()
        .getUint16(dataLength - 2, Endian.big);
    Uint8List rdata = Uint8List.fromList(data.sublist(0, dataLength - 2));

    print('<= ${hex.encode(rdata)} ${sw.toRadixString(16)}');

    return LedgerTransportResult(
      statusWord: sw,
      data: rdata,
    );
  }

  LedgerTransportResult _exchange(Uint8List data) {
    _send(data);
    return _receive();
  }

  @override
  List<int> get response {
    return ledgerTransportResult!.data;
  }

  @override
  String getLabelFromCode() {
    String labelResponse = '';
    String blockParsedHex = hex.encode(ledgerTransportResult!.data);
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
    _open(0x1011);
    ledgerTransportResult = _exchange(apdu);
  }

  @override
  Future<void> disconnectLedger() async {
    _close();
  }
}
