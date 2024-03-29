import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'entry_edit.dart';
import 'models.dart';
import 'shortcuts.dart';

import 'dart:developer';

class EntryItem extends StatefulWidget {
  EntryItem(
      {required this.entry,
      required this.searchQuery,
      required this.onEntryUpdate,
      required this.onFocus,
      required this.selected})
      : super(key: ObjectKey(entry.id));

  final Entry entry;
  final String searchQuery;
  final Function(Entry) onEntryUpdate;
  final Function() onFocus;
  final bool selected;

  @override
  _EntryItemState createState() => _EntryItemState();
}

class _EntryItemState extends State<EntryItem> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        this.widget.onFocus();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(EntryItem oldWidget) {
    if (widget.selected != oldWidget.selected) {
      if (widget.selected) {
        if (!_focusNode.hasFocus) {
          _focusNode.requestFocus();
        }
      }
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.transparent,
      margin: EdgeInsets.symmetric(vertical: 5.0),
      child: InkWell(
        focusNode: _focusNode,
        focusColor: Colors.transparent,
        onTap: () {
          showDialog(
              context: context,
              builder: (_context) {
                var state = Provider.of<JournalState>(context, listen: false);
                return EntryEdit(
                    entry: this.widget.entry,
                    onUpdate: (Entry e) {
                      e.update().then((e) {
                        this.widget.onEntryUpdate(e);
                        state.updateStreams();
                      });
                    },
                    onDelete: (Entry e) {
                      e.delete().then((e) {
                        this.widget.onEntryUpdate(e);
                      });
                    });
              });
        },
        child: Padding(
          padding: EdgeInsets.all(0.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              SizedBox(
                width: 10.0,
              ),
              Expanded(
                child: Text(this.widget.entry.title,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontSize: 13.0,
                      fontWeight: FontWeight.w800,
                      color: _focusNode.hasFocus
                          ? Colors.purple[800]
                          : Theme.of(context).colorScheme.onBackground,
                    )),
              ),
              SizedBox(
                width: 5.0,
              ),
              Container(
                child: Row(children: <Widget>[
                  for (var s in this
                      .widget
                      .entry
                      .streamNamesNotInQuery(this.widget.searchQuery))
                    Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2.0),
                        padding: const EdgeInsets.all(1.0),
                        decoration: BoxDecoration(
                          border:
                              Border.all(color: Colors.grey[400]!, width: 1.0),
                          borderRadius: BorderRadius.circular(3.0),
                        ),
                        child: Text(s,
                            style: TextStyle(
                                fontSize: 11.0,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[500])))
                ]),
              ),
              SizedBox(
                width: 5.0,
              ),
              // Expanded(
              //   // child: Text(this.widget.entry.body.replaceAll('\n', ' '),
              //   child: Text('',
              //       overflow: TextOverflow.ellipsis,
              //       textAlign: TextAlign.left,
              //       style: TextStyle(
              //         fontSize: 13.0,
              //         fontWeight: FontWeight.w200,
              //         color: Colors.grey,
              //       )),
              // ),
              SizedBox(
                width: 2.0,
              ),
              Text(
                DateFormat.MMMd().format(DateTime.fromMillisecondsSinceEpoch(
                    this.widget.entry.created * 1000)),
                style: TextStyle(
                  fontSize: 11.0,
                ),
              ),
              SizedBox(
                width: 2.0,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EntryLog extends StatefulWidget {
  EntryLog({required this.searchQuery, required this.onSearchRequested})
      : super();

  final String searchQuery;
  final Function() onSearchRequested;

  @override
  _EntryLogState createState() => _EntryLogState();
}

class _EntryLogState extends State<EntryLog> {
  List<Entry> _entries = [];
  int _total = 0;
  int _selected = -1;

  @override
  initState() {
    super.initState();
    Future<EntryList> future = EntryList.fetch(0, 100, this.widget.searchQuery);
    future.then((EntryList data) {
      _total = data.total;
      _entries.addAll(data.entries);
    });
  }

  @override
  void didUpdateWidget(EntryLog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchQuery != oldWidget.searchQuery) {
      _refresh(true);
    }
  }

  void _refresh(bool resetSelected) {
    Future<EntryList> future = EntryList.fetch(0, 100, this.widget.searchQuery);
    future.then((EntryList data) {
      setState(() {
        _total = data.total;
        _entries = data.entries;
        if (!resetSelected) {
          if (_selected >= data.entries.length) {
            _selected = data.entries.length - 1;
          }
        } else {
          _selected = -1;
        }
      });
    });
  }

  void _createEntry(context) {
    Entry.create(Provider.of<JournalState>(context, listen: false)
            .streamsFromMetaOrQuery(
                Provider.of<JournalState>(context, listen: false).query()))
        .then((entry) {
      showDialog(
          context: context,
          builder: (_context) {
            var state = Provider.of<JournalState>(context, listen: false);
            return EntryEdit(
                entry: entry,
                onUpdate: (Entry e) {
                  e.update().then((value) {
                    _refresh(false);
                    state.updateStreams();
                  });
                },
                onDelete: (Entry e) {
                  e.delete().then((value) {
                    _refresh(false);
                  });
                });
          });
    });
  }

  Widget _itemBuilder(BuildContext context, int index) {
    if (index < _entries.length) {
      return EntryItem(
          entry: _entries[index],
          searchQuery: this.widget.searchQuery,
          onEntryUpdate: (e) {
            _refresh(false);
          },
          onFocus: () {
            setState(() {
              _selected = index;
            });
          },
          selected: index == _selected);
    } else {
      return FutureBuilder(
        future: EntryList.fetch(_entries.length, 10, this.widget.searchQuery),
        builder: (BuildContext context, AsyncSnapshot<EntryList> snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}',
                    style: TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold));
              }
              _entries.addAll(snapshot.data!.entries);
              _total = snapshot.data!.total;
              Future.microtask(() {
                setState(() {});
              });
              return Container(
                alignment: Alignment.center,
                height: 10.0,
                child: Text('...'),
              );
            default:
              return Container(
                alignment: Alignment.center,
                height: 10.0,
                child: Text('...'),
              );
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        nextEntryKeySet: NextEntryIntent(),
        nextEntryKeySetDown: NextEntryIntent(),
        prevEntryKeySet: PrevEntryIntent(),
        prevEntryKeySetUp: PrevEntryIntent(),
        createEntryKeySet: CreateEntryIntent(),
        deleteEntryKeySet: DeleteEntryIntent(),
        searchKeySet: SearchIntent(),
      },
      child: Actions(
        actions: {
          PrevEntryIntent: CallbackAction(onInvoke: (e) {
            setState(() {
              if (_selected > 0) {
                _selected -= 1;
              }
            });
          }),
          NextEntryIntent: CallbackAction(onInvoke: (e) {
            setState(() {
              if (_selected < _entries.length - 1) {
                _selected += 1;
              }
            });
          }),
          CreateEntryIntent: CallbackAction(onInvoke: (e) {
            _createEntry(context);
          }),
          DeleteEntryIntent: CallbackAction(onInvoke: (e) {
            _entries[_selected].delete().then((entry) {
              _refresh(false);
            });
          }),
          SearchIntent: CallbackAction(onInvoke: (e) {
            setState(() {
              _selected = -1;
            });
            this.widget.onSearchRequested();
          }),
        },
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            width: 20.0,
          ),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                _createEntry(context);
              },
              child: Container(
                padding: const EdgeInsets.only(top: 3.0),
                child: Icon(
                  Icons.add,
                  size: 18,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(
                  left: 2.0, right: 16.0, bottom: 16.0, top: 0.0),
              itemBuilder: _itemBuilder,
              itemCount: _total,
            ),
          ),
        ]),
      ),
    );
  }
}

