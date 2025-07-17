import 'package:freezed_annotation/freezed_annotation.dart';
import 'task.dart';

part 'kanban_column.freezed.dart';
part 'kanban_column.g.dart';

@freezed
class KanbanColumn with _$KanbanColumn {
  const factory KanbanColumn({
    required String id,
    required String title,
    required List<Task> tasks,
  }) = _KanbanColumn;

  factory KanbanColumn.fromJson(Map<String, dynamic> json) =>
      _$KanbanColumnFromJson(json);
}
