import 'package:nexus/features/programs/domain/entities/program.dart';

class ProgramModel extends Program {
  const ProgramModel({
    required super.id,
    required super.title,
    required super.description,
    required super.imageUrl,
    required super.duration,
    required super.level,
  });

  factory ProgramModel.fromJson(Map<String, dynamic> json) {
    return ProgramModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String,
      duration: json['duration'] as String,
      level: json['level'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'duration': duration,
      'level': level,
    };
  }
}
