import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ledger_dart_lib/ledger_dart_lib.dart';
import 'package:ledget_dart_lib_example/service_locator.dart';

void main() {
  setupServiceLocator();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ledger Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Ledger Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String response = '';
  String labelResponse = '';

  void update() {
    setState(() {
      var readBuffer = ReadBuffer(
          Uint8List.fromList(sl.get<LedgerNanoSModel>().response)
              .buffer
              .asByteData());
      if (readBuffer.getUint8() != 1) {
        throw ArgumentError('format');
      }
      int nameLength = readBuffer.getUint8();
      String name = String.fromCharCodes(readBuffer.getUint8List(nameLength));
      int versionLength = readBuffer.getUint8();
      String version =
          String.fromCharCodes(readBuffer.getUint8List(versionLength));

      labelResponse = sl.get<LedgerNanoSModel>().getLabelFromCode();
      response = name + ' ' + version;
    });
  }

  @override
  void initState() {
    super.initState();
    sl<LedgerNanoSModel>().addListener(update);
  }

  @override
  void dispose() {
    super.dispose();
    sl<LedgerNanoSModel>().removeListener(update);
    sl.get<LedgerNanoSModel>().disconnectLedger();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          children: <Widget>[
            ElevatedButton(
                child: const Text(
                  'getAppAndVersion',
                ),
                onPressed: () async {
                  await sl
                      .get<LedgerNanoSModel>()
                      .connectLedger(getAppAndVersion);
                }),
            const Text(
              'Response',
            ),
            const SizedBox(
              height: 10,
            ),
            Padding(
              padding: const EdgeInsets.only(right: 10.0, left: 10.0),
              child: SelectableText(
                response,
              ),
            ),
            SelectableText(
              labelResponse,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
