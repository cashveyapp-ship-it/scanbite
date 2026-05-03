// admin_ratings_screen.dart (FULL UPDATED)
// ✅ Admin-only screen (you already gate it in Settings)
// ✅ Shows all ratings + allows admin to reply/edit reply
// ✅ Writes: adminReply + adminReplyAt + adminRepliedBy ("Admin") + reply seen flags
// ✅ Fully localized with AppLocalizations

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../gen_l10n/app_localizations.dart';
import '../utils/constants.dart';

class AdminRatingsScreen extends StatelessWidget {
  const AdminRatingsScreen({Key? key}) : super(key: key);

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

  Future<void> _reply(
      BuildContext context,
      String docId,
      Map<String, dynamic> data,
      ) async {
    final l10n = AppLocalizations.of(context)!;
    final ctrl =
    TextEditingController(text: (data['adminReply'] ?? '').toString());

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.adminRatingsReplyTitle),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          maxLength: 500,
          decoration: InputDecoration(
            hintText: l10n.adminRatingsReplyHint,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.adminRatingsCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.adminRatingsSaveReply),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final reply = ctrl.text.trim();
    if (reply.isEmpty) return;

    await FirebaseFirestore.instance
        .collection('app_ratings')
        .doc(docId)
        .update({
      'adminReply': reply,
      'adminReplyAt': FieldValue.serverTimestamp(),
      'adminRepliedBy': 'Admin',
      'adminReplySeen': false,
      'adminReplySeenAt': null,
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.adminRatingsReplyPosted)),
      );
    }
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

    // ✅ PRODUCTION-SAFE ADMIN GATE (minimal, won’t break your logic)
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    const adminEmails = ['an2mouth@yahoo.com', 'alerttmenow@gmail.com'];

    final email = ((authProvider.userProfile?.email ?? authProvider.user?.email) ?? '')
        .trim()
        .toLowerCase();

    if (!adminEmails.contains(email)) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Access Denied'),
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Text(
            l10n.adminRatingsAccessDenied, // ✅ add this string or replace with hard text below
            // If you don't want to add a localization key, replace with:
            // 'You do not have admin access.',
            style: const TextStyle(
              fontSize: 18,
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.adminRatingsTitle),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('app_ratings')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return Center(child: Text(l10n.adminRatingsNoReviews));
          }

          final docs = snap.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final doc = docs[i];
              final d = doc.data() as Map<String, dynamic>;

              final name = (d['name'] ?? 'User').toString();
              final email = (d['email'] ?? '').toString();

              final starsRaw = d['stars'];
              final stars =
              starsRaw is int ? starsRaw : int.tryParse('$starsRaw') ?? 0;

              final comment = (d['comment'] ?? '').toString();
              final createdAt = _fmtTs(d['createdAt']);

              final reply = (d['adminReply'] ?? '').toString().trim();
              final hasReply = reply.isNotEmpty;
              final replyAt = _fmtTs(d['adminReplyAt']);

              final repliedBy = hasReply ? 'Admin' : '';

              return Card(
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                if (email.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    email,
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                                if (createdAt.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    createdAt,
                                    style: const TextStyle(
                                        fontSize: 11, color: Colors.grey),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          _starsRow(stars),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(comment),
                      if (hasReply) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.adminRatingsYourReply,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              if (replyAt.isNotEmpty || repliedBy.isNotEmpty)
                                ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    [
                                      if (replyAt.isNotEmpty) replyAt,
                                      if (repliedBy.isNotEmpty) repliedBy,
                                    ].join(' • '),
                                    style: const TextStyle(
                                        fontSize: 11, color: Colors.grey),
                                  ),
                                ],
                              const SizedBox(height: 6),
                              Text(reply),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _reply(context, doc.id, d),
                          icon: Icon(hasReply ? Icons.edit : Icons.reply),
                          label: Text(
                            hasReply
                                ? l10n.adminRatingsEditReply
                                : l10n.adminRatingsReply,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppConstants.primaryColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}