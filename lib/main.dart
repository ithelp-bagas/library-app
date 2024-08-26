import 'package:dio/dio.dart';
import 'package:fingerspot_library/failed_login.dart';
import 'package:fingerspot_library/webview_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterDownloader.initialize(
    debug: true, // optional: set to false to disable printing logs to console
    ignoreSsl: true, // option: set to true to allow SSL errors (useful for testing)
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xff3F87B9)),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Fingerspot Library'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: ElevatedButton(
          child: const Text(
            "Open Webview",
            style: TextStyle(
              fontSize: 20.0
            ),
          ),
          onPressed: () {
            authenticate();
            // Navigator.push(context, MaterialPageRoute(builder: (context)=> const WebviewScreen()));
          },
        )
      ),
    );
  }

  @override
  void initState() {
    super.initState();
  }

  Future<void> authenticate() async {
    String encodeParam = "FINfQ==c2VyX2lkIjogMzY0NzMsInR5cGUiOiAyLCJjb21wYW55X2lkIjogMTI3NzYsInBhY2thZ2VfaWQiOiA2LCJlbXBfaWQiOiA5OTc4NSwiZW1wX3BpbiI6ICIxIiwibW9kdWxlX2lkIjogMywiaXBfYWRkcmVzcyI6ICIxOTIuMTY4LjEuOTEiLCJwbGF0Zm9ybSI6ICJhbmRyb2lkIiwibGFuZ3VhZ2UiOiAiZW4iLCJ0aGVtZSI6ICJsaWdodCIsImVtYWlsIjogImhlcnUuZmluZ2Vyc3BvdEBnbWFpbC5jb20ieyJ1SPOT";
    Dio dio = Dio();
    String url = "http://192.168.1.141/fingerspot-library/api/authenticate/?data=";

    try{
      var response = await dio.get(url + encodeParam);

        if(response.statusCode == 200) {
        var data = response.data;
          Navigator.push(context, MaterialPageRoute(builder: (context) => WebviewScreen(token: data['token'],)));
      } else {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const FailedLogin()));
      }
    } catch(e) {
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => const FailedLogin()));
      throw Exception(e);
    }
  }
}
