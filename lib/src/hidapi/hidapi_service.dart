import 'dart:typed_data';

import 'package:flutter/foundation.dart';

class HidapiVersion {
  int major;
  int minor;
  int patch;
  HidapiVersion({
    required this.major,
    required this.minor,
    required this.patch,
  });
}

abstract class HidapiService {
  int hidInit() {
    throw UnimplementedError();
  }

  int hidExit() {
    throw UnimplementedError();
  }

  List<HidapiDevice> hidEnumerate({
    int vendorId = 0,
    int productId = 0,
  }) {
    throw UnimplementedError();
  }

  HidapiVersion hidVersion() {
    throw UnimplementedError();
  }

  String hidVersionStr() {
    throw UnimplementedError();
  }
}

abstract class HidapiDevice {
  /// Platform-specific device path
  String path;

  /// Device Vendor ID
  int vendorId;

  /// Device Product ID
  int productId;

  /// Serial Number
  String serialNumber;

  /// Device Release Number in binary-coded decimal,
  ///    also known as Device Version Number
  int releaseNumber;

  /// Manufacturer String
  String manufacturerString;

  /// Product String
  String productString;

  /// Usage Page for this Device/Interface
  ///    (Windows/Mac/hidraw only)
  int usagePage;

  /// Usage for this Device/Interface
  ///    (Windows/Mac/hidraw only)
  int usage;

  /// The USB interface which this logical device represents.
  /// Valid on both Linux implementations in all cases.
  /// Valid on the Windows implementation only if the device
  /// contains more than one interface.
  /// Valid on the Mac implementation if and only if the device
  /// is a USB HID device. */
  int interfaceNumber;

  HidapiDevice({
    required this.path,
    required this.vendorId,
    required this.productId,
    required this.serialNumber,
    required this.releaseNumber,
    required this.manufacturerString,
    required this.productString,
    required this.usagePage,
    required this.usage,
    required this.interfaceNumber,
  });

  void printDebugInfo() {
    if (kDebugMode) {
      print('''HidapiDevice Info
           vendorId = $vendorId productId = $productId
           path: $path
           serial_number: $serialNumber
           Manufacturer:  $manufacturerString
           Product:       $productString
           Release:       $releaseNumber
           Interface:     $interfaceNumber
           Usage (page):  $usage ($usagePage)''');
    }
  }

  bool hidOpen() {
    throw UnimplementedError();
  }

  bool hidOpenPath() {
    throw UnimplementedError();
  }

  int hidWrite(Uint8List data) {
    throw UnimplementedError();
  }

  Uint8List? hidReadTimeout(int length, int milliseconds) {
    throw UnimplementedError();
  }

  Uint8List? hidRead(int length) {
    throw UnimplementedError();
  }

  int hidSetNonblocking(bool nonblock) {
    throw UnimplementedError();
  }

  int hidSendFeatureReport(Uint8List data) {
    throw UnimplementedError();
  }

  Uint8List? hidGetFeatureReport(int length) {
    throw UnimplementedError();
  }

  Uint8List? hidGetInputReport(int length) {
    throw UnimplementedError();
  }

  void hidClose() {
    throw UnimplementedError();
  }

  String? hidGetManufacturerString(int maxlen) {
    throw UnimplementedError();
  }

  String? hidGetProductString(int maxlen) {
    throw UnimplementedError();
  }

  String? hidGetSerialNumberString(int maxlen) {
    throw UnimplementedError();
  }

  /// return null on error
  String? hidGetIndexedString(int stringIndex, int maxlen) {
    throw UnimplementedError();
  }

  String? hidError() {
    throw UnimplementedError();
  }

  HidapiVersion hidVersion() {
    throw UnimplementedError();
  }

  String hidVersionStr() {
    throw UnimplementedError();
  }
}
