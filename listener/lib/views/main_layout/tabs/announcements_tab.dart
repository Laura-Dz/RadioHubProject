import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../../core/services/announcement_service.dart';
import '../../../core/services/channels_service.dart';
import '../../../core/services/campay_service.dart';
import '../../../core/models/radio_model.dart';
import '../../../core/models/announcement_request.dart';
import '../../../core/theme/app_colors.dart';
import '../../../view_models/announcement_view_model.dart';
import '../../announcements/my_announcements_screen.dart';

class AnnouncementsTab extends StatefulWidget {
  const AnnouncementsTab({Key? key}) : super(key: key);

  @override
  State<AnnouncementsTab> createState() => _AnnouncementsTabState();
}

class _AnnouncementsTabState extends State<AnnouncementsTab> {
  final AnnouncementService _service = AnnouncementService();
  final ChannelsService _channelsService = ChannelsService();
  final CampayService _campayService = CampayService();
  final TextEditingController _draftController = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();

  int _step = 1;
  bool _isCreating = false;
  bool _loading = false;
  bool _loadingTariffs = false;

  // Station Selection
  String _selectedRadioId = 'radio_1';
  String _selectedRadioName = 'Radio Sunshine';
  List<RadioModel> _stations = [];

  // Category & Payment (Strictly configured by Radio Admin)
  List<AnnouncementTariffEntry> _tariffs = [];
  List<String> _categories = [];
  String _category = 'general';
  AnnouncementPriority _priority = AnnouncementPriority.standard;
  String _paymentMethod = 'MoMo';

  // Date and Period
  DateTime _startDate = DateTime.now();
  int _diffusionDays = 7;
  int _diffusionsPerDay = 1;

  DateTime get _endDate => _startDate.add(Duration(days: _diffusionDays));

  // AI Notor 1
  String _finalText = '';
  int _wordCount = 0;
  int _durationSeconds = 30;

  // AI Notor 2
  double _baseTariff = 0.0;
  double _transferFee = 0.0;
  double _finalPrice = 0.0;

  String? _submittedRefId;

  final List<int> _periodOptions = [1, 3, 7, 14, 30];
  final List<int> _diffusionsPerDayOptions = [1, 2, 3];

  final List<Map<String, String>> _fallbackRadios = [
    {'id': 'radio_1', 'name': 'Radio Sunshine'},
    {'id': 'radio_2', 'name': 'City Beat FM'},
    {'id': 'radio_3', 'name': 'Capital Sound'},
  ];

