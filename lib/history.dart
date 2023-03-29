import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';

import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<String> get _localPath async {
  final directory = await getApplicationDocumentsDirectory();

  return directory.path;
}

Future<File> get _localFile async {
  final path = await _localPath;
  return File('$path/data.txt');
}

Future<File> writeMessage(String message) async {
  final file = await _localFile;

  // Write the file
  return file.writeAsString(message, mode: FileMode.append);
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
/*
class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SunBaked Proto',
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      home: const MyHistoryPage(title: 'SunBaked'),
    );
  }
}
*/

class MyHistoryPage extends StatefulWidget {
  final String title;
  const MyHistoryPage({super.key, required this.title});

  @override
  State<MyHistoryPage> createState() => _MyHistoryPageState();
}

class _MyHistoryPageState extends State<MyHistoryPage> {
  late String file;

  late String indicator = "do you ever wonder why we are here?";
  late Timer clock;

  void _getFile() async {
    file = await readMessage();
  }

  @override
  void initState() {
    super.initState();

    _getFile();
    //10 second clock that runs continuously
    clock = Timer.periodic(const Duration(seconds: 10), (Timer t) {
      _getFile();

      //after post and get, update screen to display information
      setState(() {
        indicator = file;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("History"),
        leading: GestureDetector(
          onTap: () {
            clock.cancel();
            Navigator.pop(context);
          },
          child: const Icon(
            Icons.arrow_back, // add custom icons also
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                child: Text(indicator),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
