import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/kanban_column.dart';
import '../models/task.dart';
import 'package:uuid/uuid.dart';

final boardProvider = StateNotifierProvider<BoardNotifier, List<KanbanColumn>>((
  ref,
) {
  return BoardNotifier();
});

class BoardNotifier extends StateNotifier<List<KanbanColumn>> {
  BoardNotifier()
    : super([
        KanbanColumn(id: 'todo', title: 'To Do', tasks: []),
        KanbanColumn(id: 'doing', title: 'Doing', tasks: []),
        KanbanColumn(id: 'done', title: 'Done', tasks: []),
      ]);

  void addTask(String columnId, String title) {
    final newTask = Task(id: const Uuid().v4(), title: title);
    state = [
      for (final col in state)
        if (col.id == columnId)
          col.copyWith(tasks: [...col.tasks, newTask])
        else
          col,
    ];
  }

  void moveTask(
    String fromColId,
    String toColId,
    Task task,
    int i, {
    required fromColumnId,
  }) {
    state = state.map((col) {
      if (col.id == fromColId) {
        return col.copyWith(
          tasks: col.tasks.where((t) => t.id != task.id).toList(),
        );
      } else if (col.id == toColId) {
        return col.copyWith(tasks: [...col.tasks, task]);
      } else {
        return col;
      }
    }).toList();
  }
}
