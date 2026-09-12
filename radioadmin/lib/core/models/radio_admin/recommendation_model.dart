import '../../utils/firestore_parsers.dart';

class AudimatPeak {
  final String hour;
  final int avgListeners;
  final String recommendation;

  AudimatPeak({
    required this.hour,
    required this.avgListeners,
    required this.recommendation,
  });

  factory AudimatPeak.fromJson(Map<String, dynamic> j) => AudimatPeak(
    hour: (j['hour'] ?? '').toString(),
    avgListeners: FSParsers.toInt(j['avg_listeners'] ?? j['avgListeners']),
    recommendation: (j['recommendation'] ?? '').toString(),
  );
}

class ShowPerformer {
  final String show;
  final int listeners;
  final double retention;
  final String recommendation;

  ShowPerformer({
    required this.show,
    required this.listeners,
    required this.retention,
    required this.recommendation,
  });

  factory ShowPerformer.fromJson(Map<String, dynamic> j) => ShowPerformer(
    show: (j['show'] ?? j['showName'] ?? '').toString(),
    listeners: FSParsers.toInt(j['listeners'] ?? j['avgListeners']),
    retention: FSParsers.toDouble(j['retention'] ?? j['retentionRate']),
    recommendation: (j['recommendation'] ?? '').toString(),
  );
}

class ScheduleChangeSuggestion {
  final String current;
  final String suggested;
  final String reason;

  ScheduleChangeSuggestion({
    required this.current,
    required this.suggested,
    required this.reason,
  });

  factory ScheduleChangeSuggestion.fromJson(Map<String, dynamic> j) => ScheduleChangeSuggestion(
    current: j['current'] ?? '',
    suggested: j['suggested'] ?? '',
    reason: j['reason'] ?? '',
  );
}

class CategoryRecommendation {
  final String category;
  final String reason;
  final int requests;

  CategoryRecommendation({
    required this.category,
    required this.reason,
    this.requests = 0,
  });

  factory CategoryRecommendation.fromJson(dynamic j) {
    if (j is String) {
      return CategoryRecommendation(category: j, reason: '');
    }
    if (j is Map<String, dynamic>) {
      return CategoryRecommendation(
        category: (j['category'] ?? '').toString(),
        reason: (j['reason'] ?? '').toString(),
        requests: FSParsers.toInt(j['requests']),
      );
    }
    return CategoryRecommendation(category: '', reason: '');
  }
}

class ScheduleSlot {
  final String day;
  final String hour;
  final String reason;

  ScheduleSlot({
    required this.day,
    required this.hour,
    required this.reason,
  });

  factory ScheduleSlot.fromJson(Map<String, dynamic> j) => ScheduleSlot(
    day: (j['day'] ?? '').toString(),
    hour: (j['hour'] ?? j['timeSlot'] ?? '').toString(),
    reason: (j['reason'] ?? '').toString(),
  );
}

class AudimatInsights {
  final List<AudimatPeak> peakHours;
  final List<AudimatPeak> decliningSlots;

  AudimatInsights({
    required this.peakHours,
    required this.decliningSlots,
  });

  factory AudimatInsights.fromJson(Map<String, dynamic> j) => AudimatInsights(
    peakHours: (j['peak_hours'] as List? ?? [])
        .map((x) => AudimatPeak.fromJson(x as Map<String, dynamic>))
        .toList(),
    decliningSlots: (j['declining_slots'] as List? ?? [])
        .map((x) => AudimatPeak.fromJson(x as Map<String, dynamic>))
        .toList(),
  );
}

class ShowInsights {
  final List<ShowPerformer> topPerformers;
  final List<ShowPerformer> underperformers;
  final List<ScheduleChangeSuggestion> suggestedScheduleChanges;

  ShowInsights({
    required this.topPerformers,
    required this.underperformers,
    required this.suggestedScheduleChanges,
  });

  factory ShowInsights.fromJson(Map<String, dynamic> j) => ShowInsights(
    topPerformers: (j['top_performers'] as List? ?? [])
        .map((x) => ShowPerformer.fromJson(x as Map<String, dynamic>))
        .toList(),
    underperformers: (j['underperformers'] as List? ?? [])
        .map((x) => ShowPerformer.fromJson(x as Map<String, dynamic>))
        .toList(),
    suggestedScheduleChanges: (j['suggested_schedule_changes'] as List? ?? [])
        .map((x) => ScheduleChangeSuggestion.fromJson(x as Map<String, dynamic>))
        .toList(),
  );
}

class RevenueInsights {
  final double announcementRevenue;
  final double subscriptionRevenue;
  final double refundTotal;
  final double projectedMonthly;
  final List<CategoryRecommendation> categoriesRecommended;

