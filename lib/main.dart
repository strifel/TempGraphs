import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:charts_flutter/flutter.dart' as charts;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Temp Graphs',
      theme: ThemeData(
        primarySwatch: Colors.amber,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MainPage(),
    );
  }
}

class MainPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: !Platform.isMacOS ? AppBar(
        title: Text("Temp Graphs"),
        centerTitle: true,
      ) : null,
      body: SafeArea(
        child: StreamBuilder(
          stream: API.getTemps(),
          builder: (context, snapshot) {
            if (!snapshot.hasError && snapshot.data != null) {
              List<Widget> list = [];
              for (var sensor in snapshot.data) {
                list.add(
                    Sensor(sensor['sensor'], sensor['temperature'].toDouble()));
              }
              return ListView(
                // needs to be replaced, by that thing to put multiple next to each other
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Align(
                        alignment: AlignmentDirectional.topCenter,
                        child: Wrap(
                          children: list,
                        )
                    ),
                  )
                ],
              );
            } else if (snapshot.hasError) {
              return Text(snapshot.error.toString());
            } else {
              return Text("Loading!");
            }
          },
        ),
      )
    );
  }
}

class Sensor extends StatelessWidget {
  Sensor(this.name, this.temp);

  final String name;
  final double temp;

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.all(5),
        child: GestureDetector(
          child: Container(
              decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(5)),
                  color: Colors.amberAccent
              ),
              padding: EdgeInsets.all(15),
              child: Column(
                children: [
                  Text(name.substring(0, 1).toUpperCase() + name.substring(1),
                      style: TextStyle(fontSize: 15, color: Colors.red)),
                  Text(temp.toString() + "°C", style: TextStyle(fontSize: 50, color: Colors.green))
                ],
              )
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => Graphs(name)),
            );
          },
        )
    );
  }
}

class Graphs extends StatelessWidget {
  Graphs(this.name);
  final name;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(name.substring(0, 1).toUpperCase() + name.substring(1)),
        centerTitle: true,
      ),
      body: FutureBuilder(
        future: API.getTempDataSeries(name),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done && !snapshot.hasError) {
            return charts.TimeSeriesChart(snapshot.data, animate: true, primaryMeasureAxis: charts.NumericAxisSpec(tickProviderSpec: charts.BasicNumericTickProviderSpec(zeroBound: false)),);
          } else if (snapshot.hasError) {
            return Text(snapshot.error.toString());
          } else {
            return Text("Still loading!");
          }
        },
      ),
    );
  }

}

class API {
  static const String URL = "http://temperature:8002";

  static Stream<List> getTemps() async* {
    while (true) {
      var resp = await http.get("$URL/current/all");
      if (resp.statusCode != 200) yield [];
      yield jsonDecode(resp.body)['sensors'];
      if (resp.statusCode == 200) await new Future.delayed(const Duration(seconds : 30));
      else await new Future.delayed(const Duration(seconds: 2));
    }
  }

  static Future<List> getTempDataSeries(String sensor) async {
    var resp = await http.get("$URL/lastDay/$sensor");
    if (resp.statusCode != 200) return [];
    var data = jsonDecode(resp.body)['data'];
    List<charts.Series<dynamic, DateTime>> chart = [
      charts.Series(
          id: 'Temperature',
          colorFn: (_, __) => charts.MaterialPalette.red.shadeDefault,
          data: data,
          domainFn: (tempData, _) => DateTime.fromMillisecondsSinceEpoch(tempData['time'] * 1000),
          measureFn: (tempData, _) => tempData['temperature'].toDouble() as double
      )
    ];
    if (data[0]['humidity'] != null) {
      chart.add(charts.Series(
        id: 'Humidity',
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        data: data,
        domainFn: (tempData, _) => DateTime.fromMillisecondsSinceEpoch(tempData['time'] * 1000),
        measureFn: (tempData, _) => tempData['humidity'].toDouble() as double,
      ));
    }
    return chart;
  }
}

