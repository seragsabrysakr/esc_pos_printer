import 'dart:async';
import 'dart:developer';

import 'package:flutter_pos_printer_platform_image_3/flutter_pos_printer_platform_image_3.dart';

class WindowsPrintingUsb {
  WindowsPrintingUsb._() {
    _initSubscription();
    _scan();
  }
  static final sharedInstance = WindowsPrintingUsb._();

  final printerManager = PrinterManager.instance;
  var _isBle = false;
  var _reconnect = false;
  bool _isConnected = false;

  var defaultPrinterType = PrinterType.usb;
  StreamSubscription<PrinterDevice>? _subscription;
  StreamSubscription<USBStatus>? _subscriptionUsbStatus;
  USBStatus _currentUsbStatus = USBStatus.none;
  List<Printer> devices = [];
  Printer? selectedPrinter;

  void _initSubscription() {
    _subscription?.cancel();
    _subscriptionUsbStatus?.cancel();
    _subscriptionUsbStatus = PrinterManager.instance.stateUSB.listen((status) {
      log(' ----------------- status usb $status ------------------ ');
      _currentUsbStatus = status;
    });
  }

  void _scan() {
    devices.clear();
    _subscription = printerManager.discovery(type: defaultPrinterType, isBle: _isBle).listen((device) {
      devices.add(Printer(
        deviceName: device.name,
        address: device.address,
        isBle: _isBle,
        vendorId: device.vendorId,
        productId: device.productId,
        typePrinter: defaultPrinterType,
      ));
    });
  }

  void selectDevice(Printer device) async {
    if (selectedPrinter != null) {
      if ((device.address != selectedPrinter!.address) || (device.typePrinter == PrinterType.usb && selectedPrinter!.vendorId != device.vendorId)) {
        await PrinterManager.instance.disconnect(type: selectedPrinter!.typePrinter);
      }
    }

    selectedPrinter = device;
  }

  void _connectDevice() async {
    _isConnected = false;
    if (selectedPrinter == null) {
      return null;
    }
    await printerManager.connect(
        type: selectedPrinter!.typePrinter,
        model: UsbPrinterInput(name: selectedPrinter!.deviceName, productId: selectedPrinter!.productId, vendorId: selectedPrinter!.vendorId));
    _isConnected = true;
  }

  void _sendBytesToPrint(List<int> bytes, PrinterType type) async {
    printerManager.send(type: type, bytes: bytes);
  }
}

class Printer {
  Printer(
      {this.deviceName,
      this.address,
      this.port,
      this.state,
      this.vendorId,
      this.productId,
      this.typePrinter = PrinterType.bluetooth,
      this.isBle = false});
  int? id;
  String? deviceName;
  String? address;
  String? port;
  String? vendorId;
  String? productId;
  bool? isBle;

  PrinterType typePrinter;
  bool? state;
}
