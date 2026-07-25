import 'package:nexus/core/services/firestore_service.dart';
import 'package:nexus/features/programs/domain/entities/program.dart';

/// Firestore-backed repository for Programs.
class ProgramFirestoreRepository {
  final FirestoreService _firestore = FirestoreService();
  static const String _collection = 'programs';

  /// Get all programs from Firestore.
  Future<List<Program>> getPrograms() async {
    final docs = await _firestore.getCollection(_collection);
    return docs.map((data) => Program.fromFirestore(data)).toList();
  }

  /// Get a single program by document ID.
  Future<Program?> getProgramById(String id) async {
    final data = await _firestore.getDocument(_collection, id);
    if (data == null) return null;
    return Program.fromFirestore(data);
  }

  /// Add a new program. Returns the document ID.
  Future<String> addProgram(Program program) async {
    return await _firestore.addDocument(_collection, program.toFirestore());
  }

  /// Stream all programs (real-time updates).
  Stream<List<Program>> streamPrograms() {
    return _firestore.streamCollection(_collection).map(
      (docs) => docs.map((data) => Program.fromFirestore(data)).toList(),
    );
  }
}
