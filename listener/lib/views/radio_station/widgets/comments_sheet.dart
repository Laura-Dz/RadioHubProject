import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../../core/services/realtime_database_service.dart';

import '../../../core/models/session_model.dart';
import '../../../core/constants/app_colors.dart';

class CommentsSheet extends StatefulWidget {
  final SessionModel session;
  const CommentsSheet({Key? key, required this.session}) : super(key: key);

  @override
  State<CommentsSheet> createState() => _State();
}

class _State extends State<CommentsSheet> {
  final _ctrl = TextEditingController();
  final _fns = FirebaseFunctions.instanceFor(region: 'europe-west1');
  bool _sending = false;
  StreamSubscription? _rtdbSub;
  final Map<String, Map<String, dynamic>> _rtdbComments = {};

  @override
  void initState() {
    super.initState();
    _listenRtdb();
  }

  void _listenRtdb() {
    try {
      final ref = RealtimeDatabaseService.database.ref('comments/${widget.session.id}');
      _rtdbSub = ref.onValue.listen((event) {
        if (!mounted) return;
        final val = event.snapshot.value;
        if (val is Map) {
          final Map<String, Map<String, dynamic>> loaded = {};
          val.forEach((k, v) {
            if (v is Map) {
              loaded[k.toString()] = Map<String, dynamic>.from(v);
            }
          });
          setState(() {
            _rtdbComments
              ..clear()
              ..addAll(loaded);
          });
        }
      }, onError: (e) {
        debugPrint('RTDB comments listen error: $e');
      });
    } catch (e) {
      debugPrint('RTDB comments init error: $e');
    }
  }

  @override
  void dispose() {
    _rtdbSub?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.75;

    return Container(
      height: height,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 6),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Icon(Icons.forum_outlined,
                    size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Live comments',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                      Text(widget.session.programName,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          // Comment list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('comments')
                  .where('sessionId', isEqualTo: widget.session.id)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.hasError) {
                  debugPrint('Comments stream error: ${snap.error}');
                }

                final all = <Map<String, dynamic>>[];
                if (snap.hasData) {
                  for (final d in snap.data!.docs) {
                    final m = Map<String, dynamic>.from(d.data() as Map<String, dynamic>);
                    m['id'] = d.id;
                    all.add(m);
                  }
                }

                // Merge RTDB comments
                for (final entry in _rtdbComments.entries) {
                  final rItem = entry.value;
                  final rId = entry.key;
                  final rText = (rItem['text'] ?? rItem['message'] ?? '').toString();
                  final rUser = (rItem['userId'] ?? '').toString();

                  final idx = all.indexWhere((c) =>
                      c['id'] == rId ||
                      (c['userId'] == rUser && (c['text'] == rText || c['message'] == rText)));

                  if (idx >= 0) {
                    // Overlay RTDB status/reply if present
                    if (rItem['status'] != null) all[idx]['status'] = rItem['status'];
                    if (rItem['hostReply'] != null) all[idx]['hostReply'] = rItem['hostReply'];
                  } else {
                    all.add({
                      'id': rId,
                      ...rItem,
                    });
                  }
                }

                // Sort newest first
                all.sort((a, b) {
                  int getTs(Map<String, dynamic> m) {
                    final ca = m['createdAt'] ?? m['timestamp'];
                    if (ca is Timestamp) return ca.millisecondsSinceEpoch;
                    if (ca is int) return ca;
                    if (ca is num) return ca.toInt();
                    return 0;
                  }
                  return getTs(b).compareTo(getTs(a));
                });

                if (all.isEmpty && (!snap.hasData && _rtdbComments.isEmpty)) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                if (all.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 56,
                            color: AppColors.textMuted.withOpacity(0.3)),
                        const SizedBox(height: 10),
                        const Text('No comments yet',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        const Text('Be the first to say something live!',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.textMuted)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      vertical: 8, horizontal: 16),
                  itemCount: all.length,
                  itemBuilder: (_, i) => _CommentCard(data: all[i]),
                );
              },
            ),
          ),
          // Reply bar
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 10,
              bottom: MediaQuery.of(context).viewInsets.bottom + 12,
            ),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.divider)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    maxLength: 500,
                    minLines: 1,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Add a comment…',
                      counterText: '',
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 1.4),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _sending ? null : _send,
                  icon: _sending
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send, color: AppColors.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<String> _resolveUserName(User? user) async {
    if (user == null) return 'Listener';
    if (user.displayName != null && user.displayName!.trim().isNotEmpty) {
      return user.displayName!.trim();
    }
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final d = doc.data() ?? {};
        final raw = d['displayName'] ?? d['name'] ?? d['fullName'] ?? d['username'];
        if (raw != null && raw.toString().trim().isNotEmpty) {
          final n = raw.toString().trim();
          try {
            await user.updateDisplayName(n);
          } catch (_) {}
          return n;
        }
      }
    } catch (_) {}
    if (user.email != null && user.email!.isNotEmpty) {
      return user.email!.split('@').first;
    }
    return 'Listener';
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    final user = FirebaseAuth.instance.currentUser;
    final userName = await _resolveUserName(user);
    final userId = user?.uid ?? 'anonymous';

    // 1. Send via WebSocket (Firebase Realtime Database)
    try {
      final rtdb = RealtimeDatabaseService.database.ref('comments/${widget.session.id}').push();
      await rtdb.set({
        'id': rtdb.key,
        'sessionId': widget.session.id,
        'userId': userId,
        'userName': userName,
        'text': text,
        'message': text,
        'status': 'visible',
        'timestamp': ServerValue.timestamp,
      });
    } catch (e) {
      debugPrint('RTDB send comment: $e');
    }

    // 2. Direct Firestore fallback & Cloud Function moderation
    try {
      final callable = _fns.httpsCallable('submitComment');
      final res = await callable.call({
        'sessionId': widget.session.id,
        'text': text,
        'userName': userName,
      });
      final data = Map<String, dynamic>.from(res.data);

      if (data['success'] != true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Your comment was flagged (${(data['categories'] as List?)?.join(", ") ?? "policy"})'),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 5),
            ),
          );
        }
        return;
      }
      _ctrl.clear();
    } catch (e) {
      try {
        await FirebaseFirestore.instance.collection('comments').add({
          'sessionId': widget.session.id,
          'text': text,
          'userId': userId,
          'userName': userName,
          'userPhoto': user?.photoURL,
          'status': 'visible',
          'createdAt': FieldValue.serverTimestamp(),
        });
        _ctrl.clear();
        return;
      } catch (_) {}
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
}

