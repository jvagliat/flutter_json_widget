library flutter_json_widget;

import 'package:flutter/material.dart';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

class Logger {
  static bool filter = false;
  static Type monitoring;
  static List<Type> excluding = [];
  static bool showAt = true;
  static String app = "Jvagliat Studio";

  static d(dynamic target, String message) {
    if (kIsWeb) print(message);
    if (!filter ||
        ((monitoring == null || target.runtimeType == monitoring) &&
            !excluding.contains(target.runtimeType))) {
      DateTime now = DateTime.now();
      if (showAt)
        developer.log(
          message.toString(),
          name: '$app - ${_target(target)} - at ${_format(now)}',
        );
      else
        developer.log(
          message.toString(),
          name: '$app - ${_target(target)}',
        );
    }
  }

  static String _format(DateTime dateTime) {
    return dateTime.hour.toString() +
        ":" +
        (dateTime.minute <= 9 ? "0" : "") +
        dateTime.minute.toString() +
        (dateTime.second <= 9 ? "0" : "") +
        dateTime.second.toString();
  }

  static void e(dynamic target, message, error) {
    developer.log(message,
        name: '$app - ${_target(target)}', error: error, level: 200);

    // print(error);
  }

  static String _target(dynamic target) {
    if (target is String)
      return target;
    else
      return target.runtimeType.toString();
  }
}

class JsonViewerWidget extends StatefulWidget {
  final Map<String, dynamic> jsonObj;
  final bool notRoot;

  JsonViewerWidget(this.jsonObj, {this.notRoot});

  @override
  JsonViewerWidgetState createState() => new JsonViewerWidgetState();
}

class JsonViewerWidgetState extends State<JsonViewerWidget> {
  Map<String, bool> openFlag = Map();
  @override
  void initState() {
    super.initState();
    try {
      _expandAll(widget.jsonObj);
    } catch (e) {
      Logger.e(this, "root", e);
    }
  }

  _expandAll(Map<String, dynamic> map) {
    Logger.d(this, "expanding");
    map.keys.forEach((key) {
      Logger.d(this, "expanding $key");
      openFlag[key] = map[key] is Map || map[key] is List;
      try {
        var value = map[key];
        Logger.d(this, "$key -> $value is ${value.runtimeType}");

        if (!(value is String) && !(value is int) && !value is double)
          _expandAll(map[key]);
        else if (value is List) {
          
          for (var item in value) {
            Logger.d(this, "expanding array $key  item $item");
            _expandAll(item);
          }
        }
      } catch (e) {
        Logger.e(this, "child", e);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.notRoot ?? false) {
      return Container(
          padding: EdgeInsets.only(left: 14.0),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _getList()));
    }
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: _getList());
  }

  _getList() {
    List<Widget> list = List();
    for (MapEntry entry in widget.jsonObj.entries) {
      bool ex = isExtensible(entry.value);
      bool ink = isInkWell(entry.value);
      list.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ex
              ? ((openFlag[entry.key] ?? false)
                  ? Icon(Icons.arrow_drop_down,
                      size: 14, color: Colors.grey[700])
                  : Icon(Icons.arrow_right, size: 14, color: Colors.grey[700]))
              : const Icon(
                  Icons.arrow_right,
                  color: Color.fromARGB(0, 0, 0, 0),
                  size: 14,
                ),
          (ex && ink)
              ? InkWell(
                  child: Text(entry.key,
                      style: TextStyle(color: Colors.purple[900])),
                  onTap: () {
                    setState(() {
                      openFlag[entry.key] = !(openFlag[entry.key] ?? false);
                    });
                  })
              : Text(entry.key,
                  style: TextStyle(
                      color: entry.value == null
                          ? Colors.grey
                          : Colors.purple[900])),
          Text(
            ':',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(width: 3),
          getValueWidget(entry)
        ],
      ));
      list.add(const SizedBox(height: 4));
      if (openFlag[entry.key] ?? false) {
        list.add(getContentWidget(entry.value));
      }
    }
    return list;
  }

  static getContentWidget(dynamic content) {
    if (content is List) {
      return JsonArrayViewerWidget(content, notRoot: true);
    } else if (content is Map) {
      return JsonViewerWidget(content, notRoot: true);
    }
  }

  static isInkWell(dynamic content) {
    if (content == null) {
      return false;
    } else if (content is int) {
      return false;
    } else if (content is String) {
      return false;
    } else if (content is bool) {
      return false;
    } else if (content is double) {
      return false;
    } else if (content is List) {
      if (content.isEmpty) {
        return false;
      } else {
        return true;
      }
    }
    return true;
  }

  getValueWidget(MapEntry entry) {
    if (entry.value == null) {
      return Expanded(
          child: Text(
        'undefined',
        style: TextStyle(color: Colors.grey),
      ));
    } else if (entry.value is int) {
      return Expanded(
          child: Text(
        entry.value.toString(),
        style: TextStyle(color: Colors.teal),
      ));
    } else if (entry.value is String) {
      return Expanded(
          child: Text(
        '\"' + entry.value + '\"',
        style: TextStyle(color: Colors.redAccent),
      ));
    } else if (entry.value is bool) {
      return Expanded(
          child: Text(
        entry.value.toString(),
        style: TextStyle(color: Colors.purple),
      ));
    } else if (entry.value is double) {
      return Expanded(
          child: Text(
        entry.value.toString(),
        style: TextStyle(color: Colors.teal),
      ));
    } else if (entry.value is List) {
      if (entry.value.isEmpty) {
        return Text(
          'Array[0]',
          style: TextStyle(color: Colors.grey),
        );
      } else {
        return InkWell(
            child: Text(
              'Array<${getTypeName(entry.value[0])}>[${entry.value.length}]',
              style: TextStyle(color: Colors.grey),
            ),
            onTap: () {
              setState(() {
                openFlag[entry.key] = !(openFlag[entry.key] ?? false);
              });
            });
      }
    }
    return InkWell(
        child: Text(
          'Object',
          style: TextStyle(color: Colors.grey),
        ),
        onTap: () {
          setState(() {
            openFlag[entry.key] = !(openFlag[entry.key] ?? false);
          });
        });
  }

  static isExtensible(dynamic content) {
    if (content == null) {
      return false;
    } else if (content is int) {
      return false;
    } else if (content is String) {
      return false;
    } else if (content is bool) {
      return false;
    } else if (content is double) {
      return false;
    }
    return true;
  }

  static getTypeName(dynamic content) {
    if (content is int) {
      return 'int';
    } else if (content is String) {
      return 'String';
    } else if (content is bool) {
      return 'bool';
    } else if (content is double) {
      return 'double';
    } else if (content is List) {
      return 'List';
    }
    return 'Object';
  }
}

