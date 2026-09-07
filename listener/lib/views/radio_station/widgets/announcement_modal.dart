import 'package:flutter/material.dart';
import '../../../core/enums/view_state.dart';
import '../../../view_models/radio_station_view_model.dart';
import '../../../core/models/announcement_request_model.dart';
import '../../../core/theme/app_colors.dart';

class AnnouncementModal extends StatefulWidget {
  final RadioStationViewModel viewModel;
  final VoidCallback onRequestSubmitted;

  const AnnouncementModal({
    Key? key,
    required this.viewModel,
    required this.onRequestSubmitted,
  }) : super(key: key);

  @override
  State<AnnouncementModal> createState() => _AnnouncementModalState();
}

class _AnnouncementModalState extends State<AnnouncementModal> {
  final TextEditingController _messageController = TextEditingController();
  AnnouncementCategory _selectedCategory = AnnouncementCategory.general;
  int _selectedDuration = 30;
  double _calculatedPrice = 0.0;

  final List<int> _durationOptions = [15, 30, 45, 60, 90, 120];

  @override
  void initState() {
    super.initState();
    _updatePrice();
  }

  void _updatePrice() {
    final pricing = widget.viewModel.pricing;
    if (pricing != null) {
      final tier = pricing.getPriceTier(_selectedCategory, _selectedDuration);
      if (tier != null) {
        setState(() => _calculatedPrice = tier.price);
        return;
      }
    }
    setState(() => _calculatedPrice = _selectedDuration * 0.10);
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = widget.viewModel.state == ViewState.loading;

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '📢 Request Announcement',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Pay a small fee to have your announcement aired.',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _messageController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Your Message',
              border: OutlineInputBorder(),
              hintText: 'Type your announcement message...',
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<AnnouncementCategory>(
            value: _selectedCategory,
            items: AnnouncementCategory.values.map((cat) {
              return DropdownMenuItem(
                value: cat,
                child: Text(cat.toString().split('.').last),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedCategory = val;
                  _updatePrice();
                });
              }
            },
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            value: _selectedDuration,
            items: _durationOptions.map((d) {
              return DropdownMenuItem(
                value: d,
                child: Text('${d} seconds'),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedDuration = val;
                  _updatePrice();
                });
              }
            },
            decoration: const InputDecoration(
              labelText: 'Duration',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Estimated Price:', style: TextStyle(fontWeight: FontWeight.w500)),
                Text(
                  '\$${_calculatedPrice.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLoading ? null : () => _submitRequest(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text('Pay \$${_calculatedPrice.toStringAsFixed(2)} & Submit'),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _submitRequest() async {
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your message'), backgroundColor: Colors.red),
      );
      return;
    }

    await widget.viewModel.requestAnnouncement(
      message: _messageController.text.trim(),
      category: _selectedCategory,
      durationSeconds: _selectedDuration,
      price: _calculatedPrice,
    );

    if (widget.viewModel.state == ViewState.error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.viewModel.errorMessage ?? 'Failed to submit'), backgroundColor: Colors.red),
      );
    } else {
      widget.onRequestSubmitted();
    }
  }
}
