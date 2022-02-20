import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'hidapi_service.dart';
import 'package:hid_macos/generated_bindings.dart';

final _api = Api(DynamicLibrary.executable());

class HidapiServiceMac extends HidapiService {
  @override
  int hidInit() {
    return _api.init();
  }

  @override
  int hidExit() {
    return _api.exit();
  }

  @override
  List<HidapiDevice> hidEnumerate({
    int vendorId = 0,
    int productId = 0,
  }) {
    List<HidapiDeviceMac> devices = [];
    final pointer = _api.enumerate(vendorId, productId);
    print('pointer = $pointer');
    var current = pointer;
    while (current.address != nullptr.address) {
      final ref = current.ref;
      devices.add(HidapiDeviceMac(
        path: ref.path.toDartString(),
        vendorId: ref.vendor_id,
        productId: ref.product_id,
        serialNumber: ref.serial_number.toDartString(),
        releaseNumber: ref.release_number,
        manufacturerString: ref.manufacturer_string.toDartString(),
        productString: ref.product_string.toDartString(),
        usagePage: ref.usage_page,
        usage: ref.usage,
        interfaceNumber: ref.interface_number,
      ));
      current = ref.next;
    }
    _api.free_enumeration(pointer);
    return devices;
  }

  @override
  HidapiVersion hidVersion() {
    Pointer<hid_api_version> version = _api.version();
    HidapiVersion hidapiVersion = HidapiVersion(
      major: version.ref.major,
      minor: version.ref.minor,
      patch: version.ref.patch,
    );
    return hidapiVersion;
  }

  @override
  String hidVersionStr() {
    return _api.version_str().toDartString();
  }
}

class HidapiDeviceMac extends HidapiDevice {
  bool _isOpen = false;
  Pointer<hid_device> _device = nullptr;

  HidapiDeviceMac({
    required String path,
    required int vendorId,
    required int productId,
    required String serialNumber,
    required int releaseNumber,
    required String manufacturerString,
    required String productString,
    required int usagePage,
    required int usage,
    required int interfaceNumber,
  }) : super(
          path: path,
          vendorId: vendorId,
          productId: productId,
          serialNumber: serialNumber,
          releaseNumber: releaseNumber,
          manufacturerString: manufacturerString,
          productString: productString,
          usagePage: usagePage,
          usage: usage,
          interfaceNumber: interfaceNumber,
        );

  void _makeSureDeviceOpened() {
    if (_isOpen == false) {
      throw Exception(
          'Operation is not allowed because this device is not open yet.');
    }
  }

  @override
  bool hidOpen() {
    if (_isOpen) {
      throw Exception('This device is already opened, cannot open it again!');
    }
    Pointer<Int32> pSerial = serialNumber.toPointer();
    _device = _api.open(vendorId, productId, pSerial);
    malloc.free(pSerial);
    if (_device.address == nullptr.address) {
      return false;
    }
    _isOpen = true;
    return true;
  }

  @override
  bool hidOpenPath() {
    if (_isOpen) {
      throw Exception('This device is already opened, cannot open it again!');
    }
    Pointer<Int8> pPath = path.toNativeUtf8().cast();
    _device = _api.open_path(pPath);
    malloc.free(pPath);
    if (_device.address == nullptr.address) {
      return false;
    }
    _isOpen = true;
    return true;
  }

  @override
  int hidWrite(Uint8List data) {
    _makeSureDeviceOpened();
    int dataLength = data.lengthInBytes;
    final buf = calloc<Uint8>(dataLength);
    buf.asTypedList(dataLength).setRange(0, dataLength, data);
    int result = _api.write(_device, buf, dataLength);
    calloc.free(buf);
    return result;
  }

  @override
  Uint8List? hidReadTimeout(int length, int milliseconds) {
    _makeSureDeviceOpened();
    Uint8List? result;
    final buf = calloc<Uint8>(length);
    int count = _api.read_timeout(_device, buf, length, milliseconds);
    if (count > 0) {
      // we must use Uint8List.fromList() to copy data
      result = Uint8List.fromList(buf.asTypedList(count));
    }
    calloc.free(buf);

    if (count == -1) {
      return null; // error
    }
    if (count == 0) {
      return Uint8List.fromList([]);
    }
    return result;
  }

  @override
  Uint8List? hidRead(int length) {
    _makeSureDeviceOpened();
    Uint8List? result;
    final buf = calloc<Uint8>(length);
    int count = _api.read(_device, buf, length);
    if (count > 0) {
      // we must use Uint8List.fromList() to copy data
      result = Uint8List.fromList(buf.asTypedList(count));
    }
    calloc.free(buf);

    if (count == -1) {
      return null; // error
    }
    if (count == 0) {
      return Uint8List.fromList([]);
    }
    return result;
  }

