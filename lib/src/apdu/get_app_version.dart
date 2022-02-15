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

// Project imports:
import 'package:ledger_dart_lib/src/apdu/transport.dart';

final getAppVersion = transport(0xe0, 0x01, 0x00, 0x00);