class _CommentCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _CommentCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final rawName = data['userName'] ?? data['name'] ?? data['displayName'];
    final name = (rawName != null && rawName.toString().trim().isNotEmpty)
        ? rawName.toString().trim()
        : 'Listener';
    final text = (data['text'] ?? data['message'] ?? '').toString();
    final status = (data['status'] ?? 'pending').toString();
    final reply = data['hostReply']?.toString();
    DateTime? createdAt;
    final ca = data['createdAt'] ?? data['timestamp'];
    if (ca is Timestamp) {
      createdAt = ca.toDate().toLocal();
    } else if (ca is int) {
      createdAt = DateTime.fromMillisecondsSinceEpoch(ca).toLocal();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: status == 'replying'
            ? AppColors.primary.withOpacity(0.05)
            : AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: status == 'replying'
              ? AppColors.primary.withOpacity(0.4)
              : AppColors.border,
          width: status == 'replying' ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700)),
                    if (createdAt != null)
                      Text(_timeAgo(createdAt),
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
              ),
              if (status == 'replying')
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_note, size: 11, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text('Host is replying…',
                          style: TextStyle(
                              fontSize: 10,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(text, style: const TextStyle(fontSize: 13.5, height: 1.35)),
          if (reply != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppColors.success.withOpacity(0.25)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.reply,
                      size: 13, color: AppColors.success),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Host replied',
                            style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.success,
                                letterSpacing: 0.3)),
                        const SizedBox(height: 2),
                        Text(reply,
                            style: const TextStyle(
                                fontSize: 13, height: 1.35)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _timeAgo(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inSeconds < 60) return 'Just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    return '${d.inHours}h ago';
  }
}
