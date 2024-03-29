import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'history.dart';
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

Future<http.Response> createPOST(Object data, String destination) async {
  try {
    final response =
        await http.post(Uri.parse('http://192.168.1.1/$destination'),
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

const List<Widget> materials = <Widget>[
  Text('LDPE'),
  Text('MDPE'),
  Text('HDPE')
];

const List<Widget> state = <Widget>[
  Text("STOP"),
  Text("START"),
];

void main() {
  runApp(const MyApp());
}

class SelectableButton extends StatefulWidget {
  const SelectableButton({
    super.key,
    required this.selected,
    this.style,
    required this.onPressed,
    required this.child,
  });

  final bool selected;
  final ButtonStyle? style;
  final VoidCallback? onPressed;
  final Widget child;

  @override
  State<SelectableButton> createState() => _SelectableButtonState();
}

class _SelectableButtonState extends State<SelectableButton> {
  late final MaterialStatesController statesController;

  @override
  void initState() {
    super.initState();
    statesController = MaterialStatesController(
        <MaterialState>{if (widget.selected) MaterialState.selected});
  }

  @override
  void didUpdateWidget(SelectableButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected != oldWidget.selected) {
      statesController.update(MaterialState.selected, widget.selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextButton(
      statesController: statesController,
      style: widget.style,
      onPressed: widget.onPressed,
      child: widget.child,
    );
  }
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
  bool userOverride = false;
  bool atHeat = false;
  int timeAtHeat = 0;
  bool start = false;
  final List<bool> _selectedPlastic = <bool>[false, false, false];
  bool warn = false;
  String inputTemp = "0";
  String file = "none";
  late String display = 'waiting';
  late http.Response postResp = http.Response("none", 204);
  http.Response getResp = http.Response("none", 204);
  late String indicator = "do you ever wonder why we are here?";
  late Timer clock;
  int desiredHeat = 125;

  void _updatePlastic(int p) {
    switch (p) {
      case 0:
        desiredHeat = 212;
        break;
      case 1:
        desiredHeat = 248;
        break;
      case 2:
        desiredHeat = 259;
        break;
    }
  }

  void _sendCommand(String instruction, String destination) async {
    Object data = jsonEncode(<String, String>{
      "command": instruction,
      "temp": "0",
    });
    postResp = await createPOST(data, destination);
  }

  void _postMessage() async {
    getResp = await createGET();
    //postResp = await createPOST(display);
    //writeMessage("hello, are you there");
    file = await readMessage();
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
            if (int.parse(getResp.body) >= 300) {
              _heatWarnDialogue();
            } else if (int.parse(getResp.body) >= desiredHeat) {
              atHeat = true;
            } else if (int.parse(getResp.body) < desiredHeat) {
              atHeat = false;
            }
          } else {
            display = "error";
          }
        }
        if (atHeat) {
          timeAtHeat += 10;
          if (timeAtHeat >= 1200 && !userOverride) {
            _doneCookingDialogue();
          }
        }
      });

      String saveData = jsonEncode(<String, String>{
        "post": postResp.statusCode.toString(),
        "get": getResp.statusCode.toString(),
        "temp": getResp.body
      });
      writeMessage(saveData);
    });
  }

  Future<void> _heatWarnDialogue() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('WARNING'),
          content: SingleChildScrollView(
            child: ListBody(
              children: const <Widget>[
                Text(
                    'The oven is too hot, plastic will burn at this temperature!'),
                Text('Would you like to send the shutdown signal to the oven?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Shutdown'),
              onPressed: () {
                _sendCommand("kill", "relayOff");
                Navigator.of(context).pop();
              },
            ),
            TextButton(
                onPressed: () => {Navigator.of(context).pop()},
                child: const Text("Wait"))
          ],
        );
      },
    );
  }

  Future<void> _doneCookingDialogue() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('DONE'),
          content: SingleChildScrollView(
            child: ListBody(
              children: const <Widget>[
                Text(
                    'The plastic has been at temperature for the desired time (20 minutes)'),
                Text('Would you like to send the shutdown signal to the oven?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Shutdown'),
              onPressed: () {
                _sendCommand("kill", "relayOff");
                Navigator.of(context).pop();
              },
            ),
            TextButton(
                onPressed: () {
                  userOverride = true;
                  Navigator.of(context).pop();
                },
                child: const Text("Wait"))
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const MyHistoryPage(
                        title: 'History',
                      )),
            );
          },
          child: const Icon(
            Icons.menu_book, // add custom icons also
          ),
        ),
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),

      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('Time at Target Heat',
                style: TextStyle(
                  fontSize: 25,
                )),
            Padding(
              padding: const EdgeInsets.only(bottom: 50),
              child: Text(
                Duration(seconds: timeAtHeat).toString().split('.')[0],
                style: const TextStyle(fontSize: 25),
              ),
            ),
            // ToggleButtons with a single selection.
            Text('Plastic Type', style: theme.textTheme.titleSmall),
            const SizedBox(height: 5),
            ToggleButtons(
              onPressed: (int index) {
                setState(() {
                  // The button that is tapped is set to true, and the others to false.
                  for (int i = 0; i < _selectedPlastic.length; i++) {
                    _selectedPlastic[i] = i == index;
                  }
                  _updatePlastic(index);
                });
              },
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              selectedBorderColor: Colors.orange[700],
              selectedColor: Colors.white,
              fillColor: Colors.orange[200],
              color: Colors.orange[400],
              constraints: const BoxConstraints(
                minHeight: 40.0,
                minWidth: 80.0,
              ),
              isSelected: _selectedPlastic,
              children: materials,
            ),
            Text(
              indicator,
            ),
            Text(
              display,
              style: const TextStyle(fontSize: 25),
              //style: Theme.of(context).textTheme.headlineMedium,
            ),
            SelectableButton(
              selected: start,
              style: ButtonStyle(
                foregroundColor: MaterialStateProperty.resolveWith<Color?>(
                  (Set<MaterialState> states) {
                    if (states.contains(MaterialState.selected)) {
                      return Colors.red[900];
                    }
                    return Colors.green[900]; // defer to the defaults
                  },
                ),
                backgroundColor: MaterialStateProperty.resolveWith<Color?>(
                  (Set<MaterialState> states) {
                    if (states.contains(MaterialState.selected)) {
                      return Colors.red[100];
                    }
                    return Colors.green[100];
                  },
                ),
              ),
              onPressed: () {
                setState(() {
                  if (start) {
                    _sendCommand("kill", "relayOff");
                  }
                  if (!start) {
                    _sendCommand("start", "relayOn");
                  }
                  start = !start;
                });
              },
              child: start ? state[0] : state[1],
            ),
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
