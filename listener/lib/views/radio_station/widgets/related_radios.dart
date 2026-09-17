import '../radio_station_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../../../view_models/radio_station_view_model.dart';
import '../../../core/models/radio_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../main_layout/tabs/channels/radio_card.dart';

class RelatedRadios extends StatelessWidget {
  const RelatedRadios({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RadioStationViewModel>();
    final current = vm.radio;
    if (current == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.explore_outlined,
                    size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text('Other radios',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('radios')
                  .where('isActive', isEqualTo: true)
                  .limit(20)
                  .snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final radios = snap.data!.docs
                    .where((d) => d.id != current.id)
                    .map((d) => RadioModel.fromFirestore(
                        d.data() as Map<String, dynamic>, d.id))
                    .toList();

                if (radios.isEmpty) return const SizedBox.shrink();

                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: radios.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => SizedBox(
                    width: 300,
                    child: RadioCard(
                      radio: radios[i],
                      compact: true,
                      onTap: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              // ignore: use_build_context_synchronously
                              _routeToRadio(radios[i].id),
                        ),
                      ),
                      onToggleFollow: () {},
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _routeToRadio(String radioId) {
    // Return the RadioStationPage for the tapped radio
    return RadioStationPage(radioId: radioId);
  }
}
