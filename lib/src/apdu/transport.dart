// Dart imports:
import 'dart:typed_data';

Uint8List transport(
  int cla,
  int ins,
  int p1,
  int p2, [
  Uint8List? payload,
]) {
  payload ??= Uint8List.fromList([]);
  return Uint8List.fromList([cla, ins, p1, p2, ...payload]);
}
