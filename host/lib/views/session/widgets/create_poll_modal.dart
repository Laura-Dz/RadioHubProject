import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/cloud_function_caller.dart';
import '../../../core/services/realtime_database_service.dart';
import '../../../view_models/host_view_model.dart';

class CreatePollModal extends StatefulWidget {
  const CreatePollModal({Key? key}) : super(key: key);

  @override
  State<CreatePollModal> createState() => _State();
}

class _State extends State<CreatePollModal> {
  final _questionCtrl = TextEditingController();
  final List<TextEditingController> _optionCtrls = [
    TextEditingController(),
    TextEditingController(),
  ];
  int _closeAfterSeconds = 0;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _questionCtrl.dispose();
    for (final c in _optionCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 700),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.poll_outlined, color: AppColors.primary),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Create a poll',
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w700)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: _submitting ? null : () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Question'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _questionCtrl,
                        maxLength: 200,
                        decoration: _dec('Ask a question…'),
                      ),
                      const SizedBox(height: 14),
                      _label('Options (2–4)'),
                      const SizedBox(height: 6),
                      ..._optionCtrls.asMap().entries.map(
                            (e) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: e.value,
                                      decoration: _dec('Option ${e.key + 1}'),
                                    ),
                                  ),
                                  if (_optionCtrls.length > 2)
                                    IconButton(
                                      icon: const Icon(Icons.close, size: 18),
                                      onPressed: () => setState(
                                          () => _optionCtrls.removeAt(e.key)),
                                    ),
                                ],
                              ),
                            ),
                          ),
                      if (_optionCtrls.length < 4)
                        TextButton.icon(
                          onPressed: () => setState(
                              () => _optionCtrls.add(TextEditingController())),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add option'),
                        ),
                      const SizedBox(height: 14),
                      _label('Auto-close'),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: [
                          _chip(0, 'Manual'),
                          _chip(60, '1 min'),
                          _chip(300, '5 min'),
                          _chip(600, '10 min'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.error)),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _submitting ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _submitting ? null : _submit,
                    icon: _submitting
                        ? const SizedBox(
                            width: 14, height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check, size: 16),
                    label: const Text('Launch poll'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String t) => Text(t,
      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700));

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.4)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      );

  Widget _chip(int seconds, String label) {
    final sel = _closeAfterSeconds == seconds;
    return ChoiceChip(
      label: Text(label),
      selected: sel,
      onSelected: (_) => setState(() => _closeAfterSeconds = seconds),
      selectedColor: AppColors.primary.withOpacity(0.12),
      backgroundColor: AppColors.surface,
      side: BorderSide(color: sel ? AppColors.primary : AppColors.border),
      labelStyle: TextStyle(
        color: sel ? AppColors.primary : AppColors.textSecondary,
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Future<void> _submit() async {
    final question = _questionCtrl.text.trim();
    final options = _optionCtrls
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    if (question.isEmpty) {
      setState(() => _error = 'Enter a question');
      return;
    }
    if (options.length < 2) {
      setState(() => _error = 'At least 2 options required');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      // 1. Try via CloudFunctionCaller (HTTP callable avoiding dart2js Int64 issue)
      try {
        await CloudFunctionCaller.call('createPoll', {
          'question': question,
          'options': options,
          'closeAfterSeconds': _closeAfterSeconds,
        });
        if (mounted) Navigator.pop(context);
        return;
      } catch (fnErr) {
        debugPrint('createPoll CloudFunctionCaller error ($fnErr), trying direct Firestore creation...');
      }

      // 2. Direct Firestore fallback
      final vm = context.read<HostViewModel>();
      final session = vm.session;
      final sessionId = session?.id;
      final radioId = session?.radioId ?? '';

      if (sessionId == null || sessionId.isEmpty) {
        throw Exception('No active broadcast session found.');
      }

      final db = FirebaseFirestore.instance;

      // Close previous active polls for this session in Firestore & RTDB
      try {
        await RealtimeDatabaseService.database.ref('polls/$sessionId').update({'status': 'closed'});
      } catch (_) {}

      final existing = await db
          .collection('polls')
          .where('sessionId', isEqualTo: sessionId)
          .get();
      final batch = db.batch();
      for (final d in existing.docs) {
        if (d.data()['status'] == 'active') {
          batch.update(d.reference, {'status': 'closed'});
        }
      }

      final pollRef = db.collection('polls').doc();
      final pollId = pollRef.id;
      final closesAt = _closeAfterSeconds > 0
          ? DateTime.now().add(Duration(seconds: _closeAfterSeconds))
          : null;

      final voteCounts = <String, int>{};
      for (int i = 0; i < options.length; i++) {
        voteCounts[i.toString()] = 0;
      }

      final optionsList = options.asMap().entries.map((e) => {
        'index': e.key,
        'text': e.value,
      }).toList();

      // 1. Publish to Realtime Database (WebSocket - instant delivery to listeners)
      try {
        final rtdb = RealtimeDatabaseService.database.ref('polls/$sessionId');
        await rtdb.set({
          'id': pollId,
          'pollId': pollId,
          'radioId': radioId,
          'sessionId': sessionId,
          'question': question,
          'options': optionsList,
          'createdBy': FirebaseAuth.instance.currentUser?.uid ?? 'host',
          'createdAt': ServerValue.timestamp,
          'status': 'active',
          if (closesAt != null) 'closesAt': closesAt.millisecondsSinceEpoch,
          'totalVotes': 0,
          'voteCounts': voteCounts,
        });
      } catch (rtdbErr) {
        debugPrint('Error publishing poll to RTDB: $rtdbErr');
      }

      // 2. Persist to Firestore
      batch.set(pollRef, {
        'radioId': radioId,
        'sessionId': sessionId,
        'question': question,
        'options': optionsList,
        'createdBy': FirebaseAuth.instance.currentUser?.uid ?? 'host',
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'active',
        if (closesAt != null) 'closesAt': Timestamp.fromDate(closesAt),
        'totalVotes': 0,
        'voteCounts': voteCounts,
      });

      await batch.commit();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
