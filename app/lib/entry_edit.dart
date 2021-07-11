import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'models.dart';

class EntryEdit extends StatefulWidget {
  EntryEdit({
    required this.entry,
    required this.onUpdate,
  }) : super(key: ObjectKey(entry.id));

  final Entry entry;
  final Function(Entry) onUpdate;

  @override
  _EntryEditState createState() => _EntryEditState();
}

class _EntryEditState extends State<EntryEdit> {
  final _title_controller = TextEditingController();
  final _meta_controller = TextEditingController();
  final _body_controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _title_controller.text = widget.entry.title;
    _meta_controller.text = widget.entry.meta;
    _body_controller.text = widget.entry.body;
  }

  @override
  void dispose() {
    this.widget.onUpdate(Entry(
        id: this.widget.entry.id,
        created: this.widget.entry.created,
        title: _title_controller.text,
        meta: _meta_controller.text,
        body: _body_controller.text));
    _title_controller.dispose();
    _meta_controller.dispose();
    _body_controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
        elevation: 2,
        insetAnimationDuration: Duration(milliseconds: 0),
        insetAnimationCurve: Curves.linear,
        insetPadding: EdgeInsets.all(50.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(2.0),
        ),
        child: Container(
          width: 800,
          height: 400,
          child: Column(
            children: <Widget>[
              Container(
                  // decoration: new BoxDecoration(color: Colors.blue),
                  padding: EdgeInsets.only(top: 20.0),
                  child: Row(children: [
                    SizedBox(
                      width: 20.0,
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Color.fromRGBO(0, 0, 0, 0.2),
                      size: 13.0,
                    ),
                    Expanded(
                      child: Container(
                        // decoration: new BoxDecoration(color: Colors.green),
                        child: TextField(
                          autofocus: true,
                          controller: _title_controller,
                          keyboardType: TextInputType.text,
                          decoration: const InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 10.0, horizontal: 7.0),
                          ),
                          style: TextStyle(
                            height: 1.0,
                            fontSize: 13.0,
                            fontWeight: FontWeight.w900,
                            color: Theme.of(context).colorScheme.onBackground,
                          ),
                        ),
                      ),
                    ),
                  ])),
              Container(
                  decoration: new BoxDecoration(color: Colors.transparent),
                  child: Row(children: [
                    SizedBox(
                      width: 20.0,
                    ),
                    Icon(
                      Icons.settings,
                      color: Color.fromRGBO(0, 0, 0, 0.2),
                      size: 13.0,
                    ),
                    Expanded(
                      child: TextField(
                        controller: _meta_controller,
                        keyboardType: TextInputType.text,
                        decoration: const InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.only(
                              top: 10.0, bottom: 10.0, left: 6.0, right: 7.0),
                        ),
                        style: GoogleFonts.sourceCodePro(
                            height: 1.0,
                            fontSize: 13,
                            color: Colors.black45,
                            fontWeight: FontWeight.w600),
                      ),
                    )
                  ])),
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 10.0),
                  decoration: new BoxDecoration(color: Colors.transparent),
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 20.0,
                        ),
                        Icon(
                          Icons.article,
                          color: Color.fromRGBO(0, 0, 0, 0.15),
                          size: 13.0,
                        ),
                        Expanded(
                          child: TextField(
                            controller: _body_controller,
                            keyboardType: TextInputType.multiline,
                            maxLines: null,
                            minLines: 8,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.only(
                                  top: 2, bottom: 0, left: 8.0, right: 7.0),
                            ),
                            style: TextStyle(
                                fontSize: 13.0,
                                fontWeight: FontWeight.w100,
                                color: Colors.black54),
                          ),
                        ),
                      ]),
                ),
              ),
              Container(
                decoration: new BoxDecoration(color: Colors.transparent),
                padding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 15.0),
                alignment: Alignment.centerRight,
                child: InkWell(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    "Save",
                    style: TextStyle(
                      fontSize: 13.0,
                      fontWeight: FontWeight.w400,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ));
  }
}
