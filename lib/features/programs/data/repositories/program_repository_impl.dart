import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:nexus/features/programs/data/models/program_model.dart';
import 'package:nexus/features/programs/domain/entities/program.dart';

class ProgramRepositoryImpl {
  Future<List<Program>> getPrograms() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 1200));
    
    try {
      final String response = await rootBundle.loadString('assets/data/programs.json');
      final List<dynamic> data = json.decode(response);
      return data.map((json) => ProgramModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load programs: $e');
    }
  }

  Future<Program> getProgramById(String id) async {
    final programs = await getPrograms();
    return programs.firstWhere((p) => p.id == id);
  }
}