  RevenueInsights({
    required this.announcementRevenue,
    required this.subscriptionRevenue,
    required this.refundTotal,
    required this.projectedMonthly,
    required this.categoriesRecommended,
  });

  factory RevenueInsights.fromJson(Map<String, dynamic> j) {
    final catList = j['categories_recommended'] ?? j['recommended_categories'] ?? j['announcement_categories_recommended'] ?? [];
    return RevenueInsights(
      announcementRevenue: FSParsers.toDouble(j['announcement_revenue']),
      subscriptionRevenue: FSParsers.toDouble(j['subscription_revenue']),
      refundTotal: FSParsers.toDouble(j['refund_total']),
      projectedMonthly: FSParsers.toDouble(j['projected_monthly']),
      categoriesRecommended: (catList as List)
          .map((x) => CategoryRecommendation.fromJson(x))
          .toList(),
    );
  }
}

class SchedulingInsights {
  final List<ScheduleSlot> recommendedSlots;
  final List<ScheduleSlot> avoidSlots;

  SchedulingInsights({
    required this.recommendedSlots,
    required this.avoidSlots,
  });

  factory SchedulingInsights.fromJson(Map<String, dynamic> j) => SchedulingInsights(
    recommendedSlots: (j['recommended_slots'] as List? ?? [])
        .map((x) => ScheduleSlot.fromJson(x as Map<String, dynamic>))
        .toList(),
    avoidSlots: (j['avoid_slots'] as List? ?? [])
        .map((x) => ScheduleSlot.fromJson(x as Map<String, dynamic>))
        .toList(),
  );
}

class ShowComparison {
  final String strongShow;
  final String weakShow;
  final int listenerGap;
  final double retentionGap;
  final List<AudienceDiff> audienceDiff;
  final List<CompareSuggestion> suggestions;

  ShowComparison({
    required this.strongShow,
    required this.weakShow,
    required this.listenerGap,
    required this.retentionGap,
    required this.audienceDiff,
    required this.suggestions,
  });

  factory ShowComparison.fromJson(Map<String, dynamic> j) => ShowComparison(
    strongShow: (j['strongShow'] ?? '').toString(),
    weakShow: (j['weakShow'] ?? '').toString(),
    listenerGap: FSParsers.toInt(j['listenerGap']),
    retentionGap: FSParsers.toDouble(j['retentionGap']),
    audienceDiff: (j['audienceDiff'] as List? ?? [])
        .map((e) => AudienceDiff.fromJson(e as Map<String, dynamic>)).toList(),
    suggestions: (j['suggestions'] as List? ?? [])
        .map((e) => CompareSuggestion.fromJson(e as Map<String, dynamic>)).toList(),
  );
}

class AudienceDiff {
  final String ageGroup;
  final double strongShowPct;
  final double weakShowPct;
  final double diff;
  AudienceDiff({
    required this.ageGroup,
    required this.strongShowPct,
    required this.weakShowPct,
    required this.diff,
  });
  factory AudienceDiff.fromJson(Map<String, dynamic> j) => AudienceDiff(
    ageGroup: (j['ageGroup'] ?? '').toString(),
    strongShowPct: FSParsers.toDouble(j['strongShowPct']),
    weakShowPct: FSParsers.toDouble(j['weakShowPct']),
    diff: FSParsers.toDouble(j['diff']),
  );
}

class CompareSuggestion {
  final String attribute;
  final String observation;
  final String action;
  final String expectedEffect;
  CompareSuggestion({
    required this.attribute,
    required this.observation,
    required this.action,
    required this.expectedEffect,
  });
  factory CompareSuggestion.fromJson(Map<String, dynamic> j) => CompareSuggestion(
    attribute: (j['attribute'] ?? '').toString(),
    observation: (j['observation'] ?? '').toString(),
    action: (j['action'] ?? '').toString(),
    expectedEffect: (j['expectedEffect'] ?? '').toString(),
  );
}

class ShowDiagnostic {
  final String show;
  final int listeners;
  final double retention;
  final int engagement;
  final double concentration;
  final String? topGroup;
  final List<AgeBucketPct> distribution;
  final ContentProfile contentProfile;
  final String verdict;

  ShowDiagnostic({
    required this.show,
    required this.listeners,
    required this.retention,
    required this.engagement,
    required this.concentration,
    this.topGroup,
    required this.distribution,
    required this.contentProfile,
    required this.verdict,
  });

