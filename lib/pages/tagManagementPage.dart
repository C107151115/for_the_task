/*
這個檔案的內容是關於標籤管理畫面的內容，
而Tag物件、相關辦法及其資料庫的存取主要是再appClass.dart中。
 */

import 'package:flutter/material.dart';
import 'package:async/async.dart';
import 'package:for_the_task/appClass.dart';
import 'package:cyclop/cyclop.dart';

var appColor = Colors.brown;

// StatefulWidget
class TagManagementPage extends StatefulWidget {
  // constructor
  TagManagementPage({Key key}) : super(key: key);
  // create state
  @override
  _TagManagementPageState createState() => _TagManagementPageState();
}

// StatefulWidget State
class _TagManagementPageState extends State<TagManagementPage> {
  // 資料庫查詢用
  static TagsHelper helper = new TagsHelper();
  // 存放畫面顯示的標籤
  static List<Tag> tagList = [];

  // 讓FutureBuilder只執行一次需要用到的東東
  final AsyncMemoizer _memoizer = AsyncMemoizer();

  // 初始時讀取資料庫用
  _initTagList() async {
    return _memoizer.runOnce(() async {
      print('初始化');
      await helper.open();
      tagList = await helper.getAllAvailableTags();
      tagList.removeAt(0); // 不顯示預設標籤
      // return true;
    });
  }

  // 新增標籤
  void addTag(context) async {
    // 顯示輸入畫面並取值
    Map returnData = await addTagDialog(context);
    while (returnData != null) {
      Tag newTag = Tag(name: returnData['name'], color: returnData['color']);
      // 寫入資料庫
      await helper.addTag(newTag);
      print('更新後id${newTag.id}');
      // 更新畫面List
      tagList.add(newTag);
      // 更新畫面
      setState(() {});
      // 確認是否需要再進行一次輸入
      if (returnData['next'] == true) {
        returnData = await addTagDialog(context);
      } else {
        break;
      }
    }
  }

  // 刪除標籤
  void deleteTag(context, Tag t) async {
    // 詢問是否刪除並取得布林值
    bool check = await confirmDialog(context, '刪除標籤', '確定要刪除此標籤嗎？');
    print('詢問是否刪除Tag，結果為$check');
    if (check == true) {
      // 刪除資料庫內的資料
      await helper.deleteTag(t.id);
      // 更新畫面List
      tagList.remove(t);
      // 更新畫面
      setState(() {});
    }
  }

  // 修改標籤
  void editTag(context, Tag t) async {
    // 顯示輸入畫面並修改標籤t
    await editTagDialog(context, t);
    // 更新資料庫
    helper.updateTag(t);
    // 更新畫面List
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('標籤管理', style: TextStyle(fontSize: 24)),
      ),
      body: FutureBuilder(
        future: _initTagList(),
        builder: (context, AsyncSnapshot snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
              return Center(
                child: Text(
                  '讀取標籤中...',
                  style: TextStyle(fontSize: 16),
                ),
              );
            default:
              return _buildTagListVies(context);
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: '新增標籤',
        child: Icon(
          Icons.add,
        ),
        onPressed: () async {
          addTag(context);
        },
      ),
    );
  }

  // 建立標籤清單的元件
  Widget _buildTagListVies(context) {
    if (tagList.isEmpty) {
      return Center(
          child: Text(
        '目前沒有任何標籤可被選用',
        style: TextStyle(fontSize: 16),
      ));
    } else {
      return ListView.separated(
        // padding: const EdgeInsets.all(8),
        itemCount: tagList.length,
        itemBuilder: (BuildContext context, int index) {
          return _buildTagListTile(context, tagList[index], index);
        },
        separatorBuilder: (BuildContext context, int index) => const Divider(
          height: 1,
          color: Colors.grey,
        ),
      );
    }
  }

  // 建立一列標籤的元件
  Widget _buildTagListTile(context, Tag t, int index) {
    return ListTile(
      // tileColor: Colors.red[50],
      contentPadding: EdgeInsets.only(top: 0, bottom: 0, left: 10, right: 10),
      leading: Icon(
        Icons.label,
        color: Color(t.color),
      ),
      title: Text(t.name, style: TextStyle(fontSize: 16)),
      onTap: () {
        editTag(context, t);
      },
      onLongPress: () {
        deleteTag(context, t);
      },
    );
  }
}

// 確認用的提醒框
Future<bool> confirmDialog(
    BuildContext context, String titleText, String contentText) async {
  return showDialog<bool>(
    context: context,
    // barrierDismissible: true,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(titleText),
        content: Text(contentText),
        actions: <Widget>[
          TextButton(
              child: const Text(
                '確定',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                Navigator.pop(context, true);
              }),
          TextButton(
            child: const Text(
              '取消',
              style: TextStyle(color: Colors.blue),
            ),
            onPressed: () {
              Navigator.pop(context, false);
            },
          ),
        ],
      );
    },
  );
}

