import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RatingsNoticeProvider extends ChangeNotifier {
  static const _prefUserLastSeenReplyAtMs = 'user_last_seen_reply_at_ms';
  static const _prefAdminLastSeenRatingAtMs = 'admin_last_seen_rating_at_ms';

  StreamSubscription<QuerySnapshot>? _sub;

  int _unreadUserReplies = 0;
  int _unreadAdminRatings = 0;

  int get unreadUserReplies => _unreadUserReplies;
  int get unreadAdminRatings => _unreadAdminRatings;

  void stop() {
    _sub?.cancel();
    _sub = null;
  }

  /// USER MODE: watches replies on user's own ratings
  Future<void> startForUser(String uid) async {
    stop();
    final prefs = await SharedPreferences.getInstance();
    final lastSeenMs = prefs.getInt(_prefUserLastSeenReplyAtMs) ?? 0;
    final lastSeen = DateTime.fromMillisecondsSinceEpoch(lastSeenMs);

    _sub = FirebaseFirestore.instance
        .collection('app_ratings')
        .where('uid', isEqualTo: uid)
        .where('adminReplyAt', isGreaterThan: Timestamp.fromDate(lastSeen))
        .snapshots()
        .listen((snap) {
      _unreadUserReplies = snap.docs.length;
      notifyListeners();
    });
  }

  /// ADMIN MODE: watches newly created ratings
  Future<void> startForAdmin() async {
    stop();
    final prefs = await SharedPreferences.getInstance();
    final lastSeenMs = prefs.getInt(_prefAdminLastSeenRatingAtMs) ?? 0;
    final lastSeen = DateTime.fromMillisecondsSinceEpoch(lastSeenMs);

    _sub = FirebaseFirestore.instance
        .collection('app_ratings')
        .where('createdAt', isGreaterThan: Timestamp.fromDate(lastSeen))
        .snapshots()
        .listen((snap) {
      _unreadAdminRatings = snap.docs.length;
      notifyListeners();
    });
  }

  /// USER: call when user opens RateAppScreen (so badge clears)
  Future<void> markUserRepliesSeenNow() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _prefUserLastSeenReplyAtMs,
      DateTime.now().millisecondsSinceEpoch,
    );
    _unreadUserReplies = 0;
    notifyListeners();
  }

  /// ADMIN: call when admin opens Ratings Inbox (so badge clears)
  Future<void> markAdminRatingsSeenNow() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _prefAdminLastSeenRatingAtMs,
      DateTime.now().millisecondsSinceEpoch,
    );
    _unreadAdminRatings = 0;
    notifyListeners();
  }
}
