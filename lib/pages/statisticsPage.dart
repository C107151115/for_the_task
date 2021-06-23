import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:for_the_task/appClass.dart';
import 'package:for_the_task/widgets/basicDialog.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class _CostsData {
  final String category;
  final int cost;

  const _CostsData(this.category, this.cost);
}

class StatisticsPage extends StatefulWidget {
  // constructor
  StatisticsPage({Key key}) : super(key: key);
  // create state
  @override
  _StatisticsPageState createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  // 一些畫面中的參數
  String _method = null;
  DateTime _startTime = DateTime(2021, 01, 01);
  DateTime _endTime = DateTime.now();

  // 第一列下拉式選單的內容
  static const methods = <String>['圓餅圖', '長條圖'];
  final List<DropdownMenuItem> _dropdownMethods = methods
      .map((String value) => DropdownMenuItem(
            value: value,
            child: Text(value),
          ))
      .toList();

  // 日期選擇器
  void _selectStartDate() async {
    final DateTime newDate = await showDatePicker(
      context: context,
      initialDate: _startTime,
      firstDate: DateTime(2020, 1),
      lastDate: DateTime.now(),
      helpText: '選取日期',
    );
    if (newDate != null) {
      setState(() {
        _startTime = newDate;
      });
    }
  }

  void _selectEndDate() async {
    final DateTime newDate = await showDatePicker(
      context: context,
      initialDate: _endTime,
      firstDate: DateTime(2020, 1),
      lastDate: DateTime.now(),
      helpText: '選取日期',
    );
    if (newDate != null) {
      setState(() {
        _endTime = newDate;
      });
    }
  }

  // DateTime 型態轉乘字串型態的格式 轉換請用 dateFormatter.format(DateTime變數)
  final DateFormat dateFormatter = DateFormat('yyyy/MM/dd');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Container(
          child: Text("任務統計", style: TextStyle(fontSize: 24)),
        ),
      ),
      body: Center(
        child: Column(
          // mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ListTile(
              title: const Text('統計圖選擇：', style: TextStyle(fontSize: 16)),
              trailing: DropdownButton(
                  value: _method,
                  hint: const Text('請選擇種類', style: TextStyle(fontSize: 16)),
                  onChanged: (var newValue) {
                    setState(() {
                      _method = newValue.toString();
                    });
                  },
                  items: _dropdownMethods),
            ),
            ListTile(
              title: const Text('選擇開始日期', style: TextStyle(fontSize: 16)),
              trailing: TextButton(
                onPressed: _selectStartDate,
                child: Text(dateFormatter.format(_startTime),
                    style: TextStyle(fontSize: 20)),
              ),
            ),
            ListTile(
              title: const Text('選擇結束日期', style: TextStyle(fontSize: 16)),
              trailing: TextButton(
                onPressed: _selectEndDate,
                child: Text(dateFormatter.format(_endTime),
                    style: TextStyle(fontSize: 20)),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    if (_method == '圓餅圖') {
                      Navigator.pushNamed(
                        context,
                        '/StatisticsPage/PieChart',
                      );
                    } else if (_method == '長條圖') {
                      Navigator.pushNamed(context, '/StatisticsPage/BarChart');
                    } else {
                      showBasicDialog(
                          context: context, title: '錯誤', content: '請選擇統計圖種類。');
                    }
                  },
                  child: Text('進行統計', style: TextStyle(fontSize: 20)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

// 長條圖統計結果
class BarChartResultPage extends StatefulWidget {
  BarChartResultPage({Key key}) : super(key: key);

  @override
  _BarChartResultPageState createState() => _BarChartResultPageState();
}

class _BarChartResultPageState extends State<BarChartResultPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('長條圖統計結果'),
      ),
      body: Container(
        alignment: Alignment.center,
        child: Column(
          children: <Widget>[
            Text('長條圖結果'),
          ],
        ),
      ),
    );
  }
}

