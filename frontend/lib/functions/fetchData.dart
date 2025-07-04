import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';

final fetchData = FutureProvider<List<dynamic>>((ref) async {
  final response = await rootBundle.loadString('assets/data/post.json');
  final data = jsonDecode(response);
  return data['posts'];
});
