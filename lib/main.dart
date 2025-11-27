import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'やることリスト',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const TodoListScreen(),
    );
  }
}

// Todo 資料模型
class Todo {
  final String id;
  String title;
  bool isDone;

  Todo({
    required this.id,
    required this.title,
    this.isDone = false,
  });

  // JSON 轉換
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'isDone': isDone,
      };

  factory Todo.fromJson(Map<String, dynamic> json) => Todo(
        id: json['id'],
        title: json['title'],
        isDone: json['isDone'],
      );
}

// 主畫面
class TodoListScreen extends StatefulWidget {
  const TodoListScreen({super.key});

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  List<Todo> _todos = [];
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTodos();
  }

  // 讀取資料
  Future<void> _loadTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('todos');
    if (data != null) {
      final List<dynamic> jsonList = jsonDecode(data);
      setState(() {
        _todos = jsonList.map((json) => Todo.fromJson(json)).toList();
      });
    }
  }

  // 儲存資料
  Future<void> _saveTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final String data = jsonEncode(_todos.map((t) => t.toJson()).toList());
    await prefs.setString('todos', data);
  }

  // 新增 Todo
  void _addTodo() {
    if (_textController.text.isEmpty) return;

    setState(() {
      _todos.add(Todo(
        id: DateTime.now().toString(),
        title: _textController.text,
      ));
    });
    _textController.clear();
    _saveTodos();
  }

  // 切換完成狀態
  void _toggleTodo(int index) {
    setState(() {
      _todos[index].isDone = !_todos[index].isDone;
    });
    _saveTodos();
  }

  // 刪除 Todo
  void _deleteTodo(int index) {
    setState(() {
      _todos.removeAt(index);
    });
    _saveTodos();
  }

  @override
  Widget build(BuildContext context) {
    // 統計
    final totalTodos = _todos.length;
    final completedTodos = _todos.where((t) => t.isDone).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('やることリスト'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 統計區域
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('全部', totalTodos, Colors.blue),
                _buildStatItem('完了', completedTodos, Colors.green),
                _buildStatItem(
                    '未完了', totalTodos - completedTodos, Colors.orange),
              ],
            ),
          ),

          // 新增區域
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: '新しいタスクを入力',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addTodo(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addTodo,
                  child: const Text('追加'),
                ),
              ],
            ),
          ),

          const Divider(),

          // Todo 列表
          Expanded(
            child: _todos.isEmpty
                ? const Center(
                    child: Text(
                      'タスクがありません\n上のフォームから追加してください',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _todos.length,
                    itemBuilder: (context, index) {
                      final todo = _todos[index];
                      return Dismissible(
                        key: Key(todo.id),
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) => _deleteTodo(index),
                        child: ListTile(
                          leading: Checkbox(
                            value: todo.isDone,
                            onChanged: (_) => _toggleTodo(index),
                          ),
                          title: Text(
                            todo.title,
                            style: TextStyle(
                              decoration: todo.isDone
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: todo.isDone ? Colors.grey : Colors.black,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteTodo(index),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}