class PieChartData {
  PieChartData(this.x, this.y, [this.color]);
  final String x;
  final int y;
  final Color color;
}

class PieChartResultPage extends StatefulWidget {
  // List<PieChartData> mydata;
  PieChartResultPage({
    Key key,
  }) : super(key: key);

  @override
  _PieChartResultPageState createState() => _PieChartResultPageState();
}

class _PieChartResultPageState extends State<PieChartResultPage> {
  static List<PieChartData> data;
  Future _future;

  _futureInit() async {
    data = await createPieChartData();
    print(data.length);
    setState(() {});
    return true;
  }

  @override
  void initState() {
    print('initState');
    // TODO: implement initState
    _future = _futureInit();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('圓餅圖統計結果'),
      ),
      body: Container(
          alignment: Alignment.center,
          child:
              //Column(
              //children: <Widget>[
              // Text('圓餅圖結果'),
              ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: double.infinity),

                  //Initialize chart
                  child: FutureBuilder(
                    future: _future,
                    builder: (context, AsyncSnapshot snapshot) {
                      switch (snapshot.connectionState) {
                        case ConnectionState.waiting:
                          return Center(
                            child: Text(
                              '統計中...',
                              style: TextStyle(fontSize: 16),
                            ),
                          );
                        default:
                          return SfCircularChart(
                              // title: ChartTitle(text: '結果圖'),
                              legend: Legend(
                                  iconHeight: 18,
                                  iconWidth: 18,
                                  overflowMode: LegendItemOverflowMode.wrap,
                                  textStyle: TextStyle(fontSize: 20),
                                  isVisible: true,
                                  position: LegendPosition.bottom),
                              tooltipBehavior: TooltipBehavior(enable: true),
                              series: <PieSeries>[
                                // Initialize line series
                                PieSeries<PieChartData, String>(
                                    // Enables the tooltip for individual series
                                    enableTooltip: true,
                                    explode: true,
                                    explodeIndex: 0,
                                    explodeOffset: '10%',
                                    radius: '150',
                                    dataSource: data,
                                    pointColorMapper: (PieChartData p, _) =>
                                        p.color,
                                    xValueMapper: (PieChartData p, _) => p.x,
                                    yValueMapper: (PieChartData p, _) => p.y,
                                    dataLabelMapper: (PieChartData p, _) => p.x,
                                    dataLabelSettings:
                                        DataLabelSettings(isVisible: true),
                                    animationDuration: 750)
                              ]);
                      }
                    },
                  ))
          //],
          //),
          ),
    );
  }
}

Future<List<PieChartData>> createPieChartData() async {
  List<PieChartData> result = [];
  DateTime today = DateTime.now();
  List<Tag> tags;
  List<Task> finished;
  List<Task> unfinished;

  Tag findTag(int id) {
    return tags.firstWhere((t) => t.id == id);
  }

  TagsHelper tagsHelper = TagsHelper();
  await tagsHelper.open();
  tags = await tagsHelper.getAllTags();
  Map<int, int> count = {};
  TasksHelper tasksHelper = TasksHelper(
      dataType: 'daily', y: today.year, m: today.month, d: today.day);
  await tasksHelper.open();
  finished = await tasksHelper.getAllFinishedTasks();
  unfinished = await tasksHelper.getAllUnfinishedTasks();
  // print('length of unfinished :${unfinished.length}');
  if (finished.length != null) {
    for (Task t in finished) {
      // print(t.title);
      // print('containsKey:' + count.containsKey(t.tag).toString());
      if (count.containsKey(t.tag)) {
        count.update(t.tag, (value) => value + 1);
      } else {
        count[t.tag] = 1;
      }
    }
  }
  count.forEach((key, value) {
    Tag x = findTag(key);
    result.add(PieChartData(x.name, value, Color(x.color)));
  });
  result.sort((a, b) => b.y.compareTo(a.y));
  result.add(PieChartData('未完成', unfinished.length, Colors.grey.shade300));
  return result;
}