  factory ShowDiagnostic.fromJson(Map<String, dynamic> j) {
    final spread = j['audienceSpread'] is Map ? j['audienceSpread'] as Map<String, dynamic> : <String, dynamic>{};
    return ShowDiagnostic(
      show: (j['show'] ?? '').toString(),
      listeners: FSParsers.toInt(j['listeners']),
      retention: FSParsers.toDouble(j['retention']),
      engagement: FSParsers.toInt(j['engagement']),
      concentration: FSParsers.toDouble(spread['concentration']),
      topGroup: spread['topGroup']?.toString(),
      distribution: (spread['distribution'] as List? ?? [])
          .map((e) => AgeBucketPct.fromJson(e as Map<String, dynamic>)).toList(),
      contentProfile: ContentProfile.fromJson(j['contentProfile'] is Map ? j['contentProfile'] as Map<String, dynamic> : {}),
      verdict: (j['verdict'] ?? '').toString(),
    );
  }
}

class AgeBucketPct {
  final String ageGroup;
  final double pct;
  AgeBucketPct({required this.ageGroup, required this.pct});
  factory AgeBucketPct.fromJson(Map<String, dynamic> j) =>
      AgeBucketPct(ageGroup: (j['ageGroup'] ?? '').toString(), pct: FSParsers.toDouble(j['pct']));
}

class ContentProfile {
  final List<String> formats;
  final List<String> tones;
  final List<String> topics;
  final List<String> languageRegisters;
  ContentProfile({
    this.formats = const [],
    this.tones = const [],
    this.topics = const [],
    this.languageRegisters = const [],
  });
  factory ContentProfile.fromJson(Map<String, dynamic> j) => ContentProfile(
    formats: List<String>.from(j['formats'] ?? []),
    tones: List<String>.from(j['tones'] ?? []),
    topics: List<String>.from(j['topics'] ?? []),
    languageRegisters: List<String>.from(j['languageRegisters'] ?? []),
  );
}

class RadioInsights {
  final AudimatInsights? audimat;
  final ShowInsights? shows;
  final List<ShowComparison> comparisons;
  final List<ShowDiagnostic> diagnostics;
  final RevenueInsights? revenue;
  final SchedulingInsights? scheduling;
  final Map<String, dynamic>? meta;
  final DateTime generatedAt;

  RadioInsights({
    this.audimat,
    this.shows,
    this.comparisons = const [],
    this.diagnostics = const [],
    this.revenue,
    this.scheduling,
    this.meta,
    DateTime? generatedAt,
  }) : generatedAt = generatedAt ?? DateTime.now();

  factory RadioInsights.fromJson(Map<String, dynamic> j) => RadioInsights(
    audimat: j['audimat'] != null ? AudimatInsights.fromJson(j['audimat'] as Map<String, dynamic>) : null,
    shows: j['shows'] != null ? ShowInsights.fromJson(j['shows'] as Map<String, dynamic>) : null,
    comparisons: (j['comparisons'] as List? ?? [])
        .map((e) => ShowComparison.fromJson(e as Map<String, dynamic>))
        .toList(),
    diagnostics: (j['diagnostics'] as List? ?? [])
        .map((e) => ShowDiagnostic.fromJson(e as Map<String, dynamic>))
        .toList(),
    revenue: j['revenue'] != null ? RevenueInsights.fromJson(j['revenue'] as Map<String, dynamic>) : null,
    scheduling: j['scheduling'] != null ? SchedulingInsights.fromJson(j['scheduling'] as Map<String, dynamic>) : null,
    meta: j['meta'] as Map<String, dynamic>?,
    generatedAt: j['meta'] != null && j['meta']['generated_at'] != null
        ? DateTime.tryParse(j['meta']['generated_at'].toString()) ?? DateTime.now()
        : DateTime.now(),
  );