class JsonArrayViewerWidget extends StatefulWidget {
  final List<dynamic> jsonArray;

  final bool notRoot;

  JsonArrayViewerWidget(this.jsonArray, {this.notRoot});

  @override
  _JsonArrayViewerWidgetState createState() =>
      new _JsonArrayViewerWidgetState();
}

class _JsonArrayViewerWidgetState extends State<JsonArrayViewerWidget> {
  List<bool> openFlag;

  @override
  Widget build(BuildContext context) {
    if (widget.notRoot ?? false) {
      return Container(
          padding: EdgeInsets.only(left: 14.0),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _getList()));
    }
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: _getList());
  }

  @override
  void initState() {
    super.initState();
    openFlag = List();
    for (int i =0;i<widget.jsonArray.length;i++) {
      Logger.d(this, ">>> expaidning array item $i ${widget.jsonArray[i]}");
      openFlag.add(true);
    }
  }

  _getList() {
    List<Widget> list = List();
    int i = 0;
    for (dynamic content in widget.jsonArray) {
      bool ex = JsonViewerWidgetState.isExtensible(content);
      bool ink = JsonViewerWidgetState.isInkWell(content);
      list.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ex
              ? ((openFlag[i] ?? false)
                  ? Icon(Icons.arrow_drop_down,
                      size: 14, color: Colors.grey[700])
                  : Icon(Icons.arrow_right, size: 14, color: Colors.grey[700]))
              : const Icon(
                  Icons.arrow_right,
                  color: Color.fromARGB(0, 0, 0, 0),
                  size: 14,
                ),
          (ex && ink)
              ? getInkWell(i)
              : Text('[$i]',
                  style: TextStyle(
                      color:
                          content == null ? Colors.grey : Colors.purple[900])),
          Text(
            ':',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(width: 3),
          getValueWidget(content, i)
        ],
      ));
      list.add(const SizedBox(height: 4));
      if (openFlag[i] ?? false) {
        list.add(JsonViewerWidgetState.getContentWidget(content));
      }
      i++;
    }
    return list;
  }

  getInkWell(int index) {
    return InkWell(
        child: Text('[$index]', style: TextStyle(color: Colors.purple[900])),
        onTap: () {
          setState(() {
            openFlag[index] = !(openFlag[index] ?? false);
          });
        });
  }

  getValueWidget(dynamic content, int index) {
    if (content == null) {
      return Expanded(
          child: Text(
        'undefined',
        style: TextStyle(color: Colors.grey),
      ));
    } else if (content is int) {
      return Expanded(
          child: Text(
        content.toString(),
        style: TextStyle(color: Colors.teal),
      ));
    } else if (content is String) {
      return Expanded(
          child: Text(
        '\"' + content + '\"',
        style: TextStyle(color: Colors.redAccent),
      ));
    } else if (content is bool) {
      return Expanded(
          child: Text(
        content.toString(),
        style: TextStyle(color: Colors.purple),
      ));
    } else if (content is double) {
      return Expanded(
          child: Text(
        content.toString(),
        style: TextStyle(color: Colors.teal),
      ));
    } else if (content is List) {
      if (content.isEmpty) {
        return Text(
          'Array[0]',
          style: TextStyle(color: Colors.grey),
        );
      } else {
        return InkWell(
            child: Text(
              'Array<${JsonViewerWidgetState.getTypeName(content)}>[${content.length}]',
              style: TextStyle(color: Colors.grey),
            ),
            onTap: () {
              setState(() {
                openFlag[index] = !(openFlag[index] ?? false);
              });
            });
      }
    }
    return InkWell(
        child: Text(
          'Object',
          style: TextStyle(color: Colors.grey),
        ),
        onTap: () {
          setState(() {
            openFlag[index] = !(openFlag[index] ?? false);
          });
        });
  }
}
