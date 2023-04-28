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

class MyHistoryPage extends StatefulWidget {
  final String title;
  const MyHistoryPage({super.key, required this.title});

  @override
  State<MyHistoryPage> createState() => _MyHistoryPageState();
}

class _MyHistoryPageState extends State<MyHistoryPage> {
  late String file;
  String indicator = "";

  void _getFile() async {
    file = await readMessage();
    indicator = file;
  }

  void _updateHistory() {
    setState(() {
      _getFile();
    });
  }

  @override
  void initState() {
    super.initState();
    _updateHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("History"),
        leading: GestureDetector(
          onTap: () {
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
      floatingActionButton: FloatingActionButton(
        onPressed: _updateHistory,
        tooltip: 'Refresh',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