  String _formatDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}';
  }

  @override
  void initState() {
    super.initState();
    _loadStations();
    _loadTariffsForRadio(_selectedRadioId);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      context.read<AnnouncementViewModel>().watchMyAnnouncements(uid);
    });
  }

  Future<void> _loadTariffsForRadio(String radioId) async {
    setState(() => _loadingTariffs = true);
    final list = await _service.getTariffs(radioId);
    if (mounted) {
      setState(() {
        _tariffs = list;
        _categories = list.map((t) => t.category).toList();
        if (_categories.isNotEmpty) {
          if (!_categories.contains(_category)) {
            _category = _categories.first;
          }
        }
        _loadingTariffs = false;
      });
    }
  }

  void _loadStations() {
    _channelsService.streamAllRadios().listen((radios) {
      if (radios.isNotEmpty && mounted) {
        final prevId = _selectedRadioId;
        setState(() {
          _stations = radios;
          if (!_stations.any((r) => r.id == _selectedRadioId)) {
            _selectedRadioId = _stations.first.id;
            _selectedRadioName = _stations.first.name;
          }
        });
        if (prevId != _selectedRadioId) {
          _loadTariffsForRadio(_selectedRadioId);
        }
      }
    });
  }

  @override
  void dispose() {
    _draftController.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _resetForm() {
    setState(() {
      _step = 1;
      _submittedRefId = null;
      _draftController.clear();
      _phoneCtrl.clear();
      _finalText = '';
      _baseTariff = 0.0;
      _transferFee = 0.0;
      _finalPrice = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCreating) {
      return MyAnnouncementsScreen(
        onRequestNew: () {
          setState(() {
            _isCreating = true;
            _resetForm();
          });
        },
        showAppBar: false,
      );
    }

    final myAnnouncements = context.watch<AnnouncementViewModel>().mine;
    final activeRequests = myAnnouncements.where((a) => a.isValidated || a.isPendingValidation).toList();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Return / Back Bar
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: () => setState(() => _isCreating = false),
                    icon: const Icon(Icons.arrow_back, color: AppColors.primary),
                    label: const Text(
                      'Back to My Announcements',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    tooltip: 'Cancel & Return',
                    onPressed: () => setState(() => _isCreating = false),
                  ),
                ],
              ),
            ),
            // Top Header Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.campaign, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Radio Announcements',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Draft, enhance with AI, select schedule, & hold payment in escrow.',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.history, color: Colors.white),
                        tooltip: 'My Announcements',
                        onPressed: () => setState(() => _isCreating = false),
                      ),
                      if (myAnnouncements.isNotEmpty)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: activeRequests.any((a) => a.isValidated)
                                  ? AppColors.success
                                  : (activeRequests.isNotEmpty ? AppColors.warning : AppColors.secondary),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                            child: Text(
                              '${myAnnouncements.length}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Active Request Status Tracker Banner
            if (activeRequests.isNotEmpty) ...[
              Builder(
                builder: (_) {
                  final hasValidated = activeRequests.any((a) => a.isValidated);
                  final firstVal = activeRequests.firstWhere(
                    (a) => a.isValidated,
                    orElse: () => activeRequests.first,
                  );

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: hasValidated ? Colors.green.shade50 : Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: hasValidated ? Colors.green.shade300 : Colors.amber.shade300,
                        width: 1.2,
                      ),
                    ),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MyAnnouncementsScreen()),
                        );
                      },
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: hasValidated ? Colors.green.shade600 : Colors.amber.shade700,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              hasValidated ? Icons.event_available : Icons.hourglass_top,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      hasValidated
                                          ? 'Scheduled Airing Active'
                                          : 'Announcement in Escrow Validation',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12.5,
                                        color: hasValidated ? Colors.green.shade900 : Colors.amber.shade900,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      'View Details ›',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: hasValidated ? Colors.green.shade900 : Colors.amber.shade900,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  hasValidated
                                      ? 'Airing: ${firstVal.airingTimeSummary}'
                                      : 'Station is assigning slots for "${firstVal.radioName}". Tap to track.',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: hasValidated ? Colors.green.shade800 : Colors.amber.shade800,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],

            // Step Indicator Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  _stepDot(1, 'Details'),
                  _stepLine(1),
                  _stepDot(2, 'AI Text'),
                  _stepLine(2),
                  _stepDot(3, 'Tariff & Pay'),
                  _stepLine(3),
                  _stepDot(4, 'Escrow'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Main Step Content Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _stepTitle(),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Step $_step of 4',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  if (_step == 1) _buildStep1(),
                  if (_step == 2) _buildStep2(),
                  if (_step == 3) _buildStep3(),
                  if (_step == 4) _buildStep4(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _stepTitle() {
    switch (_step) {
      case 1: return 'Announcement Details & Schedule';
      case 2: return 'AI Notor 1 — Broadcast Ready Text';
      case 3: return 'AI Notor 2 — Tariff & Escrow Payment';
      case 4: return 'Announcement Submitted';
      default: return '';
    }
  }

  Widget _stepDot(int stepNumber, String label) {
    final isActive = _step >= stepNumber;
    final isCurrent = _step == stepNumber;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: isActive ? AppColors.primary : Colors.grey.shade300,
          child: Text(
            '$stepNumber',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isActive ? Colors.white : Colors.grey.shade600,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            color: isCurrent ? AppColors.primary : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _stepLine(int stepNumber) {
    final isDone = _step > stepNumber;
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 14, left: 4, right: 4),
        color: isDone ? AppColors.primary : Colors.grey.shade300,
      ),
    );
  }

  // STEP 1: Station, Category, Start Date & Period, Message Draft
  Widget _buildStep1() {
    final radioItems = _stations.isNotEmpty
        ? _stations.map((r) => DropdownMenuItem(value: r.id, child: Text(r.name))).toList()
        : _fallbackRadios.map((r) => DropdownMenuItem(value: r['id'], child: Text(r['name']!))).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Radio Station Picker
        const Text('Radio Station', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _selectedRadioId,
          items: radioItems,
          onChanged: (v) {
            if (v != null) {
              setState(() {
                _selectedRadioId = v;
                if (_stations.isNotEmpty) {
                  final found = _stations.firstWhere((r) => r.id == v, orElse: () => _stations.first);
                  _selectedRadioName = found.name;
                } else {
                  final found = _fallbackRadios.firstWhere((r) => r['id'] == v, orElse: () => _fallbackRadios.first);
                  _selectedRadioName = found['name']!;
                }
              });
              _loadTariffsForRadio(v);
            }
          },
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.radio, color: AppColors.primary),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
        const SizedBox(height: 16),

        // 2. Category (Configured strictly by Radio Admin)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Announcement Category', style: TextStyle(fontWeight: FontWeight.w600)),
            Text(
              'Defined by Radio Admin',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (_loadingTariffs)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                SizedBox(width: 10),
                Text('Loading admin categories...', style: TextStyle(fontSize: 13, color: Colors.grey)),
              ],
            ),
          )
        else
          DropdownButtonFormField<String>(
            value: _categories.contains(_category) ? _category : (_categories.isNotEmpty ? _categories.first : null),
            items: _categories.map((c) {
              return DropdownMenuItem(
                value: c,
                child: Text(c.isNotEmpty ? c[0].toUpperCase() + c.substring(1) : c),
              );
            }).toList(),
            onChanged: (v) {
              if (v != null) setState(() => _category = v);
            },
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.category_outlined, color: AppColors.primary, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
        const SizedBox(height: 16),

        // 3. Date selection before period (Start Date)
        const Text('Start Date', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        InkWell(
          onTap: _pickStartDate,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(10),
              color: Colors.grey.shade50,
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_month, color: AppColors.primary, size: 20),
                const SizedBox(width: 10),
                Text(
                  _formatDate(_startDate),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                const Text('Choose Date', style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 4. Diffusion Period (Days)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Diffusion Period', style: TextStyle(fontWeight: FontWeight.w600)),
            Text('$_diffusionDays days', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _periodOptions.map((days) {
            final isSelected = _diffusionDays == days;
            return ChoiceChip(
              label: Text('$days ${days == 1 ? "day" : "days"}'),
              selected: isSelected,
              selectedColor: AppColors.primary.withOpacity(0.15),
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primary : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              onSelected: (selected) {
                if (selected) setState(() => _diffusionDays = days);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 12),

        // 5. Broadcasts per day
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Broadcasts per Day', style: TextStyle(fontWeight: FontWeight.w600)),
            Text('${_diffusionsPerDay}x / day', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _diffusionsPerDayOptions.map((count) {
            final isSelected = _diffusionsPerDay == count;
            return ChoiceChip(
              label: Text('${count}x / day'),
              selected: isSelected,
              selectedColor: AppColors.primary.withOpacity(0.15),
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primary : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              onSelected: (selected) {
                if (selected) setState(() => _diffusionsPerDay = count);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 12),

        // 6. Broadcast Priority
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Broadcast Priority', style: TextStyle(fontWeight: FontWeight.w600)),
            Text(_priority.label, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: AnnouncementPriority.values.map((p) {
            final isSelected = _priority == p;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: p == AnnouncementPriority.priority ? 0 : 8),
                child: InkWell(
                  onTap: () => setState(() => _priority = p),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary.withOpacity(0.08) : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : Colors.grey.shade300,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              p == AnnouncementPriority.standard
                                  ? Icons.circle_outlined
                                  : p == AnnouncementPriority.high
                                      ? Icons.trending_up
                                      : Icons.priority_high,
                              size: 14,
                              color: isSelected ? AppColors.primary : Colors.grey.shade700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              p.label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? AppColors.primary : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          p.description,
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade600, height: 1.2),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),

        // 7. Schedule summary box
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50.withOpacity(0.7),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              const Icon(Icons.date_range, color: AppColors.primary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Broadcast Window: ${_formatDate(_startDate)}  ➔  ${_formatDate(_endDate)}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$_diffusionDays days · ${_diffusionDays * _diffusionsPerDay} total broadcasts (${_priority.label} priority) on $_selectedRadioName',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 8. Message Draft
        const Text('Your Announcement Draft', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: _draftController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'e.g. Happy birthday to our beloved mother Amina! We wish you good health and prosperity.',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 20),

        // Submit Step 1 Action
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _loading ? null : _runAiEnhancement,
            icon: const Icon(Icons.auto_awesome, size: 18),
            label: _loading
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Enhance with AI Notor 1'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }

  // STEP 2: AI Notor 1 Output
  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
          child: const Row(
            children: [
              Icon(Icons.auto_awesome, color: AppColors.primary),
              SizedBox(width: 8),
              Expanded(
                child: Text('AI Notor 1 formatted your message for radio broadcast standards.', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Text('Broadcast Ready Text:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: _finalText,
          maxLines: 4,
          onChanged: (v) => _finalText = v,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Chip(label: Text('Station: $_selectedRadioName')),
            Chip(label: Text('Word Count: $_wordCount')),
            Chip(label: Text('Duration: ${_durationSeconds}s')),
            Chip(label: Text('Schedule: ${_diffusionDays}d (${_diffusionDays * _diffusionsPerDay}x)')),
            Chip(label: Text('${_formatDate(_startDate)} - ${_formatDate(_endDate)}')),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            OutlinedButton(
              onPressed: () => setState(() => _step = 1),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Back'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _loading ? null : _calculatePrice,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _loading
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Calculate Price (AI Notor 2)'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // STEP 3: AI Notor 2 Price Breakdown & Payment
  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Station & Schedule Overview
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.radio, size: 18, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(_selectedRadioName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                    child: Text(_category.isNotEmpty ? _category[0].toUpperCase() + _category.substring(1) : _category, style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(6)),
                    child: Text(_priority.label, style: TextStyle(fontSize: 11, color: Colors.amber.shade900, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const Divider(height: 14),
              Text(
                '📅 ${_formatDate(_startDate)}  ➔  ${_formatDate(_endDate)}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                '$_diffusionDays days · ${_diffusionDays * _diffusionsPerDay} total broadcasts (${_priority.label} · ${_durationSeconds}s each)',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),

        // Tariff Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            children: [
              _priceRow('Base Tariff (to Radio)', '${_baseTariff.toStringAsFixed(0)} XAF'),
              const Divider(height: 16),
              _priceRow('Transfer Fee (4%)', '${_transferFee.toStringAsFixed(0)} XAF'),
              const Divider(height: 16),
              _priceRow('Total Price', '${_finalPrice.toStringAsFixed(0)} XAF', bold: true),
            ],
          ),
        ),
        const SizedBox(height: 16),

        const Text('Select Payment Method:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: ['MoMo', 'OM', 'Ecobank', 'Card'].map((m) => Expanded(
            child: RadioListTile<String>(
              value: m,
              groupValue: _paymentMethod,
              title: Text(m, style: const TextStyle(fontSize: 12)),
              contentPadding: EdgeInsets.zero,
              onChanged: (v) => setState(() => _paymentMethod = v!),
            ),
          )).toList(),
        ),
        if (_paymentMethod == 'MoMo' || _paymentMethod == 'OM') ...[
          const SizedBox(height: 12),
          Text('$_paymentMethod Phone Number', style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: 'e.g. +237 6XX XXX XXX',
              prefixIcon: const Icon(Icons.phone_android, color: AppColors.primary, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'A prompt will be sent to your phone to approve ${_finalPrice.toStringAsFixed(0)} XAF.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
        const SizedBox(height: 16),

        Row(
          children: [
            OutlinedButton(
              onPressed: () => setState(() => _step = 2),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Back'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _loading
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('Pay & Hold in Escrow (${_finalPrice.toStringAsFixed(0)} XAF)'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // STEP 4: Escrow Confirmation
  Widget _buildStep4() {
    return Column(
      children: [
        const Icon(Icons.check_circle, color: Colors.green, size: 56),
        const SizedBox(height: 12),
        const Text('Announcement Submitted!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Column(
            children: [
              if (_submittedRefId != null) ...[
                Text('Ref: $_submittedRefId', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 4),
              ],
              Text('Station: $_selectedRadioName', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text('Schedule: ${_formatDate(_startDate)} - ${_formatDate(_endDate)} ($_diffusionDays days)', style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 2),
              Text('Status: In Escrow (${_finalPrice.toStringAsFixed(0)} XAF held)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.green)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Your payment of ${_finalPrice.toStringAsFixed(0)} XAF is securely held in escrow until validated by $_selectedRadioName. If rejected, your base tariff will be refunded directly to your wallet.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: Colors.black87),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _resetForm,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Create Another'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isCreating = false;
                    _resetForm();
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('View My Announcements'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _priceRow(String label, String value, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: bold ? 15 : 13, fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        Text(value, style: TextStyle(fontSize: bold ? 16 : 13, fontWeight: FontWeight.bold, color: bold ? AppColors.primary : Colors.black87)),
      ],
    );
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _runAiEnhancement() async {
    if (_draftController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your announcement text draft.')),
      );
      return;
    }
    setState(() => _loading = true);
    final res = await _service.suggestImprovedText(text: _draftController.text.trim(), category: _category);
    setState(() {
      _finalText = res['improved_text'] ?? _draftController.text.trim();
      _wordCount = (res['word_count'] as int?) ?? _finalText.split(' ').length;
      _durationSeconds = (res['estimated_duration_seconds'] as int?) ?? 30;
      _loading = false;
      _step = 2;
    });
  }

  Future<void> _calculatePrice() async {
    setState(() => _loading = true);
    final totalDiffusions = _diffusionDays * _diffusionsPerDay;
    final tariff = _tariffs.firstWhere(
      (t) => t.category.toLowerCase() == _category.toLowerCase(),
      orElse: () => AnnouncementTariffEntry(category: _category, ratePerUnit: 500.0),
    );
    final res = await _service.calculatePrice(
      wordCount: _wordCount,
      durationSeconds: _durationSeconds,
      diffusionCount: totalDiffusions,
      ratePerUnit: tariff.ratePerUnit > 0 ? tariff.ratePerUnit : 500.0,
      priorityMultiplier: _priority.multiplier,
    );
    setState(() {
      _baseTariff = (res['base_tariff'] as num).toDouble();
      _transferFee = (res['transfer_fee'] as num).toDouble();
      _finalPrice = (res['final_price'] as num).toDouble();
      _loading = false;
      _step = 3;
    });
  }

  Future<bool> _showUssdWaitingModal({
    required BuildContext context,
    required String reference,
    required String ussdCode,
    required String phone,
  }) async {
    bool isCompleted = false;

    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogCtx) {
            return StatefulBuilder(
              builder: (ctx, setModalState) {
                // Background polling
                Future.microtask(() async {
                  if (isCompleted) return;
                  final status = await _campayService.pollTransactionStatus(
                    reference: reference,
                    interval: const Duration(seconds: 3),
                    maxAttempts: 15,
                  );
                  if (!dialogCtx.mounted || isCompleted) return;
                  isCompleted = true;
                  if (status == CampayTransactionStatus.successful) {
                    Navigator.of(dialogCtx).pop(true);
                  }
                });

                return Dialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.phonelink_ring_rounded,
                            color: AppColors.primary,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Approve Payment Prompt',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'A payment prompt of ${_finalPrice.toStringAsFixed(0)} XAF has been sent to $phone.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.dialpad, size: 16, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text(
                                'If no prompt appears, dial $ussdCode',
                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.primary),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Waiting for authorization PIN... Check your phone screen.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () {
                                  isCompleted = true;
                                  Navigator.of(dialogCtx).pop(false);
                                },
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  isCompleted = true;
                                  Navigator.of(dialogCtx).pop(true);
                                },
                                icon: const Icon(Icons.check, size: 16),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                label: const Text('Approve Payment'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ) ??
        false;
  }

  Future<void> _submit() async {
    final user = FirebaseAuth.instance.currentUser;
    final listenerId = user?.uid ?? 'listener_123';
    final listenerName = user?.displayName ?? 'Listener';
    final listenerEmail = user?.email ?? 'listener@radiohub.app';

    if ((_paymentMethod == 'MoMo' || _paymentMethod == 'OM') && _phoneCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your phone number to receive the payment prompt.')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      String paymentRef = 'PAY_${DateTime.now().millisecondsSinceEpoch}';

      if (_paymentMethod == 'MoMo' || _paymentMethod == 'OM') {
        final externalRef = 'ANN_${DateTime.now().millisecondsSinceEpoch}';
        final collectResult = await _campayService.collect(
          amount: _finalPrice,
          phone: _phoneCtrl.text.trim(),
          description: 'Announcement broadcast on $_selectedRadioName',
          externalReference: externalRef,
        );

        if (!mounted) return;
        setState(() => _loading = false);

        final ussdCode = collectResult.ussdCode ?? (_paymentMethod == 'MoMo' ? '*126#' : '#150*50#');
        final paid = await _showUssdWaitingModal(
          context: context,
          reference: collectResult.reference ?? externalRef,
          ussdCode: ussdCode,
          phone: _phoneCtrl.text.trim(),
        );

        if (!paid) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Payment authorization was cancelled or timed out.')),
            );
          }
          return;
        }

        paymentRef = collectResult.reference ?? externalRef;
        setState(() => _loading = true);
      }

      // 1. Submit announcement
      final totalDiffusions = _diffusionDays * _diffusionsPerDay;
      final id = await _service.submitAnnouncementRequest(
        radioId: _selectedRadioId,
        radioName: _selectedRadioName,
        listenerId: listenerId,
        listenerName: listenerName,
        listenerEmail: listenerEmail,
        category: _category,
        originalText: _draftController.text.trim(),
        finalText: _finalText,
        wordCount: _wordCount,
        durationSeconds: _durationSeconds,
        diffusionCount: totalDiffusions,
        baseTariff: _baseTariff,
        transferFee: _transferFee,
        finalPrice: _finalPrice,
        paymentMethod: _paymentMethod,
        priority: _priority,
        startDate: _startDate,
        endDate: _endDate,
        diffusionPeriodDays: _diffusionDays,
        diffusionsPerDay: _diffusionsPerDay,
      );

      final db = FirebaseFirestore.instance;

      // 2. Escrow account record
      final escrowRef = db.collection('escrow_accounts').doc();
      await escrowRef.set({
        'announcementId': id,
        'listenerId': listenerId,
        'radioId': _selectedRadioId,
        'baseAmount': _baseTariff,
        'transferFee': _transferFee,
        'finalPrice': _finalPrice,
        'currency': 'XAF',
        'paymentMethod': _paymentMethod,
        'paymentReference': paymentRef,
        'payerPhone': _phoneCtrl.text.trim().isNotEmpty ? _phoneCtrl.text.trim() : null,
        'status': 'held',
        'heldAt': FieldValue.serverTimestamp(),
      });

      // 3. Transactions record
      await db.collection('transactions').add({
        'radioId': _selectedRadioId,
        'radioName': _selectedRadioName,
        'type': 'announcement',
        'status': 'inEscrow',
        'baseAmount': _baseTariff,
        'transferFee': _transferFee,
        'totalAmount': _finalPrice,
        'currency': 'XAF',
        'initiatorId': listenerId,
        'initiatorName': listenerName,
        'paymentMethod': _paymentMethod,
        'announcementId': id,
        'escrowReference': escrowRef.id,
        'createdAt': FieldValue.serverTimestamp(),
        'escrowHeldAt': FieldValue.serverTimestamp(),
      });

      // 4. Send Confirmation Notification to Listener
      await db.collection('notifications').add({
        'userId': listenerId,
        'type': 'payment',
        'title': 'Payment Confirmed & Held in Escrow',
        'body': 'Your payment of ${_finalPrice.toStringAsFixed(0)} XAF for $_selectedRadioName has been confirmed. Ref: $paymentRef.',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'data': {
          'announcementId': id,
          'reference': paymentRef,
          'amount': _finalPrice,
          'radioName': _selectedRadioName,
        },
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment confirmed! Reference: $paymentRef'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _submittedRefId = id.isNotEmpty ? id : paymentRef;
          _loading = false;
          _step = 4;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
        setState(() => _loading = false);
      }
    }
  }
}
