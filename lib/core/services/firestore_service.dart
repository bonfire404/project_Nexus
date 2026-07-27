import 'package:cloud_firestore/cloud_firestore.dart';

/// Generic Firestore CRUD helper for all feature modules.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Get all documents from a collection.
  Future<List<Map<String, dynamic>>> getCollection(String collection) async {
    final snapshot = await _db.collection(collection).get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  /// Get all documents from a collection, ordered by a field.
  Future<List<Map<String, dynamic>>> getCollectionOrdered(
    String collection, {
    required String orderBy,
    bool descending = false,
  }) async {
    final snapshot = await _db
        .collection(collection)
        .orderBy(orderBy, descending: descending)
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  /// Get a single document by ID.
  Future<Map<String, dynamic>?> getDocument(
    String collection,
    String docId,
  ) async {
    final doc = await _db.collection(collection).doc(docId).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    data['id'] = doc.id;
    return data;
  }

  /// Add a new document to a collection. Returns the document ID.
  Future<String> addDocument(
    String collection,
    Map<String, dynamic> data,
  ) async {
    final ref = await _db.collection(collection).add(data);
    return ref.id;
  }

  /// Update an existing document.
  Future<void> updateDocument(
    String collection,
    String docId,
    Map<String, dynamic> data,
  ) async {
    await _db.collection(collection).doc(docId).update(data);
  }

  /// Set a document (create or overwrite).
  Future<void> setDocument(
    String collection,
    String docId,
    Map<String, dynamic> data, {
    bool merge = true,
  }) async {
    await _db.collection(collection).doc(docId).set(data, SetOptions(merge: merge));
  }

  /// Delete a document.
  Future<void> deleteDocument(String collection, String docId) async {
    await _db.collection(collection).doc(docId).delete();
  }

  /// Query documents where a field equals a value.
  Future<List<Map<String, dynamic>>> queryWhere(
    String collection, {
    required String field,
    required dynamic isEqualTo,
  }) async {
    final snapshot = await _db
        .collection(collection)
        .where(field, isEqualTo: isEqualTo)
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  /// Stream all documents in a collection (real-time).
  Stream<List<Map<String, dynamic>>> streamCollection(String collection) {
    return _db.collection(collection).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  /// Stream documents where a field equals a value (real-time).
  Stream<List<Map<String, dynamic>>> streamWhere(
    String collection, {
    required String field,
    required dynamic isEqualTo,
  }) {
    return _db
        .collection(collection)
        .where(field, isEqualTo: isEqualTo)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  /// Stream a single document by ID (real-time).
  Stream<Map<String, dynamic>> streamDocument(
    String collection,
    String docId,
  ) {
    return _db.collection(collection).doc(docId).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return {};
      final data = snapshot.data()!;
      data['id'] = snapshot.id;
      return data;
    });
  }
}
