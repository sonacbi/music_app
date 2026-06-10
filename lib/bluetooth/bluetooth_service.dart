import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
enum BluetoothStatus {
  disconnected,
  connecting,
  connected,
}
class BluetoothService {
  BluetoothConnection? _connection;

  final StreamController<BluetoothStatus> _statusController =
      StreamController<BluetoothStatus>.broadcast();

  Stream<BluetoothStatus> get statusStream => _statusController.stream;

  BluetoothStatus _status = BluetoothStatus.disconnected;

  bool get isConnected =>
      _status == BluetoothStatus.connected && _connection != null;

  Future<List<BluetoothDevice>> getBondedDevices() async {
    return await FlutterBluetoothSerial.instance.getBondedDevices();
  }

  Future<void> connect(BluetoothDevice device) async {
    _status = BluetoothStatus.connecting;
    _statusController.add(_status);

    try {
      _connection =
          await BluetoothConnection.toAddress(device.address);

      _status = BluetoothStatus.connected;
      _statusController.add(_status);

      _connection!.input!.listen((data) {
        print("RX: $data");
      });

    } catch (e) {
      _status = BluetoothStatus.disconnected;
      _statusController.add(_status);
      print("CONNECT ERROR: $e");
    }
  }

  void send(int value) {
    if (isConnected) {
      _connection!.output.add(Uint8List.fromList([value]));
    }
  }

  void disconnect() {
    _connection?.dispose();
    _connection = null;

    _status = BluetoothStatus.disconnected;
    _statusController.add(_status);
  }

  BluetoothStatus get currentStatus => _status;
}