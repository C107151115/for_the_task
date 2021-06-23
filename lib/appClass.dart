import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

const int defalutColorString = 0xff9e9e9e;

// 標籤
class Tag {
  int id = -1;
  String name = '';
  int color = defalutColorString;
  int available = 1;

  Tag({
    this.id: -1,
    this.name: '',
    this.color: defalutColorString,
    this.available: 1,
  });

  // 資料列轉實例
  factory Tag.fromMap(Map<String, dynamic> raw) {
    return new Tag(
        id: raw['id'],
        name: raw['name'],
        color: raw['color'],
        available: raw['available']);
  }

  // 實例屬性轉Map
  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'color': color, 'available': available};
  }
}

// 預設標籤
Tag defaultTag =
    Tag(id: 0, name: 'DEFAULT', color: Colors.grey.value, available: 1);

// 標籤範例
List<Tag> tagListExample = [
  Tag(id: 1, name: 'example tag 1', color: Colors.red.value),
  Tag(id: 2, name: 'example tag 2', color: Colors.orange.value),
  Tag(id: 3, name: 'example tag 3', color: Colors.yellow.value),
  Tag(id: 4, name: 'example tag 4', color: Colors.green.value),
  Tag(id: 5, name: 'example tag 5', color: Colors.blue.value),
  Tag(id: 6, name: 'example tag 6', color: Colors.indigo.value),
  Tag(id: 7, name: 'example tag 7', color: Colors.purple.value),
];

// 任務
class Task {
  int id = -1; // 編號
  int state = 0; // 完成狀態
  String title; // 標題
  String description; // 描述
  int tag = 0; // 標籤

  Task({
    this.id: -1,
    this.state: 0,
    this.title: '',
    this.description: '',
    this.tag: 0,
  });

  // 資料列轉實例
  factory Task.fromMap(Map<String, dynamic> row) {
    return Task(
      id: row['id'],
      state: row['state'],
      title: row['title'],
      description: row['description'],
      tag: row['tag'],
    );
  }

  // 實例屬性轉Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'state': state,
      'title': title,
      'description': description,
      'tag': tag
    };
  }
}

// 測試用的範例任務
List<Task> taskListExample = [
  Task(id: 1, title: 'task1', description: 'task 1 備註'),
  Task(id: 2, title: 'task2', description: 'task 2 備註'),
  Task(id: 3, title: 'task3', description: 'task 3 備註'),
  Task(id: 4, title: 'task4', description: 'task 4 備註'),
  Task(id: 5, title: 'task5', description: 'task 5 備註'),
  Task(id: 6, title: 'task6', description: 'task 6 備註'),
  Task(id: 7, title: 'task7', description: 'task 7 備註'),
  Task(id: 8, title: 'task8', description: 'task 8 備註'),
];

class TagsHelper {
  final String databaseName = 'Tags.db';
  final String tableName = 'Tags';
  Database database;
  TagsHelper() {
    // print('create helper success. (in instance)');
  }

