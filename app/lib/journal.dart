import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'entry_edit.dart';
import 'model.dart';
import 'shortcuts.dart';

class EntryItem extends StatefulWidget {
  EntryItem(
      {required this.entry,
      required this.searchText,
      required this.onUpdate,
      required this.onFocus,
      required this.selected})
      : super(key: ObjectKey(entry.id));

  final Entry entry;
  final String searchText;
  final Function(Entry) onUpdate;
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
    super.didUpdateWidget(oldWidget);
    if (widget.selected && !oldWidget.selected && widget.selected) {
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.transparent,
      // clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.symmetric(vertical: 5.0),
      child: InkWell(
        focusNode: _focusNode,
        focusColor: Colors.transparent,
        onTap: () {
          showDialog(
              context: context,
              builder: (context) {
                return EntryEdit(
                    entry: this.widget.entry,
                    onUpdate: (Entry e) {
                      e.update().then((value) {
                        this.widget.onUpdate(e);
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
              Text(this.widget.entry.title,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontSize: 13.0,
                    fontWeight: FontWeight.w800,
                    color: _focusNode.hasFocus
                        ? Colors.purple[800]
                        : Theme.of(context).colorScheme.onBackground,
                  )),
              SizedBox(
                width: 5.0,
              ),
              Flexible(
                child: Text(this.widget.entry.body.replaceAll('\n', ' '),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontSize: 13.0,
                      fontWeight: FontWeight.w200,
                      color: Colors.grey,
                    )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EntryLog extends StatefulWidget {
  EntryLog({required this.searchText, required this.onSearch}) : super();

  final String searchText;
  final Function() onSearch;

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
    Future<EntryList> future = EntryList.fetch(0, 10, this.widget.searchText);
    future.then((EntryList data) {
      _total = data.total;
      _entries.addAll(data.entries);
    });
  }

  void refresh() {
    setState(() {});
    Future<EntryList> future = EntryList.fetch(0, 10, this.widget.searchText);
    future.then((EntryList data) {
      setState(() {
        _selected = -1;
        _total = data.total;
        _entries = data.entries;
      });
    });
  }

  @override
  void didUpdateWidget(EntryLog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchText != oldWidget.searchText) {
      refresh();
    }
  }

  void handleEntryFocus(int index) {
    setState(() {
      _selected = index;
    });
  }

  Widget _itemBuilder(BuildContext context, int index) {
    if (index < _entries.length) {
      return EntryItem(
          entry: _entries[index],
          searchText: this.widget.searchText,
          onUpdate: (e) {
            setState(() {
              _entries[index] = e;
            });
          },
          onFocus: () {
            setState(() {
              _selected = index;
            });
          },
          selected: index == _selected);
    } else {
      return FutureBuilder(
        future: EntryList.fetch(_entries.length, 10, this.widget.searchText),
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
                child: CircularProgressIndicator(),
              );
            default:
              return Container(
                alignment: Alignment.center,
                height: 10.0,
                child: CircularProgressIndicator(),
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
        nextEntryKeySet: nextEntryIntent(),
        prevEntryKeySet: prevEntryIntent(),
        createEntryKeySet: createEntryIntent(),
        deleteEntryKeySet: deleteEntryIntent(),
        searchKeySet: searchIntent(),
      },
      child: Actions(
        actions: {
          prevEntryIntent: CallbackAction(onInvoke: (e) {
            setState(() {
              if (_selected > 0) {
                _selected -= 1;
              }
            });
          }),
          nextEntryIntent: CallbackAction(onInvoke: (e) {
            setState(() {
              if (_selected < _entries.length - 1) {
                _selected += 1;
              }
            });
          }),
          createEntryIntent: CallbackAction(onInvoke: (e) {
            Entry.create().then((entry) {
              showDialog(
                  context: context,
                  builder: (context) {
                    return EntryEdit(
                        entry: entry,
                        onUpdate: (Entry e) {
                          e.update().then((value) {
                            refresh();
                          });
                        });
                  });
            });
          }),
          deleteEntryIntent: CallbackAction(onInvoke: (e) {
            _entries[_selected].delete().then((entry) {
              refresh();
            });
          }),
          searchIntent: CallbackAction(onInvoke: (e) {
            setState(() {
              _selected = -1;
            });
            this.widget.onSearch();
          }),
        },
        child: ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemBuilder: _itemBuilder,
          itemCount: _total,
        ),
      ),
    );
  }
}

class SearchBox extends StatefulWidget {
  SearchBox(
      {required this.searchText,
      required this.onUpdate,
      required this.searchFocusNode})
      : super();

  final String searchText;
  final Function(String) onUpdate;
  final FocusNode searchFocusNode;

  @override
  _SearchBoxState createState() => _SearchBoxState();
}

class _SearchBoxState extends State<SearchBox> {
  final _search_controller = TextEditingController();

  void _handleTextControllerUpdate() {
    Future.delayed(
      const Duration(seconds: 0),
      () => widget.onUpdate(_search_controller.text),
    );
  }

  @override
  void initState() {
    super.initState();
    _search_controller.text = widget.searchText;
    _search_controller.addListener(_handleTextControllerUpdate);
  }

  @override
  void dispose() {
    _search_controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(SearchBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!this.widget.searchFocusNode.hasFocus) {
      if (widget.searchText != _search_controller.text) {
        _search_controller.removeListener(_handleTextControllerUpdate);
        _search_controller.text = widget.searchText;
        _search_controller.addListener(_handleTextControllerUpdate);
        this.widget.searchFocusNode.requestFocus();
        _search_controller.selection = TextSelection(
            baseOffset: 0, extentOffset: _search_controller.text.length);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // create a search box with a search icon on the left and round corners
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      margin: EdgeInsets.all(10),
      child: Row(
        children: [
          Icon(
            Icons.search,
            size: 18,
          ),
          Expanded(
            child: TextField(
              focusNode: this.widget.searchFocusNode,
              autofocus: true,
              keyboardType: TextInputType.text,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 0.0, horizontal: 10.0),
              ),
              controller: _search_controller,
              style: TextStyle(
                  fontSize: 13.0,
                  fontWeight: FontWeight.w900,
                  color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}

class Journal extends StatefulWidget {
  Journal({required this.searchText, required this.onSearchTextUpdate})
      : super();

  final String searchText;
  final Function(String) onSearchTextUpdate;

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
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
      ),
      child: Column(
        children: [
          SearchBox(
            searchText: this.widget.searchText,
            onUpdate: this.widget.onSearchTextUpdate,
            searchFocusNode: _searchFocusNode,
          ),
          Expanded(
              child: EntryLog(
            searchText: this.widget.searchText,
            onSearch: () {
              _searchFocusNode.requestFocus();
            },
          )),
        ],
      ),
    );
  }
}