  static RadioInsights mock(String radioId) => RadioInsights.fromJson({
    'audimat': {
      'peak_hours': [
        {'hour': '08:00', 'avg_listeners': 2456, 'recommendation': 'Audience peaks at 08:00. Schedule high-value shows here.'},
        {'hour': '12:00', 'avg_listeners': 1876, 'recommendation': 'High lunchtime engagement. Good slot for promotional announcements.'},
        {'hour': '19:00', 'avg_listeners': 2100, 'recommendation': 'Prime evening drive time. Prioritize engaged hosts.'},
      ],
      'declining_slots': [
        {'hour': '15:00', 'avg_listeners': 234, 'recommendation': 'Rework or replace with automated music block.'},
      ],
    },
    'shows': {
      'top_performers': [
        {'show': 'Mid-Day Talk', 'listeners': 2400, 'retention': 0.78, 'recommendation': 'Extend by 30 minutes for higher retention.'},
        {'show': 'Morning Love Letters', 'listeners': 1900, 'retention': 0.72, 'recommendation': 'Add live call-ins or guest interviews.'},
      ],
      'underperformers': [
        {'show': 'Afternoon Chill', 'listeners': 720, 'retention': 0.42, 'recommendation': 'Broaden format beyond pure music mix to reduce 62% youth concentration.'},
      ],
      'suggested_schedule_changes': [
        {
          'current': 'Afternoon Chill — 14:00',
          'suggested': 'Introduce listener call-in segment and universal topics',
          'reason': 'Afternoon audience shows high churn with narrow music mix format.',
        }
      ],
    },
    'comparisons': [
      {
        'strongShow': 'Mid-Day Talk',
        'weakShow': 'Afternoon Chill',
        'listenerGap': 1680,
        'retentionGap': 0.36,
        'audienceDiff': [
          {'ageGroup': '18–24', 'strongShowPct': 12.0, 'weakShowPct': 62.0, 'diff': -50.0},
          {'ageGroup': '25–34', 'strongShowPct': 28.0, 'weakShowPct': 28.0, 'diff': 0.0},
          {'ageGroup': '35–44', 'strongShowPct': 31.0, 'weakShowPct': 6.0, 'diff': 25.0},
          {'ageGroup': '45–54', 'strongShowPct': 18.0, 'weakShowPct': 3.0, 'diff': 15.0},
          {'ageGroup': '55+', 'strongShowPct': 11.0, 'weakShowPct': 1.0, 'diff': 10.0},
        ],
        'suggestions': [
          {
            'attribute': 'audience breadth',
            'observation': 'Mid-Day Talk reaches all age groups, while Afternoon Chill concentrates 62% in 18–24.',
            'action': 'Broaden topics toward universal themes and use a neutral language register.',
            'expectedEffect': 'Wider age distribution within 2–4 weeks.',
          },
          {
            'attribute': 'format',
            'observation': 'Mid-Day Talk uses call in interview, Afternoon Chill does not.',
            'action': 'Introduce a listener call-in segment into Afternoon Chill for 2 weeks.',
            'expectedEffect': 'Higher engagement and wider age representation.',
          },
        ],
      }
    ],
    'diagnostics': [
      {
        'show': 'Mid-Day Talk',
        'listeners': 2400,
        'retention': 0.78,
        'engagement': 320,
        'audienceSpread': {
          'concentration': 0.31,
          'topGroup': '35–44',
          'distribution': [
            {'ageGroup': '18–24', 'pct': 12.0},
            {'ageGroup': '25–34', 'pct': 28.0},
            {'ageGroup': '35–44', 'pct': 31.0},
            {'ageGroup': '45–54', 'pct': 18.0},
            {'ageGroup': '55+', 'pct': 11.0},
          ],
        },
        'contentProfile': {
          'formats': ['call_in_interview'],
          'tones': ['uplifting'],
          'topics': ['Finding love after 40', 'Everyday relationship wins'],
          'languageRegisters': ['neutral'],
        },
        'verdict': 'Broad-appeal anchor show. Core daytime retention driver.',
      },
      {
        'show': 'Afternoon Chill',
        'listeners': 720,
        'retention': 0.42,
        'engagement': 110,
        'audienceSpread': {
          'concentration': 0.62,
          'topGroup': '18–24',
          'distribution': [
            {'ageGroup': '18–24', 'pct': 62.0},
            {'ageGroup': '25–34', 'pct': 28.0},
            {'ageGroup': '35–44', 'pct': 6.0},
            {'ageGroup': '45–54', 'pct': 3.0},
            {'ageGroup': '55+', 'pct': 1.0},
          ],
        },
        'contentProfile': {
          'formats': ['music_mix'],
          'tones': ['casual'],
          'topics': ['Gaming soundtracks', 'Trending tracks'],
          'languageRegisters': ['slang'],
        },
        'verdict': 'High youth concentration (62% 18–24). Narrow reach and low completion (42%).',
      },
    ],
    'revenue': {
      'announcement_revenue': 45000.0,
      'subscription_revenue': 30000.0,
      'refund_total': 0.0,
      'projected_monthly': 125000.0,
      'categories_recommended': [
        {'category': 'birthday', 'reason': 'High demand, low tariff'},
        {'category': 'promotional', 'reason': 'Growing local business segment'},
        {'category': 'event', 'reason': 'Strong weekend demand'},
      ],
    },
    'scheduling': {
      'recommended_slots': [
        {'day': 'Wednesday', 'hour': '20:00', 'reason': 'Audience peak with low competing programming.'},
        {'day': 'Friday', 'hour': '18:00', 'reason': 'High weekend prep listener activity.'},
      ],
      'avoid_slots': [
        {'day': 'Sunday', 'hour': '10:00', 'reason': 'Low engagement historically.'},
        {'day': 'Weekdays', 'hour': '15:00', 'reason': 'Audience trough across all demographics.'},
      ],
    },
    'meta': {
      'model': 'radio-bi-v1',
      'generated_at': DateTime.now().toIso8601String(),
    },
  });
}
