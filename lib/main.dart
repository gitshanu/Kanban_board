import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'widgets/kanban_board.dart';

void main() {
  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // title: 'Kanban Board',
      home: Scaffold(
        appBar: AppBar(title: Text('')),
        body: KanbanBoard(),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