  // 開資料庫
  open() async {
    String path = join(await getDatabasesPath(), databaseName);
    // await deleteDatabase(path); //刪除現有的Tags資料庫
    database = await openDatabase(path, version: 1,
        onCreate: (Database db, int version) async {
      // 建立Tags表
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $tableName (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          color INTEGER,
          available INTEGER
        )
        ''');
      // 插入預設標籤
      await db.rawInsert(
          'INSERT INTO $tableName (id, name, color, available) VALUES(?, ?, ?, ?)',
          [
            defaultTag.id,
            defaultTag.name,
            defaultTag.color,
            defaultTag.available
          ]);
      print('成功建表');
      for (Tag t in tagListExample) {
        await db.rawInsert(
            'INSERT INTO $tableName (id, name, color, available) VALUES(?, ?, ?, ?)',
            [t.id, t.name, t.color, t.available]);
      }
      print('成功插入預設標籤');
    });
  }

  // 新增Tag
  Future<int> addTag(Tag t) async {
    await this.database.rawInsert(
        'INSERT INTO $tableName (name, color, available) VALUES(?, ?, ?)',
        [t.name, t.color, t.available]);
    List tagRow = await database
        .rawQuery('SELECT id FROM $tableName ORDER BY id DESC LIMIT 1');
    t.id = tagRow[0]['id'];
    return tagRow[0]['id'];
  }

  // 修改標籤
  updateTag(Tag t) async {
    print('修改id為' + t.id.toString() + '的標籤');
    await database.rawUpdate(
      "UPDATE $tableName SET name='${t.name}', color=${t.color.toString()}, available=${t.available} WHERE id=${t.id}",
    );
  }

  deleteTag(int id) async {
    print('將id為${id.toString()}的標籤轉為不可選用的狀態');
    await database
        .rawUpdate("UPDATE $tableName SET available=? WHERE id=?", [0, id]);
  }

  // 用id查詢單個標籤 回傳Tag實例
  Future<Tag> getTagById(int id) async {
    List queryResult =
        await database.rawQuery("SELECT * FROM $tableName WHERE id=?", [id]);
    Tag t = Tag.fromMap(queryResult[0]);
    return t;
  }

  // 查詢所有可選用的標籤
  Future<List<Tag>> getAllAvailableTags() async {
    print('正在查詢所有可選用的標籤');
    List queryResult =
        await database.rawQuery("SELECT * FROM $tableName WHERE available=1");
    List<Tag> result = [];
    for (Map<String, dynamic> tagRow in queryResult) {
      // Tag t = Tag.fromMap(tagRow);
      result.add(Tag.fromMap(tagRow));
    }
    print('查詢到有' + result.length.toString() + '個可用標籤');
    return result;
  }

  // 查詢所有標籤(包含不可選用的)
  Future<List<Tag>> getAllTags() async {
    print('正在查詢所有的標籤');
    List<Map<String, dynamic>> queryResult =
        await database.rawQuery("SELECT * FROM $tableName");
    List<Tag> result = [];
    for (Map<String, dynamic> tagRow in queryResult) {
      result.add(Tag.fromMap(tagRow));
    }
    print('查詢到有' + result.length.toString() + '個標籤');
    return result;
  }

  Future<List<String>> getAllTagsName() async {
    List<Map<String, dynamic>> queryResult =
        await database.rawQuery("SELECT name FROM $tableName");
    List<String> result = [];
    for (Map<String, dynamic> tagRow in queryResult) {
      result.add(tagRow['name']);
    }
    return result;
  }
}

class TasksHelper {
  String databaseName = '';
  String tableName = '';
  String dataType;
  Database database;
  TasksHelper(
      {@required this.dataType,
      int y: 0,
      int m: 0,
      int d: 0,
      String custom: ''}) {
    switch (dataType) {
      case 'daily':
        databaseName = 'daily_${y.toString()}';
        tableName = 'daily_${m.toString()}_${d.toString()}';
        print('對$databaseName的$tableName進行處理。');
        break;
      case 'monthly':
        databaseName = 'monthly${y.toString()}';
        tableName = 'monthly_${m.toString()}';
        print('對$databaseName的$tableName進行處理。');
        break;
      case 'yearly':
        databaseName = 'yearly';
        tableName = 'yearly_${y.toString()}';
        print('對$databaseName的$tableName進行處理。');
        break;
      default:
        databaseName = 'custom';
        tableName = 'custom_${custom}';
        print('對$databaseName的$tableName進行處理。');
        print('dataType 錯誤');
    }
  }

  // 開資料庫
  open() async {
    String path = join(await getDatabasesPath(), databaseName);
    // await deleteDatabase(path); //刪除現有的Tags資料庫
    database = await openDatabase(path, version: 1,
        onCreate: (Database db, int version) async {
      // 建立Tags表
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $tableName (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          state INTEGER,
          title TEXT,
          description TEXT,
          tag INTEGER
        )
        ''');
      print('成功建表');
    });
    await database.execute('''
        CREATE TABLE IF NOT EXISTS $tableName (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          state INTEGER,
          title TEXT,
          description TEXT,
          tag INTEGER
        )
        ''');
  }

  // 新增Task
  Future<int> addTask(Task t) async {
    await database.rawInsert(
        'INSERT INTO $tableName (title, description, tag) VALUES(?, ?, ?)',
        [t.title, t.description, t.tag]);
    List tagRow = await database
        .rawQuery('SELECT id FROM $tableName ORDER BY id DESC LIMIT 1');
    t.id = tagRow[0]['id'];
    return tagRow[0]['id'];
  }

  // 修改Task
  updateTask(Task t) async {
    print('修改id為' + t.id.toString() + '的任務');
    await database.rawUpdate(
      "UPDATE $tableName SET title='${t.title}', description='${t.description}', tag=${t.tag.toString()} WHERE id=${t.id.toString()}",
    );
  }

  // 刪除Task
  deleteTask(int id) async {
    print('將id為${id.toString()}的任務');
    await database.rawDelete("DELETE FROM $tableName WHERE id=$id");
  }

  // 設標籤為完成狀態
  setTaskFinished(Task t) async {
    t.state = 1;
    await database
        .rawUpdate("UPDATE $tableName SET state=${t.state} WHERE id=${t.id}");
  }

  // 設標籤為完成狀態
  setTaskUnfinished(Task t) async {
    t.state = 0;
    await database
        .rawUpdate("UPDATE $tableName SET state=${t.state} WHERE id=${t.id}");
  }

  // 用id查詢單個Task 回傳Task實例
  Future<Task> getTaskById(int id) async {
    List queryResult =
        await database.rawQuery("SELECT * FROM $tableName WHERE id=?", [id]);
    Task t = Task.fromMap(queryResult[0]);
    return t;
  }

  // 查詢所有Task
  Future<List<Task>> getAllTasks() async {
    List<Map<String, dynamic>> queryResult =
        await database.rawQuery("SELECT * FROM $tableName");
    List<Task> result = [];
    for (Map<String, dynamic> taskRow in queryResult) {
      result.add(Task.fromMap(taskRow));
    }
    print('查詢到有' + result.length.toString() + '任務');
    return result;
  }

  // 查詢所有已完成的Task
  Future<List<Task>> getAllFinishedTasks() async {
    List<Map<String, dynamic>> queryResult =
        await database.rawQuery("SELECT * FROM  $tableName  WHERE  state=1");
    List<Task> result = [];
    for (Map<String, dynamic> taskRow in queryResult) {
      result.add(Task.fromMap(taskRow));
    }
    print('查詢到有' + queryResult.length.toString() + '已完成的任務');
    return result;
  }

  // 查詢所有未完成的Task
  Future<List<Task>> getAllUnfinishedTasks() async {
    List<Map<String, dynamic>> queryResult =
        await database.rawQuery("SELECT * FROM $tableName");
    List<Task> result = [];
    for (Map<String, dynamic> taskRow in queryResult) {
      result.add(Task.fromMap(taskRow));
    }
    print('len result: ${result.length}');
    await Future.delayed(Duration(microseconds: 100));
    List<Task> resultT = [];
    queryResult =
        await database.rawQuery("SELECT * FROM $tableName WHERE state=1");
    for (Map<String, dynamic> taskRow in queryResult) {
      resultT.add(Task.fromMap(taskRow));
    }
    print('len resultT: ${resultT.length}');
    for (Task t in resultT) {
      result.removeWhere((element) => element.id == t.id);
    }

    // List<Map<String, dynamic>> queryResult =
    //     await database.rawQuery("SELECT * FROM  $tableName  WHERE state=0");
    // List<Task> result = [];
    // for (Map<String, dynamic> taskRow in queryResult) {
    //   result.add(Task.fromMap(taskRow));
    // }

    print('查詢到有' + result.length.toString() + '已完成的任務');
    return result;
  }
}
