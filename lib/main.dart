import 'package:flutter/material.dart';
import 'package:for_the_task/pages/homePage.dart';
import 'package:for_the_task/pages/statisticsPage.dart';
import 'package:for_the_task/pages/tagManagementPage.dart';

void main() {
  runApp(MyApp());
}

var appColor = Colors.brown;

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: appColor,
      ),
      // home: MyHomePage(title: 'Home Page'),
      home: HomePage(),
      routes: {
        '/HomePage': (context) => HomePage(),
        '/TagManagementPage': (context) => TagManagementPage(),
        '/StatisticsPage': (context) => StatisticsPage(),
        '/StatisticsPage/BarChart': (context) => BarChartResultPage(),
        '/StatisticsPage/PieChart': (context) => PieChartResultPage(),
      },
    );
  }
}
