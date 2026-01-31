import 'dart:io';
import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

class LocalTaskStorage {
  final String fileName = 'tasks_local.json';

  Future<File> _localFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$fileName');
  }

  Future<List<Map<String, dynamic>>> readTasks() async {
    try {
      final file = await _localFile();
      if (!await file.exists()) {
        final data = await rootBundle.loadString('assets/sample_tasks_data.json');
        await file.writeAsString(data);
      }
      final content = await file.readAsString();
      final List<dynamic> jsonList = json.decode(content) as List<dynamic>;
      return jsonList.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> writeTasks(List<Map<String, dynamic>> tasks) async {
    final file = await _localFile();
    await file.writeAsString(json.encode(tasks));
  }

  Future<void> appendTask(Map<String, dynamic> task) async {
    final list = await readTasks();
    list.add(task);
    await writeTasks(list);
  }
}
