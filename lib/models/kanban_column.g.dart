// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kanban_column.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$KanbanColumnImpl _$$KanbanColumnImplFromJson(Map<String, dynamic> json) =>
    _$KanbanColumnImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      tasks: (json['tasks'] as List<dynamic>)
          .map((e) => Task.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$KanbanColumnImplToJson(_$KanbanColumnImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'tasks': instance.tasks,
    };