  @override
  int hidSetNonblocking(bool nonblock) {
    _makeSureDeviceOpened();
    return _api.set_nonblocking(_device, nonblock ? 1 : 0);
  }

  @override
  int hidSendFeatureReport(Uint8List data) {
    _makeSureDeviceOpened();
    int dataLength = data.lengthInBytes;
    final buf = calloc<Uint8>(dataLength);
    buf.asTypedList(dataLength).setRange(0, dataLength, data);
    int result = _api.send_feature_report(_device, buf, dataLength);
    calloc.free(buf);
    return result;
  }

  @override
  Uint8List? hidGetFeatureReport(int length) {
    _makeSureDeviceOpened();
    Uint8List? result;
    final buf = calloc<Uint8>(length);
    int count = _api.get_feature_report(_device, buf, length);
    if (count > 0) {
      // we must use Uint8List.fromList() to copy data
      result = Uint8List.fromList(buf.asTypedList(count));
    }
    calloc.free(buf);

    if (count == -1) {
      return null; // error
    }
    if (count == 0) {
      return Uint8List.fromList([]);
    }
    return result;
  }

  @override
  Uint8List? hidGetInputReport(int length) {
    _makeSureDeviceOpened();
    Uint8List? result;
    final buf = calloc<Uint8>(length);
    int count = _api.get_input_report(_device, buf, length);
    if (count > 0) {
      // we must use Uint8List.fromList() to copy data
      result = Uint8List.fromList(buf.asTypedList(count));
    }
    calloc.free(buf);

    if (count == -1) {
      return null; // error
    }
    if (count == 0) {
      return Uint8List.fromList([]);
    }
    return result;
  }

  @override
  void hidClose() {
    if (_isOpen) {
      _api.close(_device);
      _isOpen = false;
      _device = nullptr;
    }
  }

  @override
  String? hidGetManufacturerString(int maxlen) {
    _makeSureDeviceOpened();

    final buf = calloc<Int32>(maxlen);
    int retCode = _api.get_manufacturer_string(_device, buf, maxlen);

    // failed
    if (retCode != 0) {
      calloc.free(buf);
      return null;
    }

    // success
    String result = buf.toDartString();
    calloc.free(buf);
    return result;
  }

  @override
  String? hidGetProductString(int maxlen) {
    _makeSureDeviceOpened();

    final buf = calloc<Int32>(maxlen);
    int retCode = _api.get_product_string(_device, buf, maxlen);

    // failed
    if (retCode != 0) {
      calloc.free(buf);
      return null;
    }

    // success
    String result = buf.toDartString();
    calloc.free(buf);
    return result;
  }

  @override
  String? hidGetSerialNumberString(int maxlen) {
    _makeSureDeviceOpened();

    final buf = calloc<Int32>(maxlen);
    int retCode = _api.get_serial_number_string(_device, buf, maxlen);

    // failed
    if (retCode != 0) {
      calloc.free(buf);
      return null;
    }

    // success
    String result = buf.toDartString();
    calloc.free(buf);
    return result;
  }

  /// return null on error
  @override
  String? hidGetIndexedString(int stringIndex, int maxlen) {
    _makeSureDeviceOpened();

    // must use calloc to clear the memory, because macOS implementation
    // does not change the buf even it return 0 (success)
    final buf = calloc<Int32>(maxlen);
    int retCode = _api.get_indexed_string(_device, stringIndex, buf, maxlen);

    // failed
    if (retCode != 0) {
      calloc.free(buf);
      return null;
    }

    // success
    String result = buf.toDartString();
    calloc.free(buf);
    return result;
  }

  @override
  String? hidError() {
    final pError = _api.error(_device);
    if (pError.address == nullptr.address) {
      return null;
    }
    return pError.toDartString();
  }
}

extension PointerInt8ToString on Pointer<Int8> {
  String toDartString() {
    final buffer = StringBuffer();
    var i = 0;
    while (true) {
      final char = elementAt(i).value;
      if (char == 0) {
        return buffer.toString();
      }
      buffer.writeCharCode(char);
      i++;
    }
  }
}

extension PointerInt32ToString on Pointer<Int32> {
  String toDartString() {
    final buffer = StringBuffer();
    var i = 0;
    while (true) {
      final char = elementAt(i).value;
      if (char == 0) {
        return buffer.toString();
      }
      buffer.writeCharCode(char);
      i++;
    }
  }
}

extension StringToPointerInt32 on String {
  Pointer<Int32> toPointer({Allocator allocator = malloc}) {
    final units = codeUnits;
    final Pointer<Int32> result = allocator<Int32>(units.length + 1);
    final Int32List nativeString = result.asTypedList(units.length + 1);
    nativeString.setRange(0, units.length, units);
    nativeString[units.length] = 0;
    return result.cast();
  }
}