// 新增標籤用的對話框
Future<Map> addTagDialog(BuildContext context) async {
  String _tagName = '';
  int _tagColor = Colors.grey.value;
  Color _buttonColor = Colors.grey;
  Set<Color> swatches = Colors.primaries.map((e) => Color(e.value)).toSet();

  ColorButton _buildColorButtons(setState) {
    return ColorButton(
      key: Key('colorButton'),
      color: _buttonColor,
      swatches: swatches,
      onColorChanged: (value) => setState(
        () => {
          _buttonColor = value,
          _tagColor = value.value,
          print(value),
        },
      ),
      onSwatchesChanged: (newSwatches) =>
          setState(() => {swatches = newSwatches}),
    );
  }

  return showDialog<Map>(
    context: context,
    // barrierDismissible: true,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setStte) {
          return AlertDialog(
            title: const Text('新增標籤'),
            content: Container(
              constraints: BoxConstraints(minHeight: 0.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        filled: true,
                        // icon: Icon(Icons.label),
                        hintText: '請輸入標籤名稱',
                        labelText: '標籤名稱*',
                      ),
                      onChanged: (value) {
                        _tagName = value.trim();
                        print('標籤名稱：$_tagName');
                      },
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(top: 25.0),
                    // color: Colors.amber,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Align(
                          alignment: Alignment.topLeft,
                          child: Text(
                            '標籤顏色：',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                        Align(
                          alignment: Alignment.topRight,
                          child: _buildColorButtons(setStte),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                  child: const Text('新增', style: TextStyle(color: Colors.blue)),
                  onPressed: () {
                    _tagName = _tagName.trim();
                    Map returnData = null;
                    if (_tagName.isNotEmpty)
                      returnData = {
                        'name': _tagName,
                        'color': _tagColor,
                        'next': false
                      };
                    Navigator.pop(context, returnData);
                  }),
              TextButton(
                child: const Text(
                  '新增下一個',
                  style: TextStyle(color: Colors.purple),
                ),
                onPressed: () {
                  _tagName = _tagName.trim();
                  Map returnData = null;
                  if (_tagName.isNotEmpty)
                    returnData = {
                      'name': _tagName,
                      'color': _tagColor,
                      'next': true
                    };
                  Navigator.pop(context, returnData);
                },
              ),
              TextButton(
                child: const Text('取消', style: TextStyle(color: Colors.red)),
                onPressed: () {
                  Navigator.pop(context, null);
                },
              ),
            ],
          );
        },
      );
    },
  );
}

// 編輯標籤用的對話框
Future<Map> editTagDialog(BuildContext context, Tag t) async {
  String _tagName = t.name;
  int _tagColor = t.color;
  Color buttonColor = Color(_tagColor);
  Set<Color> swatches = Colors.primaries.map((e) => Color(e.value)).toSet();

  ColorButton _buildColorButtons(setState) {
    return ColorButton(
      key: Key('colorButton'),
      color: buttonColor,
      swatches: swatches,
      onColorChanged: (value) => setState(
        () => {
          buttonColor = value,
          _tagColor = value.value,
          print(value),
        },
      ),
      onSwatchesChanged: (newSwatches) =>
          setState(() => {swatches = newSwatches}),
    );
  }

  return showDialog<Map>(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setStte) {
          return AlertDialog(
            title: const Text('修改標籤'),
            content: Container(
              constraints: BoxConstraints(minHeight: 0.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    child: TextFormField(
                      initialValue: _tagName,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        filled: true,
                        hintText: '請輸入標籤名稱',
                        labelText: '標籤名稱*',
                      ),
                      onChanged: (value) {
                        _tagName = value;
                        print('標籤名稱：$_tagName');
                      },
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(top: 25.0),
                    // color: Colors.amber,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Align(
                          alignment: Alignment.topLeft,
                          child: Text(
                            '標籤顏色：',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                        Align(
                          alignment: Alignment.topRight,
                          child: _buildColorButtons(setStte),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                  child: const Text('確定', style: TextStyle(color: Colors.blue)),
                  onPressed: () {
                    t.name = _tagName;
                    t.color = _tagColor;
                    Map returnData = null;
                    if (_tagName != '' || _tagName.trim().isNotEmpty)
                      returnData = {
                        'name': _tagName,
                        'color': _tagColor,
                      };
                    Navigator.pop(context, returnData);
                  }),
              TextButton(
                child: const Text('取消', style: TextStyle(color: Colors.red)),
                onPressed: () {
                  Navigator.pop(context, null);
                },
              ),
            ],
          );
        },
      );
    },
  );
}
