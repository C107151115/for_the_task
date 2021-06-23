import 'package:flutter/material.dart';
import 'package:async/async.dart';
import 'package:for_the_task/appClass.dart';

var appColor = Colors.brown;

const List<String> TASKTYPE = ['daily', 'monthly', 'yearly', 'custom'];

class HomePage extends StatefulWidget {
  String title;
  HomePage({Key key, this.title}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  List<Widget> testlist = [];

  static int tabIndex = 0; // 目前所在的分頁位置
  static String appBarTitle = ''; // 標題名稱
  // static String taskType = 'daily';
  static int dailyY = 0, dailyM = 0, dailyD = 0; // 日任務的年月日值
  static int monthlyY = 0, monthlyM = 0; // 月任務的年月值
  static int yearlyY = 0; // 年任務的年值
  static String customTask = 'CUSTOM'; // 自訂任務的名稱
  // ...
  List<String> customTaskList = []; // 放所有自訂任務名稱的List

  static List<List<Task>> finishedList = [[], [], [], []];
  static List<List<Task>> unfinishedList = [[], [], [], []];

  TabController _tabController;
  static List<Widget> _kTabPages = <Widget>[
    Container(child: Text('tab0', style: TextStyle(fontSize: 40))),
    Container(child: Text('tab1', style: TextStyle(fontSize: 40))),
    Container(child: Text('tab2', style: TextStyle(fontSize: 40))),
    Container(
      child: Text('data'),
    ),
  ];

  // 讓FutureBuilder只執行一次需要用到的東東
  final AsyncMemoizer _memoizer = AsyncMemoizer();

  // BottomBar的項目
  static const _kTabs = <Tab>[
    Tab(
      icon: ImageIcon(
        AssetImage('assets/icons/calendar_D.png'),
        size: 34,
        color: Colors.white,
      ),
      child: Text(
        '日',
        style: TextStyle(fontSize: 18),
      ),
    ),
    Tab(
      icon: ImageIcon(
        AssetImage('assets/icons/calendar_M.png'),
        size: 34,
        color: Colors.white,
      ),
      child: Text(
        '月',
        style: TextStyle(fontSize: 18),
      ),
    ),
    Tab(
      icon: ImageIcon(
        AssetImage('assets/icons/calendar_Y.png'),
        size: 34,
        color: Colors.white,
      ),
      child: Text(
        '年',
        style: TextStyle(fontSize: 18),
      ),
    ),
    Tab(
      icon: ImageIcon(
        AssetImage('assets/icons/calendar_C.png'),
        size: 34,
        color: Colors.white,
      ),
      child: Text(
        '自訂',
        style: TextStyle(fontSize: 18),
      ),
    ),
  ];

  _init(constext) async {
    return _memoizer.runOnce(() async {
      _kTabPages[3] = Container(
        child: ListView(
          children: testlist,
        ),
      );
      print('home page init.');
      // 取得今天的值並作為畫面預設顯示的參考
      dailyY = monthlyY = yearlyY = DateTime.now().year;
      dailyM = monthlyM = DateTime.now().month;
      dailyD = DateTime.now().day;

      // 取得上次顯示的自訂清單名稱

      // ...
      // 修改預設顯示的標題文字
      appBarTitle = '$dailyY/$dailyM/$dailyD';
      // 抓資料庫中的任務資料
      for (int i = 0; i < 4; i++) {
        TasksHelper helper = tasksHelperBuilder(
          dataType: i,
        );
        await helper.open();
        finishedList[i] = await helper.getAllFinishedTasks();
        print(finishedList[i].length);
        unfinishedList[i] = await helper.getAllUnfinishedTasks();
        _kTabPages[i] = _buildPage(context, i);
      }

      setState(() {});
      return true;
    });
  }

  TasksHelper tasksHelperBuilder({int dataType = -1}) {
    if (dataType == -1) {
      dataType = tabIndex;
    }
    TasksHelper helper;
    switch (dataType) {
      case 0:
        helper =
            TasksHelper(dataType: TASKTYPE[0], y: dailyY, m: dailyM, d: dailyD);
        break;
      case 1:
        helper = TasksHelper(dataType: TASKTYPE[1], y: monthlyY, m: monthlyM);
        break;
      case 2:
        helper = TasksHelper(dataType: TASKTYPE[2], y: yearlyY);
        break;
      case 3:
        helper = TasksHelper(dataType: TASKTYPE[3], custom: customTask);
        break;
    }
    return helper;
  }

  // 根據類型讀取資料庫中所有已完成的任務
  Future<List<Task>> getFinished(int dataType) async {
    TasksHelper helper = tasksHelperBuilder(dataType: dataType);
    await helper.open();
    List<Task> result = await helper.getAllFinishedTasks();
    return result;
  }

  // 根據類型讀取資料庫中所有未完成的任務
  Future<List<Task>> getUnfinished(int dataType) async {
    TasksHelper helper = tasksHelperBuilder(dataType: dataType);
    await helper.open();
    List<Task> result = await helper.getAllUnfinishedTasks();
    return result;
  }

  // 新增任務
  void addTask(context) async {
    List dialogReturn = await addTaskDialog(context);
    while (dialogReturn != null && dialogReturn.isNotEmpty) {
      TasksHelper helper = tasksHelperBuilder();
      await helper.open();
      await helper.addTask(dialogReturn[0]);
      unfinishedList[tabIndex].add(dialogReturn[0]);
      _kTabPages[tabIndex] = _buildPage(context, tabIndex);

      print('成功新增任務 id=${dialogReturn[0].id}');
      int x = (await helper.getAllTasks()).length;
      setState(() {});
      if (dialogReturn[1] == true) {
        dialogReturn = await addTaskDialog(context);
      } else
        break;
    }
  }

  // 編輯現有任務
  void editTask(context, Task t) async {
    await editTaskDialog(context, t);
    TasksHelper helper = tasksHelperBuilder();
    await helper.open();
    await helper.updateTask(t);
    _kTabPages[tabIndex] = _buildPage(context, tabIndex);

    setState(() {
      print('成功修改任務 id=${t.id}');
    });
  }

  // 刪除任務
  void deleteTask(context, Task t) async {
    bool check = await confirmDialog(context, '刪除任務', '確定要刪除此任務嗎？');
    if (check == true) {
      TasksHelper helper = tasksHelperBuilder();
      await helper.open();
      // 刪除資料庫內的資料
      await helper.deleteTask(t.id);
      // 更新畫面List
      if (t.state == 1) {
        finishedList[tabIndex].remove(t);
      } else {
        unfinishedList[tabIndex].remove(t);
      }
      // 更新畫面
      _kTabPages[tabIndex] = _buildPage(context, tabIndex);

      setState(() {});
    }
  }

  // 設任務為完成
  void setFinished(context, Task t) async {
    TasksHelper helper = tasksHelperBuilder();
    await helper.open();
    await helper.setTaskFinished(t);
    finishedList[tabIndex].add(t);
    unfinishedList[tabIndex].remove(t);
    _kTabPages[tabIndex] = _buildPage(context, tabIndex);
    setState(() {});
  }

  // 設任務為未完成
  void setUnfinished(context, Task t) async {
    TasksHelper helper = tasksHelperBuilder();
    await helper.open();
    await helper.setTaskUnfinished(t);
    unfinishedList[tabIndex].add(t);
    finishedList[tabIndex].remove(t);
    _kTabPages[tabIndex] = _buildPage(context, tabIndex);
    setState(() {});
  }

  // 新增自訂任務清單
  void createCustomTaskList() async {}

  ListTile _buildTaskRow(context, Task t) {
    if (t.state == 1) {
      return ListTile(
        leading: IconButton(
          icon: Icon(Icons.check),
          color: Colors.green,
          onPressed: () {
            setUnfinished(context, t);
          },
        ),
        title: Text(
          t.title,
          style: TextStyle(decoration: TextDecoration.lineThrough),
        ),
        onTap: () {
          editTask(context, t);
        },
        onLongPress: () {
          deleteTask(context, t);
        },
      );
    } else {
      return ListTile(
        leading: IconButton(
          icon: Icon(Icons.circle_outlined),
          color: Colors.grey.shade800,
          onPressed: () {
            setFinished(context, t);
          },
        ),
        title: Text(t.title),
        onTap: () {
          editTask(context, t);
        },
        onLongPress: () {
          deleteTask(context, t);
        },
      );
    }
  }

  List<Widget> _buildTaskList(context, int dataType, bool finished) {
    if (finished == true) {
      List<ListTile> rows = [];
      for (Task t in finishedList[dataType]) {
        rows.add(_buildTaskRow(context, t));
      }
      Widget w = ExpansionTile(
        title: Text(
          '已完成(${rows.length})',
          style: TextStyle(),
        ),
        initiallyExpanded: false,
        children: rows,
      );
      return [w];
    } else {
      List<Widget> rows = [];
      for (Task t in unfinishedList[dataType]) {
        rows.add(_buildTaskRow(context, t));
      }
      return rows;
    }
  }

  Widget _buildPage(context, int dataType) {
    // 沒有任何任務
    if (unfinishedList[dataType].isEmpty && finishedList[dataType].isEmpty) {
      return Center(
        child: Text(
          '目前沒有任務喔',
          style: TextStyle(fontSize: 16),
        ),
      );
    }
    // 只有未完成的任務
    else if (finishedList[dataType].isEmpty) {
      print('未完成${unfinishedList[dataType].length} 已完成${finishedList.length}');
      return ListView(
        children: _buildTaskList(context, dataType, false),
      );
    }
    // 只有已完成的任務
    else if (unfinishedList[dataType].isEmpty) {
      print('未完成${unfinishedList[dataType].length} 已完成${finishedList.length}');
      return ListView(
        children: _buildTaskList(context, dataType, true),
      );
    }
    // 兩種都有
    else {
      print('未完成${unfinishedList[dataType].length} 已完成${finishedList.length}');
      List c = <Widget>[];
      c = c + _buildTaskList(context, dataType, false);
      c += _buildTaskList(context, dataType, true);
      return ListView(children: c);
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _kTabPages.length, vsync: this);
    _tabController.addListener(() {
      if (tabIndex != _tabController.index) {
        tabIndex = _tabController.index;
        switch (_tabController.index) {
          case 0:
            appBarTitle = '$dailyY/$dailyM/$dailyD';
            setState(() {});
            print(0);
            break;
          case 1:
            appBarTitle = '$monthlyM月';
            setState(() {});
            print(1);
            break;
          case 2:
            appBarTitle = '$yearlyY年';
            setState(() {});
            print(2);
            break;
          case 3:
            appBarTitle = customTask;
            setState(() {});
            print(3);
            break;
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle, style: TextStyle(fontSize: 24)),
      ),
      drawer: drawerWidget(context),
      body: FutureBuilder(
        future: _init(context),
        builder: (context, AsyncSnapshot snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
              return Center(
                child: Text(
                  '讀取中...',
                  style: TextStyle(fontSize: 16),
                ),
              );
            default:
              return TabBarView(
                controller: _tabController,
                children: _kTabPages,
              );
          }
        },
      ),
      bottomNavigationBar: Material(
        color: appColor,
        child: TabBar(
          // labelPadding: EdgeInsets.only(top: 5, bottom: 5),
          tabs: _kTabs,
          controller: _tabController,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          addTask(context);
          testlist.insert(0, Text('data'));
          setState(() {});
        },
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

Drawer drawerWidget(context) {
  return Drawer(
    child: ListView(
      padding: EdgeInsets.zero,
      children: <Widget>[
        DrawerHeader(
            decoration: BoxDecoration(
              color: appColor,
            ),
            child: Container(
              margin: EdgeInsets.only(top: 10),
              child: Text(
                'For the Task',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            )),
        ListTile(
          leading: Icon(Icons.label),
          title: Text('標籤管理', style: TextStyle(fontSize: 16)),
          onTap: () => {Navigator.pushNamed(context, '/TagManagementPage')},
        ),
        ListTile(
          leading: Icon(Icons.poll),
          title: Text('任務統計', style: TextStyle(fontSize: 16)),
          onTap: () => {Navigator.pushNamed(context, '/StatisticsPage')},
        ),
        // ListTile(
        //   leading: Icon(Icons.settings),
        //   title: Text('設定', style: TextStyle(fontSize: 16)),
        // ),
      ],
    ),
  );
}

// 新增標籤用的對話框
Future<List> addTaskDialog(BuildContext context) async {
  String _title = ''; // 標題
  String _description = ''; // 描述
  int _tag = 0; // 標籤
  TagsHelper helper = TagsHelper();
  await helper.open();
  List<Tag> tagList = await helper.getAllAvailableTags();
  print(tagList.length);

  final List<DropdownMenuItem> _dropdownItem = tagList
      .map((Tag t) => DropdownMenuItem(
            value: t.id,
            child: Text(t.name),
          ))
      .toList();

  return showDialog<List>(
    context: context,
    // barrierDismissible: true,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setStte) {
          return AlertDialog(
            title: const Text('新增任務'),
            content: Container(
              // color: Colors.amber,
              constraints: BoxConstraints(minHeight: 0.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: TextFormField(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        filled: true,
                        // icon: Icon(Icons.label),
                        hintText: '請輸入任務標題',
                        labelText: '標題',
                      ),
                      onChanged: (value) {
                        _title = value;
                        // print('標籤名稱：$_title');
                      },
                    ),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: TextFormField(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        filled: true,
                        hintText: '請輸入任務備註',
                        labelText: '備註',
                      ),
                      onChanged: (value) {
                        _description = value;
                        // print('任務備註：$_description');
                      },
                    ),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('標籤：'),
                    trailing: DropdownButton(
                      value: _tag == 0 ? null : _tag,
                      hint: const Text(
                        '請選取標籤',
                        style: TextStyle(fontSize: 16),
                      ),
                      onChanged: (value) {
                        // print('value: $value');
                        _tag = value;
                        setStte(() {});
                      },
                      items: _dropdownItem,
                    ),
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                  child: const Text('新增', style: TextStyle(color: Colors.blue)),
                  onPressed: () {
                    _title = _title.trim();
                    _description = _description.trim();
                    List returnData = [];
                    if (_title.isNotEmpty) {
                      returnData = [
                        Task(
                            title: _title,
                            description: _description,
                            tag: _tag),
                        false
                      ];
                    }
                    Navigator.pop(context, returnData);
                  }),
              TextButton(
                child: const Text(
                  '新增下一個',
                  style: TextStyle(color: Colors.purple),
                ),
                onPressed: () {
                  _title = _title.trim();
                  _description = _description.trim();
                  List returnData = [];
                  if (_title.isNotEmpty) {
                    returnData = [
                      Task(title: _title, description: _description, tag: _tag),
                      true
                    ];
                  }
                  Navigator.pop(context, returnData);
                },
              ),
              TextButton(
                child: const Text('取消', style: TextStyle(color: Colors.red)),
                onPressed: () {
                  Navigator.pop(context, []);
                },
              ),
            ],
          );
        },
      );
    },
  );
}

// 新增標籤用的對話框
void editTaskDialog(BuildContext context, Task t) async {
  String _title = t.title; // 標題
  String _description = t.description; // 描述
  int _tag = t.tag; // 標籤
  TagsHelper helper = TagsHelper();
  await helper.open();
  List<Tag> tagList = await helper.getAllAvailableTags();
  tagList.removeAt(0);
  print(tagList.length);

  final List<DropdownMenuItem> _dropdownItem = tagList
      .map((Tag t) => DropdownMenuItem(
            value: t.id,
            child: Text(t.name),
          ))
      .toList();

  return showDialog<void>(
    context: context,
    // barrierDismissible: true,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setStte) {
          return AlertDialog(
            title: const Text('編輯任務'),
            content: Container(
              // color: Colors.amber,
              constraints: BoxConstraints(minHeight: 0.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: TextFormField(
                      initialValue: _title,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        filled: true,
                        // icon: Icon(Icons.label),
                        hintText: '請輸入任務標題',
                        labelText: '標題',
                      ),
                      onChanged: (value) {
                        _title = value;
                        // print('標籤名稱：$_title');
                      },
                    ),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: TextFormField(
                      initialValue: _description,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        filled: true,
                        hintText: '請輸入任務備註',
                        labelText: '備註',
                      ),
                      onChanged: (value) {
                        _description = value;
                        // print('任務備註：$_description');
                      },
                    ),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('標籤：'),
                    trailing: DropdownButton(
                      value: _tag == 0 ? null : _tag,
                      hint: const Text(
                        '請選取標籤',
                        style: TextStyle(fontSize: 16),
                      ),
                      onChanged: (value) {
                        // print('value: $value');
                        _tag = value;
                        setStte(() {});
                      },
                      items: _dropdownItem,
                    ),
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                  child: const Text('確定', style: TextStyle(color: Colors.blue)),
                  onPressed: () {
                    _title = _title.trim();
                    _description = _description.trim();
                    // Task returnData;
                    if (_title.isNotEmpty) {
                      // returnData = Task(
                      //     title: _title, description: _description, tag: _tag);
                      t.title = _title;
                      t.description = _description;
                      t.tag = _tag;
                    }
                    Navigator.pop(context);
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
