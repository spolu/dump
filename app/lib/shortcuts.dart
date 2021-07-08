import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class nextEntryIntent extends Intent {}

final nextEntryKeySet = LogicalKeySet(
  LogicalKeyboardKey.keyJ,
);

class prevEntryIntent extends Intent {}

final prevEntryKeySet = LogicalKeySet(
  LogicalKeyboardKey.keyK,
);

class createEntryIntent extends Intent {}

final createEntryKeySet = LogicalKeySet(
  LogicalKeyboardKey.keyC,
);

class searchIntent extends Intent {}

final searchKeySet = LogicalKeySet(
  LogicalKeyboardKey.slash,
);