class SearchBox extends StatefulWidget {
  SearchBox(
      {required this.searchQuery,
      required this.onUpdate,
      required this.onMenu,
      required this.searchFocusNode})
      : super();

  final String searchQuery;
  final Function(String) onUpdate;
  final Function() onMenu;
  final FocusNode searchFocusNode;

  @override
  _SearchBoxState createState() => _SearchBoxState();
}

class _SearchBoxState extends State<SearchBox> {
  final _searchController = TextEditingController();

  void _handleTextControllerUpdate() {
    scheduleMicrotask(() => widget.onUpdate(_searchController.text));
  }

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.searchQuery;
    _searchController.addListener(_handleTextControllerUpdate);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(SearchBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchQuery != _searchController.text) {
      _searchController.removeListener(_handleTextControllerUpdate);
      _searchController.text = widget.searchQuery;
      _searchController.addListener(_handleTextControllerUpdate);
      if (!this.widget.searchFocusNode.hasFocus) {
        this.widget.searchFocusNode.requestFocus();
        _searchController.selection = TextSelection.fromPosition(
            TextPosition(offset: _searchController.text.length));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isHandset = MediaQuery.of(context).size.width < 600;
    // create a search box with a search icon on the left and round corners
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
      ),
      margin: EdgeInsets.all(10),
      child: Row(
        children: isHandset
            ? _buildHandsetChildren(context)
            : _buildNormalChildren(context),
      ),
    );
  }

  List<Widget> _buildNormalChildren(BuildContext context) {
    return [
      Container(
        padding: const EdgeInsets.only(top: 2.0),
        child: Icon(
          Icons.search,
          size: 18,
        ),
      ),
      Expanded(
        child: TextField(
          autofocus: true,
          focusNode: this.widget.searchFocusNode,
          keyboardType: TextInputType.text,
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 0.0, horizontal: 10.0),
          ),
          controller: _searchController,
          style: TextStyle(
              fontSize: 13.0, fontWeight: FontWeight.w900, color: Colors.grey),
        ),
      ),
    ];
  }

  List<Widget> _buildHandsetChildren(BuildContext context) {
    var children = _buildNormalChildren(context);
    children.insert(
      0,
      MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => this.widget.onMenu(),
          child: Container(
            padding: const EdgeInsets.only(bottom: 1.0),
            child: Icon(
              Icons.menu_open,
              size: 18,
            ),
          ),
        ),
      ),
    );
    children.insert(
      1,
      SizedBox(
        width: 10.0,
      ),
    );
    return children;
  }
}

class Journal extends StatefulWidget {
  Journal({
    required this.onMenu,
  }) : super();

  final Function() onMenu;

  @override
  _JournalState createState() => _JournalState();
}

class _JournalState extends State<Journal> {
  late FocusNode _searchFocusNode;

  @override
  void initState() {
    super.initState();
    _searchFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
      ),
      child: Consumer<JournalState>(
        builder: (context, state, child) => Column(
          children: [
            SearchBox(
              searchQuery: state.query(),
              searchFocusNode: _searchFocusNode,
              onMenu: () => this.widget.onMenu(),
              onUpdate: (query) {
                state.updateQuery(query);
              },
            ),
            Expanded(
                child: EntryLog(
              searchQuery: state.query(),
              onSearchRequested: () {
                _searchFocusNode.requestFocus();
              },
            )),
          ],
        ),
      ),
    );
  }
}
