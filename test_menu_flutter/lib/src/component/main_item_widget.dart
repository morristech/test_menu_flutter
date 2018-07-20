import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:func/func.dart';
import '../model/main_item.dart';

class MainItemWidget extends StatefulWidget {
  final MainItem item;
  final VoidFunc1<MainItem> onTap; // = Function(MainItem item);
  MainItemWidget(this.item, this.onTap);

  @override
  _MainItemWidgetState createState() => new _MainItemWidgetState();
}

class _MainItemWidgetState extends State<MainItemWidget> {
  @override
  Widget build(BuildContext context) {
    return new ListTile(
        title: new Text(widget.item.title),
        subtitle: widget.item.description == null
            ? null
            : new Text(widget.item.description),
        onTap: _onTap);
  }

  void _onTap() {
    widget.onTap(widget.item);

    //print(widget.item.route);
    //Navigator.pushNamed(context, widget.item.route);
  }
}
