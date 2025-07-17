import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/kanban_provider.dart';
import '../models/task.dart';

class KanbanBoard extends ConsumerWidget {
  const KanbanBoard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ignore: deprecated_member_use
    final board = ref.watch(boardProvider);
    final boardNotifier = ref.read(boardProvider.notifier);
    final theme = Theme.of(context);

    // NEW: WIP Limits - Define WIP limits for each column (e.g., max 5 tasks)
    final Map<String, int> wipLimits = {
      for (var column in board) column.id: 5, // Adjust limits as needed
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Kanban Board',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 24),
        ),
        elevation: 2,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: Container(
        color: theme.colorScheme.surface,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: board.map((column) {
            // NEW: WIP Limits - Check if column exceeds WIP limit
            final bool exceedsWipLimit =
                column.tasks.length > (wipLimits[column.id] ?? 5);
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary.withValues(alpha: 0.8),
                            theme.colorScheme.primary,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        // NEW: WIP Limits - Highlight header if WIP limit exceeded
                        border: exceedsWipLimit
                            ? Border.all(
                                color: theme.colorScheme.error,
                                width: 2,
                              )
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            column.title,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimary,
                            ),
                          ),
                          Row(
                            children: [
                              // NEW: WIP Limits - Show current count vs limit
                              Text(
                                '${column.tasks.length}/${wipLimits[column.id]}',
                                style: TextStyle(
                                  color: exceedsWipLimit
                                      ? theme.colorScheme.error
                                      : theme.colorScheme.onPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Chip(
                                label: Text(
                                  '${column.tasks.length}',
                                  style: TextStyle(
                                    color: theme.colorScheme.onPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                backgroundColor:
                                    theme.colorScheme.primaryContainer,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: DragTarget<Task>(
                        // NEW: WIP Limits - Prevent dropping if WIP limit exceeded
                        onWillAcceptWithDetails: (details) {
                          return !exceedsWipLimit;
                        },
                        onAcceptWithDetails: (details) {
                          final task = details.data;
                          final sourceColumn = board.firstWhere(
                            (col) => col.tasks.contains(task),
                            orElse: () => column,
                          );
                          final renderBox =
                              context.findRenderObject() as RenderBox;
                          final localOffset = renderBox.globalToLocal(
                            details.offset,
                          );
                          final dropIndex = _calculateDropIndex(
                            context,
                            localOffset,
                            column.tasks.length,
                            sourceColumn.id == column.id,
                            task,
                            column.tasks,
                          );
                          boardNotifier.moveTask(
                            sourceColumn.id,
                            column.id,
                            task,
                            dropIndex,
                            fromColumnId: sourceColumn.id,
                          );
                          debugPrint(
                            'Moved task "${task.title}" from ${sourceColumn.id} to ${column.id} at index $dropIndex',
                          );
                        },
                        builder: (context, candidateData, rejectedData) =>
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color:
                                    candidateData.isNotEmpty && !exceedsWipLimit
                                    ? theme.colorScheme.primary.withValues(
                                        alpha: 0.1,
                                      )
                                    : theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color:
                                      candidateData.isNotEmpty &&
                                          !exceedsWipLimit
                                      ? theme.colorScheme.primary
                                      : Colors.grey[300]!,
                                  width: 2,
                                ),
                              ),
                              child: column.tasks.isEmpty
                                  ? Center(
                                      child: Text(
                                        'No tasks yet',
                                        style: TextStyle(
                                          color: theme.colorScheme.onSurface
                                              .withValues(alpha: 0.6),
                                          fontSize: 16,
                                        ),
                                      ),
                                    )
                                  : ListView.builder(
                                      itemCount: column.tasks.length,
                                      itemBuilder: (context, index) {
                                        final task = column.tasks[index];
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 6,
                                          ),
                                          child: Draggable<Task>(
                                            key: ValueKey(task.id),
                                            data: task,
                                            feedback: Material(
                                              elevation: 4,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Container(
                                                width: 250,
                                                padding: const EdgeInsets.all(
                                                  12,
                                                ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      theme.colorScheme.primary,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  task.title,
                                                  style: TextStyle(
                                                    color: theme
                                                        .colorScheme
                                                        .onPrimary,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            childWhenDragging: Opacity(
                                              opacity: 0.3,
                                              child: TaskCard(
                                                task: task,
                                                // NEW: Task Details View - Pass onTap handler
                                                onTap: () =>
                                                    _showTaskDetailsDialog(
                                                      context,
                                                      task,
                                                    ),
                                              ),
                                            ),
                                            child: TaskCard(
                                              task: task,
                                              // NEW: Task Details View - Pass onTap handler
                                              onTap: () =>
                                                  _showTaskDetailsDialog(
                                                    context,
                                                    task,
                                                  ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context, ref),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        tooltip: 'Add New Task',
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  int _calculateDropIndex(
    BuildContext context,
    Offset localOffset,
    int taskCount,
    bool isSameColumn,
    Task draggedTask,
    List<Task> tasks,
  ) {
    final box = context.findRenderObject() as RenderBox;
    final itemHeight = box.size.height / (taskCount == 0 ? 1 : taskCount + 1);
    int dropIndex = (localOffset.dy / itemHeight).floor().clamp(0, taskCount);
    if (isSameColumn) {
      final currentIndex = tasks.indexOf(draggedTask);
      if (currentIndex >= 0) {
        if (currentIndex < dropIndex) {
          dropIndex--;
        } else if (currentIndex == dropIndex) {
          dropIndex = currentIndex;
        }
      }
    }
    return dropIndex;
  }

  void _showAddTaskDialog(BuildContext context, WidgetRef ref) {
    final board = ref.watch(boardProvider);
    final boardNotifier = ref.read(boardProvider.notifier);
    String selectedColumnId = board.first.id;
    final titleController = TextEditingController();
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: theme.colorScheme.surface,
        title: const Text(
          'Add New Task',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'Task Title',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedColumnId,
              items: board
                  .map(
                    (col) =>
                        DropdownMenuItem(value: col.id, child: Text(col.title)),
                  )
                  .toList(),
              onChanged: (val) {
                if (val != null) selectedColumnId = val;
              },
              decoration: InputDecoration(
                labelText: 'Select Column',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: theme.colorScheme.secondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final title = titleController.text.trim();
              if (title.isNotEmpty) {
                boardNotifier.addTask(selectedColumnId, title);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Add Task'),
          ),
        ],
      ),
    );
  }

  // NEW: Task Details View - Dialog to show task details
  void _showTaskDetailsDialog(BuildContext context, Task task) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: theme.colorScheme.surface,
        title: Text(
          task.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Details:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Task ID: ${task.id}',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(color: theme.colorScheme.secondary),
            ),
          ),
        ],
      ),
    );
  }
}

class TaskCard extends StatelessWidget {
  final Task task;
  // NEW: Task Details View - Add onTap callback
  final VoidCallback? onTap;

  const TaskCard({super.key, required this.task, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: theme.colorScheme.surface,
      // NEW: Task Details View - Add GestureDetector for click handling
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.task_alt, color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../providers/kanban_provider.dart';
// import '../models/task.dart';

// class KanbanBoard extends ConsumerWidget {
//   const KanbanBoard({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     // ignore: deprecated_member_use
//     final board = ref.watch(boardProvider);
//     final boardNotifier = ref.read(boardProvider.notifier);
//     final theme = Theme.of(context);

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           'Kanban Board',
//           style: TextStyle(fontWeight: FontWeight.w600, fontSize: 24),
//         ),
//         elevation: 2,
//         backgroundColor: theme.colorScheme.primary,
//         foregroundColor: theme.colorScheme.onPrimary,
//       ),
//       body: Container(
//         color: theme.colorScheme.surface,
//         child: Row(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: board.map((column) {
//             return Expanded(
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 12,
//                   vertical: 16,
//                 ),
//                 child: Column(
//                   children: [
//                     Container(
//                       padding: const EdgeInsets.all(12),
//                       decoration: BoxDecoration(
//                         gradient: LinearGradient(
//                           colors: [
//                             theme.colorScheme.primary.withValues(alpha: 0.8),
//                             theme.colorScheme.primary,
//                           ],
//                           begin: Alignment.topLeft,
//                           end: Alignment.bottomRight,
//                         ),
//                         borderRadius: BorderRadius.circular(12),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.black.withValues(alpha: 0.1),
//                             blurRadius: 8,
//                             offset: const Offset(0, 4),
//                           ),
//                         ],
//                       ),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Text(
//                             column.title,
//                             style: TextStyle(
//                               fontSize: 20,
//                               fontWeight: FontWeight.bold,
//                               color: theme.colorScheme.onPrimary,
//                             ),
//                           ),
//                           Chip(
//                             label: Text(
//                               '${column.tasks.length}',
//                               style: TextStyle(
//                                 color: theme.colorScheme.onPrimary,
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                             backgroundColor: theme.colorScheme.primaryContainer,
//                             padding: const EdgeInsets.symmetric(horizontal: 8),
//                           ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     Expanded(
//                       child: DragTarget<Task>(
//                         onAcceptWithDetails: (details) {
//                           final task = details.data;
//                           final sourceColumn = board.firstWhere(
//                             (col) => col.tasks.contains(task),
//                             orElse: () => column,
//                           );
//                           final renderBox =
//                               context.findRenderObject() as RenderBox;
//                           final localOffset = renderBox.globalToLocal(
//                             details.offset,
//                           );
//                           final dropIndex = _calculateDropIndex(
//                             context,
//                             localOffset,
//                             column.tasks.length,
//                             sourceColumn.id == column.id,
//                             task,
//                             column.tasks,
//                           );
//                           boardNotifier.moveTask(
//                             sourceColumn.id,
//                             column.id,
//                             task,
//                             dropIndex,
//                             fromColumnId: sourceColumn.id,
//                           );
//                           debugPrint(
//                             'Moved task "${task.title}" from ${sourceColumn.id} to ${column.id} at index $dropIndex',
//                           );
//                         },
//                         builder: (context, candidateData, rejectedData) =>
//                             AnimatedContainer(
//                               duration: const Duration(milliseconds: 200),
//                               padding: const EdgeInsets.all(12),
//                               decoration: BoxDecoration(
//                                 color: candidateData.isNotEmpty
//                                     ? theme.colorScheme.primary.withValues(
//                                         alpha: 0.1,
//                                       )
//                                     : theme.colorScheme.surface,
//                                 borderRadius: BorderRadius.circular(12),
//                                 border: Border.all(
//                                   color: candidateData.isNotEmpty
//                                       ? theme.colorScheme.primary
//                                       : Colors.grey[300]!,
//                                   width: 2,
//                                 ),
//                               ),
//                               child: column.tasks.isEmpty
//                                   ? Center(
//                                       child: Text(
//                                         'No tasks yet',
//                                         style: TextStyle(
//                                           color: theme.colorScheme.onSurface
//                                               .withValues(alpha: 0.6),
//                                           fontSize: 16,
//                                         ),
//                                       ),
//                                     )
//                                   : ListView.builder(
//                                       itemCount: column.tasks.length,
//                                       itemBuilder: (context, index) {
//                                         final task = column.tasks[index];
//                                         return Padding(
//                                           padding: const EdgeInsets.symmetric(
//                                             vertical: 6,
//                                           ),
//                                           child: Draggable<Task>(
//                                             key: ValueKey(task.id),
//                                             data: task,
//                                             feedback: Material(
//                                               elevation: 4,
//                                               borderRadius:
//                                                   BorderRadius.circular(8),
//                                               child: Container(
//                                                 width: 250,
//                                                 padding: const EdgeInsets.all(
//                                                   12,
//                                                 ),
//                                                 decoration: BoxDecoration(
//                                                   color:
//                                                       theme.colorScheme.primary,
//                                                   borderRadius:
//                                                       BorderRadius.circular(8),
//                                                 ),
//                                                 child: Text(
//                                                   task.title,
//                                                   style: TextStyle(
//                                                     color: theme
//                                                         .colorScheme
//                                                         .onPrimary,
//                                                     fontWeight: FontWeight.w500,
//                                                   ),
//                                                 ),
//                                               ),
//                                             ),
//                                             childWhenDragging: Opacity(
//                                               opacity: 0.3,
//                                               child: TaskCard(task: task),
//                                             ),
//                                             child: TaskCard(task: task),
//                                           ),
//                                         );
//                                       },
//                                     ),
//                             ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             );
//           }).toList(),
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () => _showAddTaskDialog(context, ref),
//         backgroundColor: theme.colorScheme.primary,
//         foregroundColor: theme.colorScheme.onPrimary,
//         tooltip: 'Add New Task',
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         child: const Icon(Icons.add, size: 28),
//       ),
//     );
//   }

//   int _calculateDropIndex(
//     BuildContext context,
//     Offset localOffset,
//     int taskCount,
//     bool isSameColumn,
//     Task draggedTask,
//     List<Task> tasks,
//   ) {
//     final box = context.findRenderObject() as RenderBox;
//     final itemHeight = box.size.height / (taskCount == 0 ? 1 : taskCount + 1);
//     int dropIndex = (localOffset.dy / itemHeight).floor().clamp(0, taskCount);
//     if (isSameColumn) {
//       final currentIndex = tasks.indexOf(draggedTask);
//       if (currentIndex >= 0) {
//         if (currentIndex < dropIndex) {
//           dropIndex--;
//         } else if (currentIndex == dropIndex) {
//           dropIndex = currentIndex;
//         }
//       }
//     }
//     return dropIndex;
//   }

//   void _showAddTaskDialog(BuildContext context, WidgetRef ref) {
//     final board = ref.watch(boardProvider);
//     final boardNotifier = ref.read(boardProvider.notifier);
//     String selectedColumnId = board.first.id;
//     final titleController = TextEditingController();
//     final theme = Theme.of(context);

//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         backgroundColor: theme.colorScheme.surface,
//         title: Text(
//           'Add New Task',
//           style: TextStyle(
//             fontWeight: FontWeight.bold,
//             color: theme.colorScheme.onSurface,
//           ),
//         ),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             TextField(
//               controller: titleController,
//               decoration: InputDecoration(
//                 labelText: 'Task Title',
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 filled: true,
//                 fillColor: theme.colorScheme.surfaceContainerHighest,
//               ),
//             ),
//             const SizedBox(height: 16),
//             DropdownButtonFormField<String>(
//               value: selectedColumnId,
//               items: board
//                   .map(
//                     (col) =>
//                         DropdownMenuItem(value: col.id, child: Text(col.title)),
//                   )
//                   .toList(),
//               onChanged: (val) {
//                 if (val != null) selectedColumnId = val;
//               },
//               decoration: InputDecoration(
//                 labelText: 'Select Column',
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 filled: true,
//                 fillColor: theme.colorScheme.surfaceContainerHighest,
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text(
//               'Cancel',
//               style: TextStyle(color: theme.colorScheme.secondary),
//             ),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               final title = titleController.text.trim();
//               if (title.isNotEmpty) {
//                 boardNotifier.addTask(selectedColumnId, title);
//                 Navigator.pop(context);
//               }
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: theme.colorScheme.primary,
//               foregroundColor: theme.colorScheme.onPrimary,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(8),
//               ),
//             ),
//             child: const Text('Add Task'),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class TaskCard extends StatelessWidget {
//   final Task task;
//   const TaskCard({super.key, required this.task});

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     return Card(
//       elevation: 3,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       color: theme.colorScheme.surface,
//       child: Padding(
//         padding: const EdgeInsets.all(12),
//         child: Row(
//           children: [
//             Icon(Icons.task_alt, color: theme.colorScheme.primary, size: 20),
//             const SizedBox(width: 8),
//             Expanded(
//               child: Text(
//                 task.title,
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.w500,
//                   color: theme.colorScheme.onSurface,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../providers/kanban_provider.dart';
// import '../models/task.dart';
// // import '../models/kanban_column.dart';

// class KanbanBoard extends ConsumerWidget {
//   const KanbanBoard({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final board = ref.watch(boardProvider);
//     final boardNotifier = ref.read(boardProvider.notifier);

//     return Scaffold(
//       appBar: AppBar(title: const Text('Kanban Board')),
//       body: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: board.map((column) {
//           return Expanded(
//             child: Padding(
//               padding: const EdgeInsets.all(8),
//               child: Column(
//                 children: [
//                   Text(
//                     column.title,
//                     style: const TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   Expanded(
//                     child: DragTarget<Task>(
//                       // ignore: deprecated_member_use
//                       onAccept: (task) {
//                         boardNotifier.moveTask(
//                           board
//                               .firstWhere((col) => col.tasks.contains(task))
//                               .id,
//                           column.id,
//                           task,
//                           column.tasks.length,
//                           fromColumnId: null,
//                         );
//                       },
//                       builder: (context, _, __) => Container(
//                         padding: const EdgeInsets.all(8),
//                         decoration: BoxDecoration(
//                           color: Colors.grey[200],
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: ListView(
//                           children: column.tasks.map((task) {
//                             return Padding(
//                               padding: const EdgeInsets.symmetric(vertical: 4),
//                               child: Draggable<Task>(
//                                 data: task,
//                                 feedback: Material(
//                                   child: Container(
//                                     width: 200,
//                                     padding: const EdgeInsets.all(8),
//                                     color: Colors.blue,
//                                     child: Text(
//                                       task.title,
//                                       style: const TextStyle(
//                                         color: Colors.white,
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                                 childWhenDragging: Opacity(
//                                   opacity: 0.5,
//                                   child: TaskCard(task: task),
//                                 ),
//                                 child: TaskCard(task: task),
//                               ),
//                             );
//                           }).toList(),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         }).toList(),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () => _showAddTaskDialog(context, ref),
//         child: const Icon(Icons.add),
//       ),
//     );
//   }

//   void _showAddTaskDialog(BuildContext context, WidgetRef ref) {
//     final board = ref.watch(boardProvider);
//     final boardNotifier = ref.read(boardProvider.notifier);
//     String selectedColumnId = board.first.id;
//     final titleController = TextEditingController();

//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: const Text('Add New Task'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             TextField(
//               controller: titleController,
//               decoration: const InputDecoration(labelText: 'Task title'),
//             ),
//             const SizedBox(height: 16),
//             DropdownButtonFormField<String>(
//               value: selectedColumnId,
//               items: board
//                   .map(
//                     (col) =>
//                         DropdownMenuItem(value: col.id, child: Text(col.title)),
//                   )
//                   .toList(),
//               onChanged: (val) {
//                 if (val != null) selectedColumnId = val;
//               },
//               decoration: const InputDecoration(labelText: 'Select Column'),
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               final title = titleController.text.trim();
//               if (title.isNotEmpty) {
//                 boardNotifier.addTask(selectedColumnId, title);
//                 Navigator.pop(context);
//               }
//             },
//             child: const Text('Add'),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class TaskCard extends StatelessWidget {
//   final Task task;
//   const TaskCard({super.key, required this.task});

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       color: Colors.white,
//       child: Padding(padding: const EdgeInsets.all(8), child: Text(task.title)),
//     );
//   }
// }

// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../providers/kanban_provider.dart';
// import '../models/task.dart';

// class KanbanBoard extends ConsumerWidget {
//   const KanbanBoard({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final board = ref.watch(boardProvider);
//     final boardNotifier = ref.read(boardProvider.notifier);
//     final theme = Theme.of(context);

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           'Kanban Board',
//           style: TextStyle(fontWeight: FontWeight.w600, fontSize: 24),
//         ),
//         elevation: 2,
//         backgroundColor: theme.colorScheme.primary,
//         foregroundColor: theme.colorScheme.onPrimary,
//       ),
//       body: Container(
//         color: theme.colorScheme.surface,
//         child: Row(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: board.map((column) {
//             return Expanded(
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 12,
//                   vertical: 16,
//                 ),
//                 child: Column(
//                   children: [
//                     Container(
//                       padding: const EdgeInsets.all(12),
//                       decoration: BoxDecoration(
//                         gradient: LinearGradient(
//                           colors: [
//                             theme.colorScheme.primary.withValues(alpha: 0.8),
//                             theme.colorScheme.primary,
//                           ],
//                           begin: Alignment.topLeft,
//                           end: Alignment.bottomRight,
//                         ),
//                         borderRadius: BorderRadius.circular(12),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.black.withValues(alpha: 0.1),
//                             blurRadius: 8,
//                             offset: const Offset(0, 4),
//                           ),
//                         ],
//                       ),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Text(
//                             column.title,
//                             style: TextStyle(
//                               fontSize: 20,
//                               fontWeight: FontWeight.bold,
//                               color: theme.colorScheme.onPrimary,
//                             ),
//                           ),
//                           Chip(
//                             label: Text(
//                               '${column.tasks.length}',
//                               style: TextStyle(
//                                 color: theme.colorScheme.onPrimary,
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                             backgroundColor: theme.colorScheme.primaryContainer,
//                             padding: const EdgeInsets.symmetric(horizontal: 8),
//                           ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     Expanded(
//                       child: DragTarget<Task>(
//                         onAcceptWithDetails: (details) {
//                           final task = details.data;
//                           final sourceColumn = board.firstWhere(
//                             (col) => col.tasks.contains(task),
//                             orElse: () => column,
//                           );
//                           final renderBox =
//                               context.findRenderObject() as RenderBox;
//                           final localOffset = renderBox.globalToLocal(
//                             details.offset,
//                           );
//                           final dropIndex = _calculateDropIndex(
//                             context,
//                             localOffset,
//                             column.tasks.length,
//                             sourceColumn.id == column.id,
//                             task,
//                             column.tasks,
//                           );
//                           boardNotifier.moveTask(
//                             sourceColumn.id,
//                             column.id,
//                             task,
//                             dropIndex,
//                             fromColumnId: sourceColumn.id,
//                           );
//                           debugPrint(
//                             'Moved task "${task.title}" from ${sourceColumn.id} to ${column.id} at index $dropIndex',
//                           );
//                         },
//                         builder: (context, candidateData, rejectedData) =>
//                             AnimatedContainer(
//                               duration: const Duration(milliseconds: 200),
//                               padding: const EdgeInsets.all(12),
//                               decoration: BoxDecoration(
//                                 color: candidateData.isNotEmpty
//                                     ? theme.colorScheme.primary.withValues(
//                                         alpha: 0.1,
//                                       )
//                                     : theme.colorScheme.surface,
//                                 borderRadius: BorderRadius.circular(12),
//                                 border: Border.all(
//                                   color: candidateData.isNotEmpty
//                                       ? theme.colorScheme.primary
//                                       : Colors.grey[300]!,
//                                   width: 2,
//                                 ),
//                               ),
//                               child: column.tasks.isEmpty
//                                   ? Center(
//                                       child: Text(
//                                         'No tasks yet',
//                                         style: TextStyle(
//                                           color: theme.colorScheme.onSurface
//                                               .withValues(alpha: 0.6),
//                                           fontSize: 16,
//                                         ),
//                                       ),
//                                     )
//                                   : ListView.builder(
//                                       itemCount: column.tasks.length,
//                                       itemBuilder: (context, index) {
//                                         final task = column.tasks[index];
//                                         return Padding(
//                                           padding: const EdgeInsets.symmetric(
//                                             vertical: 6,
//                                           ),
//                                           child: Draggable<Task>(
//                                             data: task,
//                                             feedback: Material(
//                                               elevation: 4,
//                                               borderRadius:
//                                                   BorderRadius.circular(8),
//                                               child: Container(
//                                                 width: 250,
//                                                 padding: const EdgeInsets.all(
//                                                   12,
//                                                 ),
//                                                 decoration: BoxDecoration(
//                                                   color:
//                                                       theme.colorScheme.primary,
//                                                   borderRadius:
//                                                       BorderRadius.circular(8),
//                                                 ),
//                                                 child: Text(
//                                                   task.title,
//                                                   style: TextStyle(
//                                                     color: theme
//                                                         .colorScheme
//                                                         .onPrimary,
//                                                     fontWeight: FontWeight.w500,
//                                                   ),
//                                                 ),
//                                               ),
//                                             ),
//                                             childWhenDragging: Opacity(
//                                               opacity: 0.3,
//                                               child: TaskCard(task: task),
//                                             ),
//                                             child: TaskCard(task: task),
//                                           ),
//                                         );
//                                       },
//                                     ),
//                             ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             );
//           }).toList(),
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () => _showAddTaskDialog(context, ref),
//         backgroundColor: theme.colorScheme.primary,
//         foregroundColor: theme.colorScheme.onPrimary,
//         tooltip: 'Add New Task',
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         child: const Icon(Icons.add, size: 28),
//       ),
//     );
//   }

//   int _calculateDropIndex(
//     BuildContext context,
//     Offset localOffset,
//     int taskCount,
//     bool isSameColumn,
//     Task draggedTask,
//     List<Task> tasks,
//   ) {
//     final box = context.findRenderObject() as RenderBox;
//     final itemHeight = box.size.height / (taskCount == 0 ? 1 : taskCount + 1);
//     int dropIndex = (localOffset.dy / itemHeight).floor().clamp(0, taskCount);
//     if (isSameColumn) {
//       final currentIndex = tasks.indexOf(draggedTask);
//       if (currentIndex >= 0) {
//         if (currentIndex < dropIndex) {
//           dropIndex--;
//         } else if (currentIndex == dropIndex) {
//           dropIndex = currentIndex;
//         }
//       }
//     }
//     return dropIndex;
//   }

//   void _showAddTaskDialog(BuildContext context, WidgetRef ref) {
//     final board = ref.watch(boardProvider);
//     final boardNotifier = ref.read(boardProvider.notifier);
//     String selectedColumnId = board.first.id;
//     final titleController = TextEditingController();
//     final theme = Theme.of(context);

//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         backgroundColor: theme.colorScheme.surface,
//         title: Text(
//           'Add New Task',
//           style: TextStyle(
//             fontWeight: FontWeight.bold,
//             color: theme.colorScheme.onSurface,
//           ),
//         ),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             TextField(
//               controller: titleController,
//               decoration: InputDecoration(
//                 labelText: 'Task Title',
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 filled: true,
//                 fillColor: theme.colorScheme.surfaceContainerHighest,
//               ),
//             ),
//             const SizedBox(height: 16),
//             DropdownButtonFormField<String>(
//               value: selectedColumnId,
//               items: board
//                   .map(
//                     (col) =>
//                         DropdownMenuItem(value: col.id, child: Text(col.title)),
//                   )
//                   .toList(),
//               onChanged: (val) {
//                 if (val != null) selectedColumnId = val;
//               },
//               decoration: InputDecoration(
//                 labelText: 'Select Column',
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 filled: true,
//                 fillColor: theme.colorScheme.surfaceContainerHighest,
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text(
//               'Cancel',
//               style: TextStyle(color: theme.colorScheme.secondary),
//             ),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               final title = titleController.text.trim();
//               if (title.isNotEmpty) {
//                 boardNotifier.addTask(selectedColumnId, title);
//                 Navigator.pop(context);
//               }
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: theme.colorScheme.primary,
//               foregroundColor: theme.colorScheme.onPrimary,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(8),
//               ),
//             ),
//             child: const Text('Add Task'),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class TaskCard extends StatelessWidget {
//   final Task task;
//   const TaskCard({super.key, required this.task});

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     return Card(
//       elevation: 3,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       color: theme.colorScheme.surface,
//       child: Padding(
//         padding: const EdgeInsets.all(12),
//         child: Row(
//           children: [
//             Icon(Icons.task_alt, color: theme.colorScheme.primary, size: 20),
//             const SizedBox(width: 8),
//             Expanded(
//               child: Text(
//                 task.title,
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.w500,
//                   color: theme.colorScheme.onSurface,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
