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
import 'dart:typed_data';

// Flutter imports:
import 'package:flutter/foundation.dart';

abstract class AbstractLedgerNanoS extends ChangeNotifier {
  List<int> get response;

  String getLabelFromCode();

  Future<void> connectLedger(Uint8List apdu);

  Future<void> disconnectLedger();
}
