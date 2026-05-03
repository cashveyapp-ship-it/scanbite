// rate_app_screen.dart (FULL UPDATED - FIXED)
// ✅ Submit no longer “spins forever” (email launch is non-blocking + Firestore timeout)
// ✅ Fixes bottom overflow (uses CustomScrollView instead of Column)
// ✅ Still saves to Firestore + opens mail composer + shows recent reviews + admin replies
// ✅ Fully localized with AppLocalizations

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../gen_l10n/app_localizations.dart';

class RateAppScreen extends StatefulWidget {
  const RateAppScreen({Key? key}) : super(key: key);

  @override
  State<RateAppScreen> createState() => _RateAppScreenState();
}

class _RateAppScreenState extends State<RateAppScreen> {
  int _stars = 5;
  final _commentCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  String _fmtTs(dynamic ts) {
    try {
      if (ts == null) return '';
      final dt = (ts as Timestamp).toDate();
      final mm = dt.minute.toString().padLeft(2, '0');
      final hh = dt.hour.toString().padLeft(2, '0');
      return '${dt.month}/${dt.day}/${dt.year} $hh:$mm';
    } catch (_) {
      return '';
    }
  }

  Future<void> _submitRating() async {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;

    if (user == null) {
      _showSnack(l10n.rateAppSignInFirst);
      return;
    }

    final comment = _commentCtrl.text.trim();
    if (comment.isEmpty) {
      _showSnack(l10n.rateAppWriteComment);
      return;
    }

    if (comment.length > 500) {
      _showSnack(l10n.rateAppCommentTooLong);
      return;
    }

    if (_submitting) return;
    setState(() => _submitting = true);

    bool queuedOrSaved = false;

    try {
      final uid = user.uid;
      final email = (user.email ?? '').trim();
      final name =
          authProvider.userProfile?.displayName ?? user.displayName ?? 'User';

      final now = DateTime.now();

      // ✅ Firestore sometimes hangs when gRPC channel resets.
      // Timeout prevents infinite spinner.
      await FirebaseFirestore.instance
          .collection('app_ratings')
          .add({
        'uid': uid,
        'name': name,
        'email': email,
        'stars': _stars,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
        'createdAtLocal': now,
        'appVersion': AppConstants.appVersion,
        'adminReply': '',
        'adminReplyAt': null,
        'adminRepliedBy': 'Admin',
        'adminReplySeen': true,
        'adminReplySeenAt': null,
      })
          .timeout(const Duration(seconds: 8));

      queuedOrSaved = true;
    } on TimeoutException {
      // ✅ If it timed out, Firestore often still queued it locally.
      // Don’t punish the user with an infinite spinner.
      queuedOrSaved = true;
    } catch (e) {
      queuedOrSaved = false;
    } finally {
      if (!mounted) return;

      // ✅ Always stop spinner
      setState(() => _submitting = false);

      if (queuedOrSaved) {
        // ✅ Clear UI exactly how you want it
        _commentCtrl.clear();
        setState(() => _stars = 5);

        _showSnack(l10n.rateAppThanks);

        // Email is optional — don’t block submit
        _openSupportEmail(
          l10n: l10n,
          name: authProvider.userProfile?.displayName ??
              user.displayName ??
              'User',
          email: (user.email ?? '').trim(),
          stars: _stars,
          comment: comment,
        );
      } else {
        _showSnack(l10n.rateAppFailed);
      }
    }
  }
  Future<void> _openSupportEmail({
    required AppLocalizations l10n,
    required String name,
    required String email,
    required int stars,
    required String comment,
  }) async {
    try {
      final subject =
      Uri.encodeComponent('${l10n.rateAppEmailSubject} ($stars★)');
      final body = Uri.encodeComponent('''
User: $name
Email: $email
Stars: $stars
App Version: ${AppConstants.appVersion}

Comment:
$comment
''');

      final uri =
      Uri.parse('mailto:alerttmenow@gmail.com?subject=$subject&body=$body');

      final ok = await canLaunchUrl(uri);
      if (!ok) return;

      // Don’t let this hang the app; also don’t crash if user cancels
      await launchUrl(uri, mode: LaunchMode.externalApplication)
          .timeout(const Duration(seconds: 3));
    } catch (_) {
      // silently ignore (email is optional)
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppConstants.primaryColor,
      ),
    );
  }

  Widget _starsRow(int stars) {
    return Row(
      children: List.generate(5, (j) {
        final idx = j + 1;
        return Icon(
          idx <= stars ? Icons.star : Icons.star_border,
          size: 16,
          color: idx <= stars ? Colors.amber : Colors.grey,
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.rateAppTitle),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),

      // ✅ Fix overflow: use CustomScrollView instead of Column
      body: SafeArea(
        child: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.rateAppQuestion,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: List.generate(5, (i) {
                            final index = i + 1;
                            final selected = index <= _stars;
                            return IconButton(
                              onPressed: _submitting
                                  ? null
                                  : () => setState(() => _stars = index),
                              icon: Icon(
                                selected ? Icons.star : Icons.star_border,
                                color: selected ? Colors.amber : Colors.grey,
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _commentCtrl,
                          enabled: !_submitting,
                          maxLines: 4,
                          maxLength: 500,
                          decoration: InputDecoration(
                            hintText: l10n.rateAppHint,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _submitting ? null : _submitRating,
                            icon: _submitting
                                ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                                : const Icon(Icons.send),
                            label: Text(_submitting
                                ? l10n.rateAppSubmitting
                                : l10n.rateAppSubmit),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppConstants.primaryColor,
                              foregroundColor: Colors.white,
                              padding:
                              const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.rateAppDisclaimer,
                          style:
                          const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n.rateAppRecentReviews,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),

            SliverFillRemaining(
              hasScrollBody: true,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('app_ratings')
                    .orderBy('createdAt', descending: true)
                    .limit(50)
                    .snapshots(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return Center(child: Text('Error: ${snap.error}'));
                  }
                  if (!snap.hasData || snap.data!.docs.isEmpty) {
                    return Center(child: Text(l10n.rateAppNoReviews));
                  }

                  final docs = snap.data!.docs;

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final doc = docs[i];
                      final d = doc.data() as Map<String, dynamic>;

                      final name = (d['name'] ?? 'User').toString();
                      final starsRaw = d['stars'];
                      final stars = starsRaw is int
                          ? starsRaw
                          : int.tryParse('$starsRaw') ?? 0;

                      final comment = (d['comment'] ?? '').toString();
                      final createdAt = _fmtTs(d['createdAt']);

                      final adminReply =
                      (d['adminReply'] ?? '').toString().trim();
                      final hasReply = adminReply.isNotEmpty;
                      final adminReplyAt = _fmtTs(d['adminReplyAt']);
                      final adminRepliedBy = hasReply ? 'Admin' : '';

                      return Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        if (createdAt.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            createdAt,
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  _starsRow(stars),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(comment),
                              if (hasReply) ...[
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: Colors.green.shade200),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.rateAppDeveloperResponse,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      if (adminReplyAt.isNotEmpty ||
                                          adminRepliedBy.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          [
                                            if (adminReplyAt.isNotEmpty)
                                              adminReplyAt,
                                            if (adminRepliedBy.isNotEmpty)
                                              adminRepliedBy,
                                          ].join(' • '),
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey),
                                        ),
                                      ],
                                      const SizedBox(height: 6),
                                      Text(adminReply),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}