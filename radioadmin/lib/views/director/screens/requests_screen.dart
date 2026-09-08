import 'package:flutter/material.dart';
import '../../../core/models/director/request_model.dart';

class RequestsScreen extends StatelessWidget {
  final List<Request> requests;
  final Future<void> Function(String, {String? adminResponse}) onApprove;
  final Future<void> Function(String, {required String adminResponse}) onReject;
  final Future<void> Function(String) onInProgress;
  final Future<void> Function(String) onComplete;
  final Function(RequestStatus?) onFilterStatus;
  final Function(RequestType?) onFilterType;

  const RequestsScreen({
    Key? key,
    required this.requests,
    required this.onApprove,
    required this.onReject,
    required this.onInProgress,
    required this.onComplete,
    required this.onFilterStatus,
    required this.onFilterType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📩 Requests', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const Spacer(),
              DropdownButton<RequestStatus>(
                hint: const Text('Status'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('All')),
                  DropdownMenuItem(value: RequestStatus.pending, child: Text('Pending')),
                  DropdownMenuItem(value: RequestStatus.approved, child: Text('Approved')),
                  DropdownMenuItem(value: RequestStatus.rejected, child: Text('Rejected')),
                ],
                onChanged: onFilterStatus,
              ),
              const SizedBox(width: 8),
              DropdownButton<RequestType>(
                hint: const Text('Type'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('All')),
                  DropdownMenuItem(value: RequestType.announcement, child: Text('Announcement')),
                  DropdownMenuItem(value: RequestType.technicalSupport, child: Text('Tech Support')),
                  DropdownMenuItem(value: RequestType.featureRequest, child: Text('Feature')),
                ],
                onChanged: onFilterType,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final req = requests[index];
                return Card(
                  child: ListTile(
                    leading: Icon(Icons.request_page, color: req.statusColor),
                    title: Text(req.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${req.typeLabel} • ${req.statusLabel}'),
                    trailing: req.status == RequestStatus.pending
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(icon: const Icon(Icons.check, color: Colors.green), onPressed: () => onApprove(req.id)),
                              IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () => onReject(req.id, adminResponse: 'Rejected')),
                            ],
                          )
                        : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
