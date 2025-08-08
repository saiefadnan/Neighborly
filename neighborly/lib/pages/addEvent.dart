import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Addevent extends ConsumerStatefulWidget {
  final String title;
  const Addevent({super.key, required this.title});

  ConsumerState<Addevent> createState() => _AddeventState();
}

class _AddeventState extends ConsumerState<Addevent> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: AppBar());
  }
}
