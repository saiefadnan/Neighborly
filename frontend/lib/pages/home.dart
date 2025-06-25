import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});
  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String result = "hello";
  String url = "http://10.0.2.2:4000/api/test";

  Future<void> fetchData() async {
    //api testing
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'message': 'Hello from Flutter!'}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        result = data['message'];
      });
    } else {
      setState(() {
        result = 'operation failed: ${response.statusCode}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(widget.title),
              ElevatedButton(
                child: Text("Click to test backend"),
                onPressed: () {
                  fetchData();
                },
              ),
              Text(result),
            ],
          ),
        ),
      ),
    );
  }
}
