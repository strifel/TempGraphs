import 'dart:async';
import 'dart:convert';
import 'dart:io';

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
      appBar: AppBar(
        title: Text("Temp Graphs"),
        centerTitle: true,
      ),
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
        )
    );
  }
}

class API {
  static Stream<List> getTemps() async* {
    while (true) {
      var resp = await http.get("http://192.168.1.79:8002/current/all");
      if (resp.statusCode != 200) yield [];
      yield jsonDecode(resp.body)['sensors'];
      await new Future.delayed(const Duration(seconds : 30));
    }
  }
}

