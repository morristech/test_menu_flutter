import 'dart:async';

import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart';
//import 'package:tekartik_common_utils/dev_utils.dart';
// ignore: implementation_imports
import 'package:tekartik_test_menu/src/test_menu/test_menu.dart';
// ignore: implementation_imports
import 'package:tekartik_test_menu/src/test_menu/test_menu_manager.dart';
import 'package:tekartik_test_menu/test_menu.dart';
import 'package:tekartik_test_menu_flutter/src/component/item_widget.dart';
import 'package:tekartik_test_menu_flutter/src/component/menu_item_widget.dart';
import 'package:tekartik_test_menu_flutter/src/model/item.dart';

// ignore: implementation_imports
// ignore: implementation_imports

class MenuItems extends StatefulWidget {
  final List<BaseItem> items;

  MenuItems({Key key, this.title, this.items}) : super(key: key);

  final String title;

  @override
  MenuItemsState createState() => new MenuItemsState();
}

class MenuItemsState extends State<MenuItems> {
  int get _itemCount => widget.items?.length ?? 0;

  final _lock = Lock();

  @override
  initState() {
    // devPrint('MenuItemsState.initState');
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(itemBuilder: _itemBuilder, itemCount: _itemCount);
  }

  //new Center(child: new Text('Running on: $_platformVersion\n')),

  _runIfTest(Item item) {
    if (item.autoRun && item.test == true && item.state == ItemState.idle) {
      _lock.synchronized(() async {
        await _run(item);
      });
    }
  }

  _runIfGroup(Menu item) {
    if (item.autoRun && item.group == true && item.state == ItemState.idle) {
      _lock.synchronized(() async {
        await _runGroup(item);
      });
    }
  }

  Widget _itemBuilder(BuildContext context, int index) {
    var item = widget.items[index];
    /*if (item is MainItem) {
      return new GroupWidget(item as MainItem, (MainItem item) {
        if (item is PageItem) {
          // Navigator.of(context).push(new MaterialPageRoute(builder: item.pageBuilder));
        } else {
          if (item.action != null) {
            item.action(context);
          } else {
            // Navigator.of(context).pushNamed(item.route);
          }
        }
      });
    } else */
    if (item is Item) {
      // devPrint('item widget ${item}');
      new Future.value().then((_) {
        _runIfTest(item);
      });
      return new ItemWidget(item, (_) async {
        // item.action();
        await _run(item);
        /*
        if (item.action != null) {
          item.action(context);
        }
        */
      });
    } else if (item is Menu) {
      // devPrint('menu widget ${item}');
      new Future.value().then((_) {
        _runIfGroup(item);
      });
      return new MenuItemWidget(
        item,
        onTap: (_) async {
          // item.action();
          await _enterMenu(item);
          /*
        if (item.action != null) {
          item.action(context);
        }
        */
        },
        onPlay: (Menu menu) {
          _runGroup(menu);
          // (menu.testItem as MenuTestItem).
        },
      );
    }
    throw 'not supported $item ${item?.runtimeType}';
  }

  _enterMenu(Menu menu) async {
    var testItem = menu.testItem;
    // devPrint('running $testItem');
    await testMenuManager.runItem(testItem);
    // devPrint('done $testItem');
  }

  _runGroup(Menu menu) async {
    // devPrint("_runGroup");
    int count = 0;
    int successCount = 0;
    dynamic firstError;

    Future _addMenu(TestMenu testMenu, bool run) async {
      for (var item in testMenu.items) {
        if (item is MenuTestItem) {
          _addMenu(item.menu, run);
          // devPrint(item);
        } else if (item is RunnableTestItem) {
          // devPrint(item);
          count++;
          if (run) {
            print("#TEST Running ${item.name}");
            try {
              await item.fn();
              successCount++;
            } catch (e) {
              firstError ??= e;
            }
            print("TEST Done ${item.name}");
          }
        }
      }
    }

    setState(() {
      menu.state = ItemState.running;
      // devPrint('running item widget ${menu}');
    });

    try {
      //await _addMenu(menu.menuTestItem.menu, false);

      await _addMenu(menu.menuTestItem.menu, true);
      if (firstError != null) {
        throw firstError;
      }
      setState(() {
        menu.state = ItemState.success;
        // devPrint('success menu widget ${menu}');
      });
      write('SUCCESS tests $successCount/$count');
    } catch (e) {
      write('ERROR tests $successCount/$count');
      print("TEST Error $e running ${menu.name}");
      try {
        //print(st);
/*        if (await Sqflite.getDebugModeOn()) {
    print(st);
    }
    */
      } finally {
        setState(() {
          menu..state = ItemState.failure;
          // devPrint('failure menu widget ${menu}');
        });
      }
    }
  }

  _run(Item item) async {
    setState(() {
      item.state = ItemState.running;
      // devPrint('running item widget ${item}');
    });
    try {
      print("#TEST Running ${item.name}");
      await item.action();
      print("TEST Done ${item.name}");

      //item = new Item("${item.name}")..state = ItemState.success;
      setState(() {
        item.state = ItemState.success;
        // devPrint('success item widget ${item}');
      });
    } catch (e) {
      print("TEST Error $e running ${item.name}");
      try {
        //print(st);
/*        if (await Sqflite.getDebugModeOn()) {
    print(st);
    }
    */
      } finally {
        setState(() {
          item..state = ItemState.failure;
          // devPrint('failure item widget ${item}');
        });
      }
    }
  }
}
