import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FirestoreStreamService {
  static final FirestoreStreamService _instance = FirestoreStreamService._internal();
  factory FirestoreStreamService() => _instance;
  FirestoreStreamService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final Map<String, StreamController<QuerySnapshot<Map<String, dynamic>>>> _streamControllers = {};
  final Map<String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>> _subscriptions = {};

  // ------------------- Skills Stream -------------------
  Stream<QuerySnapshot<Map<String, dynamic>>> getSkillsStream(
    String streamId, {
    String? type,
    String? userId,
    bool excludeCurrentUser = false,
  }) {
    // Create stable key without timestamp to maintain stream consistency
    final keyParts = [
      'skills',
      streamId,
      if (type != null) 'type_$type',
      if (userId != null) 'user_$userId',
      if (excludeCurrentUser) 'exclude_current',
    ];
    final key = keyParts.join('_');

    // Always create a fresh stream to ensure real-time updates after posting
    if (_streamControllers.containsKey(key) && !_streamControllers[key]!.isClosed) {
      _streamControllers[key]!.close();
      _subscriptions[key]?.cancel();
    }

    final controller = StreamController<QuerySnapshot<Map<String, dynamic>>>.broadcast();
    _streamControllers[key] = controller;

    Query<Map<String, dynamic>> query = _firestore.collection('skills');

    if (type != null) {
      query = query.where('type', isEqualTo: type);
    }
    if (userId != null) {
      query = query.where('userId', isEqualTo: userId);
    }

    query = query.orderBy('timestamp', descending: true);

    final subscription = query.snapshots().listen(
      (snapshot) {
        if (!controller.isClosed) {
          if (excludeCurrentUser) {
            final currentUserId = _auth.currentUser?.uid;
            final filteredDocs = snapshot.docs.where((doc) => doc.data()['userId'] != currentUserId).toList();
            controller.add(_FilteredQuerySnapshot(snapshot, filteredDocs));
          } else {
            controller.add(snapshot);
          }
        }
      },
      onError: (error) {
        if (!controller.isClosed) {
          controller.addError(error);
        }
      },
    );

    _subscriptions[key] = subscription;
    return _streamControllers[key]!.stream;
  }

  // ------------------- Sessions Stream -------------------
  Stream<QuerySnapshot<Map<String, dynamic>>> getSessionsStream(String streamId) {
    final key = 'sessions_$streamId';

    if (!_streamControllers.containsKey(key) || _streamControllers[key]!.isClosed) {
      final controller = StreamController<QuerySnapshot<Map<String, dynamic>>>.broadcast();
      _streamControllers[key] = controller;
    } else {
      return _streamControllers[key]!.stream;
    }

    final controller = _streamControllers[key]!;

    final subscription = _firestore
        .collection('sessions')
        .orderBy('dateTime')
        .snapshots()
        .listen((snapshot) => controller.add(snapshot), onError: (error) => controller.addError(error));

    _subscriptions[key] = subscription;
    return controller.stream;
  }

  // ------------------- Chats Stream -------------------
  Stream<QuerySnapshot<Map<String, dynamic>>> getChatsStream(String streamId, String userId) {
    final key = 'chats_${streamId}_$userId';

    if (!_streamControllers.containsKey(key) || _streamControllers[key]!.isClosed) {
      final controller = StreamController<QuerySnapshot<Map<String, dynamic>>>.broadcast();
      _streamControllers[key] = controller;
    } else {
      return _streamControllers[key]!.stream;
    }

    final controller = _streamControllers[key]!;

    final subscription = _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .listen((snapshot) => controller.add(snapshot), onError: (error) => controller.addError(error));

    _subscriptions[key] = subscription;
    return controller.stream;
  }

  // ------------------- Messages Stream -------------------
  Stream<QuerySnapshot<Map<String, dynamic>>> getMessagesStream(String streamId, String chatId) {
    final key = 'messages_${streamId}_$chatId';

    if (!_streamControllers.containsKey(key) || _streamControllers[key]!.isClosed) {
      final controller = StreamController<QuerySnapshot<Map<String, dynamic>>>.broadcast();
      _streamControllers[key] = controller;
    } else {
      return _streamControllers[key]!.stream;
    }

    final controller = _streamControllers[key]!;

    final subscription = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .listen((snapshot) => controller.add(snapshot), onError: (error) => controller.addError(error));

    _subscriptions[key] = subscription;
    return controller.stream;
  }

  // ------------------- Notifications Stream -------------------
  Stream<QuerySnapshot<Map<String, dynamic>>> getNotificationsStream(String streamId, String userId) {
    final key = 'notifications_${streamId}_$userId';

    if (!_streamControllers.containsKey(key) || _streamControllers[key]!.isClosed) {
      final controller = StreamController<QuerySnapshot<Map<String, dynamic>>>.broadcast();
      _streamControllers[key] = controller;
    } else {
      return _streamControllers[key]!.stream;
    }

    final controller = _streamControllers[key]!;

    final subscription = _firestore
        .collection('notifications')
        .doc(userId)
        .collection('items')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) => controller.add(snapshot), onError: (error) => controller.addError(error));

    _subscriptions[key] = subscription;
    return controller.stream;
  }

  // ------------------- Contacts Stream -------------------
  Stream<QuerySnapshot<Map<String, dynamic>>> getContactsStream(String streamId) {
    final key = 'contacts_$streamId';
    final currentUserId = _auth.currentUser?.uid;

    if (currentUserId == null) {
      // Return empty stream if no user is logged in
      final controller = StreamController<QuerySnapshot<Map<String, dynamic>>>.broadcast();
      controller.addError('No authenticated user');
      return controller.stream;
    }

    if (!_streamControllers.containsKey(key) || _streamControllers[key]!.isClosed) {
      final controller = StreamController<QuerySnapshot<Map<String, dynamic>>>.broadcast();
      _streamControllers[key] = controller;
    } else {
      return _streamControllers[key]!.stream;
    }

    final controller = _streamControllers[key]!;

    // Load contacts from chats where current user is a participant
    final subscription = _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .listen((snapshot) => controller.add(snapshot), onError: (error) => controller.addError(error));

    _subscriptions[key] = subscription;
    return controller.stream;
  }

  // ------------------- Dispose Helpers -------------------
  void disposeStream(String streamId) {
    // Find keys that contain the streamId to handle complex key patterns
    final keys =
        _streamControllers.keys
            .where(
              (key) =>
                  key.contains(streamId) ||
                  key.startsWith('skills_$streamId') ||
                  key.startsWith('${streamId}_') ||
                  key == streamId,
            )
            .toList();

    debugPrint('🗑️ Disposing streams for: $streamId');
    debugPrint('🔍 Found keys to dispose: $keys');

    for (final key in keys) {
      try {
        _subscriptions[key]?.cancel();
        if (!(_streamControllers[key]?.isClosed ?? true)) {
          _streamControllers[key]?.close();
        }
        _subscriptions.remove(key);
        _streamControllers.remove(key);
        debugPrint('✅ Disposed stream: $key');
      } catch (e) {
        debugPrint('❌ Error disposing stream $key: $e');
      }
    }
  }

  // Force refresh all skill-related streams after posting
  void refreshSkillStreams() {
    debugPrint('🔄 Refreshing all skill-related streams...');
    final skillKeys =
        _streamControllers.keys.where((key) => key.contains('skills') || key.contains('marketplace')).toList();

    for (final key in skillKeys) {
      try {
        _subscriptions[key]?.cancel();
        if (!(_streamControllers[key]?.isClosed ?? true)) {
          _streamControllers[key]?.close();
        }
        _subscriptions.remove(key);
        _streamControllers.remove(key);
        debugPrint('✅ Refreshed stream: $key');
      } catch (e) {
        debugPrint('❌ Error refreshing stream $key: $e');
      }
    }
  }

  void disposeAll() {
    for (final sub in _subscriptions.values) {
      sub.cancel();
    }
    for (final controller in _streamControllers.values) {
      controller.close();
    }
    _subscriptions.clear();
    _streamControllers.clear();
  }
}

// ------------------- Custom Filtered Snapshot -------------------
class _FilteredQuerySnapshot extends QuerySnapshot<Map<String, dynamic>> {
  final QuerySnapshot<Map<String, dynamic>> _original;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> _filteredDocs;

  _FilteredQuerySnapshot(this._original, this._filteredDocs);

  @override
  List<QueryDocumentSnapshot<Map<String, dynamic>>> get docs => _filteredDocs;

  @override
  List<DocumentChange<Map<String, dynamic>>> get docChanges => _original.docChanges;

  @override
  SnapshotMetadata get metadata => _original.metadata;

  @override
  int get size => _filteredDocs.length;

  bool get isEmpty => _filteredDocs.isEmpty;

  bool get isNotEmpty => _filteredDocs.isNotEmpty;

  Iterator<QueryDocumentSnapshot<Map<String, dynamic>>> get iterator => _filteredDocs.iterator;
}
