import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';

final fetchData = FutureProvider.family<List<Map<String, dynamic>>, String>((
  ref,
  type,
) async {
  final response = await rootBundle.loadString('assets/data/$type.json');
  final data = jsonDecode(response);

  return (data[type] as List).cast<Map<String, dynamic>>();
});
