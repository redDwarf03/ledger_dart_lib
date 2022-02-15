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

/// Package Ledger aims to provide a easy way to communicate with Ledger devices.
library ledger;

export 'src/platform_impl/stub_ledger_nano_s.dart'
    if (dart.library.html) 'src/platform_impl/web_ledger_nano_s.dart';
export 'src/apdu/transport.dart';
export 'src/apdu/get_app_and_version.dart';
export 'src/apdu/get_app_version.dart';
