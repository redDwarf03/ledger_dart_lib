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
    var mode = ThemeMode.light;

    return MaterialApp(
      title: 'Ledger Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.from(colorScheme: const ColorScheme.light()),
      darkTheme: ThemeData.from(colorScheme: const ColorScheme.dark()),
      themeMode: mode,
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
          Uint8List.fromList(sl.get<LedgerNanoSImpl>().response)
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

      labelResponse = sl.get<LedgerNanoSImpl>().getLabelFromCode();
      response = name + ' ' + version;
    });
  }

  @override
  void initState() {
    super.initState();
    sl<LedgerNanoSImpl>().addListener(update);
  }

  @override
  void dispose() {
    super.dispose();
    sl<LedgerNanoSImpl>().removeListener(update);
    sl.get<LedgerNanoSImpl>().disconnectLedger();
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
            const SizedBox(
              height: 10,
            ),
            ElevatedButton(
                child: const Text(
                  'get App And Version From Nano S',
                ),
                onPressed: () async {
                  await sl
                      .get<LedgerNanoSImpl>()
                      .connectLedger(getAppAndVersion);
                }),
            const SizedBox(
              height: 10,
            ),
            response != ''
                ? const Text(
                    'Response',
                  )
                : const SizedBox(),
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
