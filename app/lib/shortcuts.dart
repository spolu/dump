import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NextEntryIntent extends Intent {}

final nextEntryKeySet = LogicalKeySet(
  LogicalKeyboardKey.keyJ,
);
final nextEntryKeySetDown = LogicalKeySet(
  LogicalKeyboardKey.arrowDown,
);

class PrevEntryIntent extends Intent {}

final prevEntryKeySet = LogicalKeySet(
  LogicalKeyboardKey.keyK,
);
final prevEntryKeySetUp = LogicalKeySet(
  LogicalKeyboardKey.arrowUp,
);

class CreateEntryIntent extends Intent {}

final createEntryKeySet = LogicalKeySet(
  LogicalKeyboardKey.keyC,
);

class DeleteEntryIntent extends Intent {}

final deleteEntryKeySet = LogicalKeySet(
  LogicalKeyboardKey.keyD,
);

class SearchIntent extends Intent {}

final searchKeySet = LogicalKeySet(
  LogicalKeyboardKey.slash,
);
