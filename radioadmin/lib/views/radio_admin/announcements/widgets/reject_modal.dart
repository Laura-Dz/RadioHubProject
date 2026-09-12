import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../view_models/radio_admin_view_model.dart';
import '../../../../core/models/radio_admin/announcement_request_model.dart';
import '../../../../core/constants/app_colors.dart';

class RejectAnnouncementModal extends StatefulWidget {
  final AnnouncementRequest announcement;
  const RejectAnnouncementModal({Key? key, required this.announcement}) : super(key: key);

  @override
  State<RejectAnnouncementModal> createState() => _RejectAnnouncementModalState();
}

class _RejectAnnouncementModalState extends State<RejectAnnouncementModal> {
  String _selectedReason = 'Inappropriate content';
  final _additionalNotes = TextEditingController();
  bool _submitting = false;

  final _reasons = const [
    'Inappropriate content',
    'Incomplete information',
    'Policy violation',
    'Duplicate request',
    'Other',
  ];

  @override
  void dispose() {
    _additionalNotes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.announcement;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.cancel_outlined, color: AppColors.error),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Reject announcement',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text('Select a reason for rejection:',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedReason,
                items: _reasons.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                onChanged: (v) => setState(() => _selectedReason = v ?? _selectedReason),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 14),
              const Text('Additional notes (optional):',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: _additionalNotes,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Provide details for the listener...',
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 16),
              // Escrow refund notice
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, size: 18, color: AppColors.warning),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'On rejection, the base amount of ${a.baseAmount.toStringAsFixed(0)} ${a.currency} will be refunded to the listener\'s wallet.',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
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
                        ? const SizedBox(width: 14, height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.close, size: 16),
                    label: const Text('Confirm Rejection'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
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

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final reasonText = _additionalNotes.text.trim().isNotEmpty
        ? '$_selectedReason: ${_additionalNotes.text.trim()}'
        : _selectedReason;
    try {
      await context.read<RadioAdminViewModel>().rejectAnnouncement(
            widget.announcement.id,
            reasonText,
          );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Announcement rejected and base amount refunded'), backgroundColor: AppColors.warning),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
