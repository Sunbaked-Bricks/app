import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<String> get _localPath async {
  final directory = await getApplicationDocumentsDirectory();

  return directory.path;
}

Future<File> get _localFile async {
  final path = await _localPath;
  return File('$path/test.txt');
}

Future<File> writeMessage(String message) async {
  final file = await _localFile;

  // Write the file
  return file.writeAsString(message);
}

Future<String> readMessage() async {
  try {
    final file = await _localFile;

    // Read the file
    final contents = await file.readAsString();

    return contents;
  } catch (e) {
    // If encountering an error, return 0
    return 'error reading file';
  }
}

Future<http.Response> createPOST(Object data) async {
  try {
    final response = await http.post(Uri.parse('http://192.168.1.1/info'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: data);

    return response;
  } on SocketException catch (e) {
    final http.Response ret = http.Response("Timeout", 408);
    return ret;
  } on TimeoutException catch (e) {
    final http.Response ret = http.Response("Timeout", 409);
    return ret;
  } on Error catch (e) {
    final http.Response ret = http.Response(e.stackTrace.toString(), 404);
    return ret;
  }
}

Future<http.Response> createGET() async {
  try {
    final response = await http.get(
      Uri.parse('http://192.168.1.1/getTemp'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    return response;
  } on SocketException catch (e) {
    final http.Response ret = http.Response("Timeout", 408);
    return ret;
  } on TimeoutException catch (e) {
    final http.Response ret = http.Response("Timeout", 409);
    return ret;
  } on Error catch (e) {
    final http.Response ret = http.Response(e.stackTrace.toString(), 404);
    return ret;
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SunBaked Proto',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.orange,
      ),
      home: const MyHomePage(title: 'SunBaked'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String inputTemp = "0";
  int test = 0;
  late String display = 'waiting';
  late http.Response postResp = http.Response("none", 204);
  http.Response getResp = http.Response("none", 204);
  late String indicator = "do you ever wonder why we are here?";
  late Timer clock;

  void _stop() async {
    Object data = jsonEncode(<String, String>{
      "command": "kill",
      "temp": "0",
    });
    postResp = await createPOST(data);
  }

  void _sendTemp(String temp) async {
    Object data = jsonEncode(<String, String>{
      "command": "none",
      "temp": temp,
    });
    postResp = await createPOST(data);
  }

  void _postMessage() async {
    getResp = await createGET();
    //postResp = await createPOST(display);
    //writeMessage("hello, are you there");
  }

  @override
  void initState() {
    super.initState();

    //10 second clock that runs continuously
    clock = Timer.periodic(const Duration(seconds: 10), (Timer t) {
      //send out post and get requests
      _postMessage();

      //after post and get, update screen to display information
      setState(() {
        if (getResp.statusCode == 200 && postResp.statusCode == 200) {
          indicator = "message sent succesfully, data retrieved succesfully";
          display = getResp.body;
        } else {
          int stat1 = postResp.statusCode;
          int stat2 = getResp.statusCode;
          indicator =
              "error sending message or data. Message code: $stat1 , Get request code: $stat2";
          if (getResp.statusCode == 200) {
            display = getResp.body;
          } else {
            display = "error $test";
          }
          test++;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              indicator,
            ),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
              Text(
                display,
                //style: Theme.of(context).textTheme.headlineMedium,
              ),
              TextButton(
                onPressed: _stop,
                child: const Text("STOP"),
              )
            ]),
            TextField(
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              onEditingComplete: () => _sendTemp(inputTemp),
              onChanged: (text) {
                inputTemp = text;
              },
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _postMessage,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
