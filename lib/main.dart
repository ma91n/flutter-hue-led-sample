import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Hue LED',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
      ),
      home: const MyPage(title: 'Flutter Hue LED'),
    );
  }
}

class MyPage extends StatefulWidget {
  const MyPage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  var _deviceName = "";
  var _onOff = true;
  var _color = false;
  var _temperature = false;
  var _brightness = false;

  @override
  void initState() {
    super.initState();

    Future(() async {
      var ble = FlutterReactiveBle();
      var device = await FlutterReactiveBle().scanForDevices(withServices: [], scanMode: ScanMode.lowLatency).firstWhere((device) => device.name == "Hue Lamp");

      print('Device: ${device.toString()}');
      _deviceName = device.name;

      ble.connectToDevice(id: device.id, servicesWithCharacteristicsToDiscover: {}, connectionTimeout: const Duration(seconds: 2)).listen((state) async {
        print('State: ${state.toString()}');

        if (state.connectionState == DeviceConnectionState.connected) {
          var services = await ble.discoverServices(device.id);
          var service = services;
          print('Service: ${service.toString()}');

          for (int i = 0;; i++) {
            print('START: QualifiedCharacteristic');

            if (_color) {
              const colors = [
                // RGB color
                [1, 1, 1],
                [128, 51, 51],
                [128, 128, 51],
                [51, 128, 51],
                [51, 128, 128],
                [128, 70, 70]
              ];
              final colorControl = QualifiedCharacteristic(
                  serviceId: Uuid.parse("932c32bd-0000-47a2-835a-a8d455b859dd"), characteristicId: Uuid.parse("932c32bd-0005-47a2-835a-a8d455b859dd"), deviceId: device.id);
              await ble.writeCharacteristicWithoutResponse(colorControl, value: [1, ...colors[i % 5]]);
            } else if (_onOff) {
              final lightControl = QualifiedCharacteristic(
                  serviceId: Uuid.parse("932c32bd-0000-47a2-835a-a8d455b859dd"), characteristicId: Uuid.parse("932c32bd-0002-47a2-835a-a8d455b859dd"), deviceId: device.id);
              await ble.writeCharacteristicWithoutResponse(lightControl, value: [i % 2]);
            } else if (_temperature) {
              // Index ranges from 153 (bluest) to 454 (bluest), or 500 on some models
              final temperatureControl = QualifiedCharacteristic(
                  serviceId: Uuid.parse("932c32bd-0000-47a2-835a-a8d455b859dd"), characteristicId: Uuid.parse("932c32bd-0004-47a2-835a-a8d455b859dd"), deviceId: device.id);
              await ble.writeCharacteristicWithoutResponse(temperatureControl, value: [50, i % 255]); // sample value
            } else if (_brightness) {
              final brightnessControl = QualifiedCharacteristic(
                  serviceId: Uuid.parse("932c32bd-0000-47a2-835a-a8d455b859dd"), characteristicId: Uuid.parse("932c32bd-0003-47a2-835a-a8d455b859dd"), deviceId: device.id);
              await ble.writeCharacteristicWithoutResponse(brightnessControl, value: [i % 2 == 0 ? 1 : 254]); // 1~254
            }

            await Future.delayed(const Duration(seconds: 2));
          }
        }
      }, onError: (dynamic error) {
        print(error.toString());
      });
    });
  }

  Future<void> _connect() async {
    _onOff = true;
    _color = false;
    _temperature = false;
    _brightness = false;
  }

  Future<void> _play() async {
    _onOff = false;
    _color = true;
    _temperature = false;
    _brightness = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'デバイス名',
            ),
            Text(_deviceName, style: Theme.of(context).textTheme.headline4),
            FloatingActionButton(
              onPressed: _connect,
              tooltip: 'Lチカ',
              child: const Icon(Icons.light),
            ),
            FloatingActionButton(
              onPressed: _play,
              tooltip: 'ダンス',
              child: const Icon(Icons.play_arrow),
            ),
          ],
        ),
      ),
    );
  }
}
