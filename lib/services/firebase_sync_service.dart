import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_note.dart';
import '../firebase_options.dart';
import 'storage_service.dart';

class FirebaseSyncService with ChangeNotifier {
  static final FirebaseSyncService _instance = FirebaseSyncService._internal();
  factory FirebaseSyncService() => _instance;
  FirebaseSyncService._internal();

  FirebaseAuth? _auth;
  FirebaseFirestore? _firestore;
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  User? get currentUser => _auth?.currentUser;
  bool get isLoggedIn => currentUser != null;

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<QuerySnapshot>? _highlightsSub;
  StreamSubscription<QuerySnapshot>? _notesSub;
  StreamSubscription<DocumentSnapshot>? _bookmarksSub;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      _auth = FirebaseAuth.instance;
      _firestore = FirebaseFirestore.instance;
      _isInitialized = true;

      _authSubscription = _auth!.authStateChanges().listen((user) {
        notifyListeners();
        if (user != null) {
          _onUserLoggedIn(user.uid);
        } else {
          _cancelCloudSubscriptions();
        }
      });
    } catch (e) {
      // ignore: avoid_print
      print('Firebase initialization deferred or not yet configured: $e');
      _isInitialized = false;
    }
  }

  void _cancelCloudSubscriptions() {
    _highlightsSub?.cancel();
    _notesSub?.cancel();
    _bookmarksSub?.cancel();
    _highlightsSub = null;
    _notesSub = null;
    _bookmarksSub = null;
  }

  // --- Auth Methods ---
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    if (!_isInitialized || _auth == null) return null;
    try {
      final cred = await _auth!.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      notifyListeners();
      return cred;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserCredential?> registerWithEmail(String email, String password, {String? displayName}) async {
    if (!_isInitialized || _auth == null) return null;
    try {
      final cred = await _auth!.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (displayName != null && displayName.isNotEmpty) {
        await cred.user?.updateDisplayName(displayName);
      }
      notifyListeners();
      return cred;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserCredential?> signInAnonymously() async {
    if (!_isInitialized || _auth == null) return null;
    try {
      final cred = await _auth!.signInAnonymously();
      notifyListeners();
      return cred;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    _cancelCloudSubscriptions();
    await _auth?.signOut();
    notifyListeners();
  }

  // --- Sync on Login ---
  Future<void> _onUserLoggedIn(String uid) async {
    if (_firestore == null) return;

    // 1. Upload local data to cloud (merge)
    await syncLocalToCloud();

    // 2. Start real-time listeners from Firestore to local
    final userDoc = _firestore!.collection('users').doc(uid);

    // Listen to Highlights
    _highlightsSub = userDoc.collection('highlights').snapshots().listen((snap) {
      final storage = StorageService();
      final localHighlights = storage.getHighlights();
      bool changed = false;

      for (final doc in snap.docs) {
        final data = doc.data();
        try {
          final cloudItem = UserHighlight.fromJson(data);
          final exists = localHighlights.any((h) => h.id == cloudItem.id);
          if (!exists) {
            storage.addHighlight(cloudItem);
            changed = true;
          }
        } catch (_) {}
      }
      if (changed) notifyListeners();
    });

    // Listen to Notes
    _notesSub = userDoc.collection('notes').snapshots().listen((snap) {
      final storage = StorageService();
      final localNotes = storage.getNotes();
      bool changed = false;

      for (final doc in snap.docs) {
        final data = doc.data();
        try {
          final cloudItem = UserNote.fromJson(data);
          final exists = localNotes.any((n) => n.id == cloudItem.id);
          if (!exists) {
            storage.saveNote(cloudItem);
            changed = true;
          }
        } catch (_) {}
      }
      if (changed) notifyListeners();
    });

    // Listen to Bookmarks & Reading Progress
    _bookmarksSub = userDoc.snapshots().listen((snap) {
      if (!snap.exists) return;
      final data = snap.data();
      if (data == null) return;

      final storage = StorageService();
      final cloudBookmarks = List<String>.from(data['bookmarks'] as List? ?? []);
      for (final b in cloudBookmarks) {
        if (!storage.isBookmarked(b)) {
          storage.toggleBookmark(b);
        }
      }

      final lastSec = data['lastReadSectionId'] as String?;
      final lastTitle = data['lastReadSectionTitle'] as String?;
      if (lastSec != null && lastTitle != null) {
        storage.saveLastRead(lastSec, lastTitle);
      }
      notifyListeners();
    });
  }

  // Push all local data into Cloud Firestore
  Future<void> syncLocalToCloud() async {
    final user = currentUser;
    if (user == null || _firestore == null) return;

    final storage = StorageService();
    final userDoc = _firestore!.collection('users').doc(user.uid);

    // Batch update
    final batch = _firestore!.batch();

    // Highlights
    for (final h in storage.getHighlights()) {
      final ref = userDoc.collection('highlights').doc(h.id);
      batch.set(ref, h.toJson(), SetOptions(merge: true));
    }

    // Notes
    for (final n in storage.getNotes()) {
      final ref = userDoc.collection('notes').doc(n.id);
      batch.set(ref, n.toJson(), SetOptions(merge: true));
    }

    // Bookmarks and Progress
    batch.set(
      userDoc,
      {
        'bookmarks': storage.getBookmarks(),
        'lastReadSectionId': storage.lastReadSectionId,
        'lastReadSectionTitle': storage.lastReadSectionTitle,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    try {
      await batch.commit();
    } catch (_) {}
  }

  // --- Realtime Document Updates ---
  Future<void> uploadHighlight(UserHighlight h) async {
    final user = currentUser;
    if (user == null || _firestore == null) return;
    try {
      await _firestore!
          .collection('users')
          .doc(user.uid)
          .collection('highlights')
          .doc(h.id)
          .set(h.toJson(), SetOptions(merge: true));
    } catch (_) {}
  }

  Future<void> deleteHighlight(String id) async {
    final user = currentUser;
    if (user == null || _firestore == null) return;
    try {
      await _firestore!
          .collection('users')
          .doc(user.uid)
          .collection('highlights')
          .doc(id)
          .delete();
    } catch (_) {}
  }

  Future<void> uploadNote(UserNote n) async {
    final user = currentUser;
    if (user == null || _firestore == null) return;
    try {
      await _firestore!
          .collection('users')
          .doc(user.uid)
          .collection('notes')
          .doc(n.id)
          .set(n.toJson(), SetOptions(merge: true));
    } catch (_) {}
  }

  Future<void> deleteNote(String id) async {
    final user = currentUser;
    if (user == null || _firestore == null) return;
    try {
      await _firestore!
          .collection('users')
          .doc(user.uid)
          .collection('notes')
          .doc(id)
          .delete();
    } catch (_) {}
  }

  Future<void> uploadBookmarks(List<String> bookmarks) async {
    final user = currentUser;
    if (user == null || _firestore == null) return;
    try {
      await _firestore!.collection('users').doc(user.uid).set(
        {'bookmarks': bookmarks, 'updatedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
    } catch (_) {}
  }

  Future<void> uploadLastRead(String sectionId, String title) async {
    final user = currentUser;
    if (user == null || _firestore == null) return;
    try {
      await _firestore!.collection('users').doc(user.uid).set(
        {
          'lastReadSectionId': sectionId,
          'lastReadSectionTitle': title,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _cancelCloudSubscriptions();
    super.dispose();
  }
}
