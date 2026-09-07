import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/radio_station_view_model.dart';
import '../../core/models/schedule_model.dart';
import 'widgets/program_poster.dart';
import 'widgets/player_controls.dart';
import 'widgets/comments_section.dart';
import 'widgets/radio_info_section.dart';
import 'widgets/announcement_modal.dart';

class RadioStationPage extends StatefulWidget {
  final String radioId;

  const RadioStationPage({Key? key, required this.radioId}) : super(key: key);

  @override
  State<RadioStationPage> createState() => _RadioStationPageState();
}

class _RadioStationPageState extends State<RadioStationPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RadioStationViewModel>().loadRadioData(widget.radioId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<RadioStationViewModel>();

    if (viewModel.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (viewModel.radio == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Radio Not Found')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.radio, size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              const Text('Radio station not found'),
              const SizedBox(height: 8),
              Text(
                'It may have been removed',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(context, viewModel),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: ProgramPoster(
              radio: viewModel.radio!,
              currentProgram: viewModel.currentProgram,
              onKnowMore: () => _showKnowMoreDialog(context, viewModel.currentProgram),
            ),
          ),
          SliverToBoxAdapter(
            child: PlayerControls(
              isPlaying: viewModel.isPlaying,
              onPlayToggle: viewModel.togglePlay,
              onQueueTap: viewModel.toggleUpcomingModal,
              onCommentsTap: viewModel.toggleComments,
              hasComments: true,
            ),
          ),
          if (viewModel.showComments)
            SliverToBoxAdapter(
              child: CommentsSection(
                radioId: viewModel.radio!.id,
                programId: viewModel.currentProgram?.id,
              ),
            ),
          SliverToBoxAdapter(
            child: RadioInfoSection(
              radio: viewModel.radio!,
              onViewSchedule: () {},
              onViewPrograms: () {},
              onRequestAnnouncement: () {
                _showAnnouncementModal(context, viewModel);
              },
            ),
          ),
          SliverToBoxAdapter(
            child: _buildRelatedPrograms(context),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, RadioStationViewModel viewModel) {
    final radio = viewModel.radio!;
    return AppBar(
      title: Row(
        children: [
          if (radio.logoUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(radio.logoUrl!, width: 28, height: 28, fit: BoxFit.cover),
            )
          else
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  radio.name.substring(0, 1).toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                ),
              ),
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              radio.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(
            viewModel.isFollowing ? Icons.favorite : Icons.favorite_border,
            color: viewModel.isFollowing ? Colors.red : null,
          ),
          onPressed: viewModel.toggleFollow,
          tooltip: viewModel.isFollowing ? 'Unfollow' : 'Follow',
        ),
        IconButton(
          icon: Stack(
            children: [
              const Icon(Icons.notifications_outlined),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  child: const Center(
                    child: Text('3', style: TextStyle(color: Colors.white, fontSize: 9)),
                  ),
                ),
              ),
            ],
          ),
          onPressed: () {},
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildRelatedPrograms(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('More from this radio', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              itemBuilder: (context, index) => Container(
                width: 100,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.withOpacity(0.1)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.radio, size: 24, color: Colors.blue.withOpacity(0.4)),
                    const SizedBox(height: 4),
                    Text('Show ${index + 1}', style: const TextStyle(fontSize: 11)),
                    Text('${(index + 1) * 30} min', style: TextStyle(fontSize: 9, color: Colors.grey)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showKnowMoreDialog(BuildContext context, ScheduleItem? program) {
    if (program == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollController) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Text(program.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('🎙️ Host', program.host),
                      if (program.guest != null) _buildInfoRow('👤 Guest', program.guest!),
                      if (program.guestTitle != null) _buildInfoRow('📋 Guest Title', program.guestTitle!),
                      _buildInfoRow('⏰ Time', program.timeRange),
                      _buildInfoRow('📅 Date', _formatDate(program.startTime)),
                      const SizedBox(height: 12),
                      if (program.description != null) ...[
                        const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(program.description!, style: const TextStyle(fontSize: 14)),
                      ],
                      if (program.tags.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Text('Tags', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 4,
                          children: program.tags.map((tag) => Chip(
                            label: Text(tag, style: const TextStyle(fontSize: 11)),
                            backgroundColor: Colors.blue.withOpacity(0.1),
                            padding: EdgeInsets.zero,
                          )).toList(),
                        ),
                      ],
                      const SizedBox(height: 16),
                      if (program.isLive || program.isNow)
                        ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Listen Now'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: Colors.grey)),
      const SizedBox(width: 8),
      Text(value, style: const TextStyle(fontSize: 13)),
    ]),
  );

  String _formatDate(DateTime date) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  void _showAnnouncementModal(BuildContext context, RadioStationViewModel viewModel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => AnnouncementModal(
        viewModel: viewModel,
        onRequestSubmitted: () {
          Navigator.pop(ctx);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Announcement request submitted!'), backgroundColor: Colors.green),
          );
        },
      ),
    );
  }
}
