from datetime import datetime, timedelta
from statistics import mean
from collections import defaultdict
from typing import Dict, Any, List, Optional


AGE_BUCKETS = ['18_24', '25_34', '35_44', '45_54', '55_plus']
AGE_LABELS = {
    '18_24': '18–24', '25_34': '25–34', '35_44': '35–44',
    '45_54': '45–54', '55_plus': '55+',
}


class RadioInsightsEngine:
    """
    Pure heuristic + comparative engine. No external API.
    Reads live Firestore data. Produces diagnostic insights with
    cross-show comparison and concrete improvement suggestions.
    """

    def __init__(self, db=None, llm=None):
        self.db = db
        self.llm = llm

    # ---------------- PUBLIC ----------------

    def generate(self, radio_id: str, time_range: str = 'last_30_days') -> Dict[str, Any]:
        days = {'today': 1, 'last_7_days': 7, 'last_30_days': 30, 'last_90_days': 90}.get(time_range, 30)
        cutoff = datetime.utcnow() - timedelta(days=days)

        sessions = self._fetch_sessions(radio_id, cutoff)
        analytics = self._fetch_analytics(radio_id, cutoff)
        announcements = self._fetch_announcements(radio_id, cutoff)
        transactions = self._fetch_transactions(radio_id, cutoff)

        hourly = self._bucket_by_hour(analytics)
        show_perf = self._compute_show_performance(sessions)
        comparisons = self._compare_shows(show_perf)
        diagnostics = self._diagnose(show_perf, sessions)

        return {
            'audimat': self._audimat_insights(hourly),
            'shows': {
                'top_performers': [s for s in show_perf if s['listeners'] >= 1000 and s['retention'] >= 0.6][:5],
                'underperformers': [s for s in show_perf if s['listeners'] < 300 or s['retention'] < 0.4][:5],
                'suggested_schedule_changes': self._suggest_moves(show_perf),
            },
            'comparisons': comparisons,          # Pairwise diagnostics
            'diagnostics': diagnostics,          # Per-show "why"
            'revenue': self._compute_revenue(transactions, announcements),
            'scheduling': self._scheduling_insights(hourly, sessions),
            'meta': {
                'generated_at': datetime.utcnow().isoformat(),
                'model': 'radio-bi-heuristic-v2-diagnostic',
                'time_range': time_range,
                'days_analyzed': days,
                'sessions_analyzed': len(sessions),
                'external_api': False,
            },
        }

    # ---------------- FETCH ----------------

    def _fetch_sessions(self, radio_id: str, cutoff: datetime) -> List[dict]:
        if not self.db:
            return []
        try:
            docs = list(
                self.db.collection('sessions')
                .where('radioId', '==', radio_id)
                .where('startTime', '>=', cutoff)
                .stream()
            )
            if not docs:
                docs = list(
                    self.db.collection('sessions')
                    .where('programId', '==', radio_id)
                    .where('startTime', '>=', cutoff)
                    .stream()
                )
            return [{**d.to_dict(), 'id': d.id} for d in docs]
        except Exception:
            return []

    def _fetch_analytics(self, radio_id: str, cutoff: datetime) -> List[dict]:
        if not self.db:
            return []
        try:
            return [
                d.to_dict()
                for d in self.db.collection('listener_analytics')
                .where('radioId', '==', radio_id)
                .where('date', '>=', cutoff)
                .stream()
            ]
        except Exception:
            return []

    def _fetch_announcements(self, radio_id: str, cutoff: datetime) -> List[dict]:
        if not self.db:
            return []
        try:
            return [
                d.to_dict()
                for d in self.db.collection('announcements')
                .where('radioId', '==', radio_id)
                .where('createdAt', '>=', cutoff)
                .stream()
            ]
        except Exception:
            return []

    def _fetch_transactions(self, radio_id: str, cutoff: datetime) -> List[dict]:
        if not self.db:
            return []
        try:
            return [
                d.to_dict()
                for d in self.db.collection('transactions')
                .where('radioId', '==', radio_id)
                .where('createdAt', '>=', cutoff)
                .stream()
            ]
        except Exception:
            return []

    # ---------------- AGGREGATE ----------------

    def _bucket_by_hour(self, analytics: List[dict]) -> Dict[int, float]:
        buckets: Dict[int, List[int]] = defaultdict(list)
        for a in analytics:
            date = a.get('date')
            if not date:
                continue
            buckets[date.hour].append(a.get('count', 0))
        return {h: (mean(v) if v else 0.0) for h, v in buckets.items()}

    def _compute_show_performance(self, sessions: List[dict]) -> List[dict]:
        """Aggregate per-show metrics, including audience segments."""
        by_name: Dict[str, List[dict]] = defaultdict(list)
        for s in sessions:
            by_name[s.get('programName', 'Unknown')].append(s)

        out = []
        for name, items in by_name.items():
            listeners = [i.get('listenerCount', 0) for i in items if 'listenerCount' in i]
            if not listeners:
                continue

            # Aggregate audience distribution
            age_dist = self._aggregate_age_distribution(items)
            fmt_set = {i.get('format') for i in items if i.get('format')}
            tone_set = {i.get('tone') for i in items if i.get('tone')}
            topic_set = {
                (i.get('theme') or {}).get('category')
                for i in items if (i.get('theme') or {}).get('category')
            }
            register_set = {i.get('languageRegister') for i in items if i.get('languageRegister')}

            avg_completion = mean([i.get('completionRate', 0) for i in items]) if items else 0
            avg_engagement = mean([i.get('engagementCount', 0) for i in items]) if items else 0

            out.append({
                'show': name,
                'listeners': int(mean(listeners)),
                'retention': round(avg_completion, 2),
                'sessions': len(items),
                'engagement': int(avg_engagement),
                'ageDistribution': age_dist,
                'topAgeGroup': max(age_dist, key=age_dist.get) if age_dist else None,
                'concentration': round(max(age_dist.values()), 2) if age_dist else 0.0,
                'formats': sorted(f for f in fmt_set if f),
                'tones': sorted(t for t in tone_set if t),
                'topics': sorted(t for t in topic_set if t),
                'languageRegisters': sorted(r for r in register_set if r),
                'sampleStartTimes': [i.get('startTime') for i in items if i.get('startTime')][:3],
            })

        out.sort(key=lambda x: (x['listeners'], x['retention']), reverse=True)
        return out

    def _aggregate_age_distribution(self, sessions: List[dict]) -> Dict[str, float]:
        """Average the audience ageDistribution across the sessions of a show."""
        totals = {b: [] for b in AGE_BUCKETS}
        for s in sessions:
            dist = (s.get('audience') or {}).get('ageDistribution') or {}
            for b in AGE_BUCKETS:
                if b in dist:
                    totals[b].append(dist[b])
        return {b: round(mean(v), 3) if v else 0.0 for b, v in totals.items()}

    # ---------------- COMPARISONS ----------------

    def _compare_shows(self, show_perf: List[dict]) -> List[dict]:
        """
        For each underperformer, find the top performer with the most similar
        topic category, and produce a side-by-side diagnostic + suggestion.
        """
        if len(show_perf) < 2:
            return []

        top = show_perf[:3]
        bottom = [s for s in show_perf if s['listeners'] < 500 or s['concentration'] > 0.55]

        comparisons = []
        for weak in bottom:
            # Find best pairing by shared topics
            best_match: Optional[dict] = None
            best_overlap = -1
            for strong in top:
                if strong['show'] == weak['show']:
                    continue
                overlap = len(set(strong['topics']) & set(weak['topics']))
                if overlap > best_overlap:
                    best_overlap = overlap
                    best_match = strong

            if not best_match:
                continue

            comparison = {
                'strongShow': best_match['show'],
                'weakShow': weak['show'],
                'listenerGap': best_match['listeners'] - weak['listeners'],
                'retentionGap': round(best_match['retention'] - weak['retention'], 2),
                'audienceDiff': self._audience_diff(best_match, weak),
                'contentDiff': self._content_diff(best_match, weak),
                'suggestions': self._build_suggestions(best_match, weak),
            }
            comparisons.append(comparison)

        return comparisons

    def _audience_diff(self, strong: dict, weak: dict) -> List[dict]:
        """
        Per age bucket, how much of the strong show's audience is in that bucket
        vs the weak show's.
        """
        out = []
        for b in AGE_BUCKETS:
            s_pct = strong['ageDistribution'].get(b, 0)
            w_pct = weak['ageDistribution'].get(b, 0)
            out.append({
                'ageGroup': AGE_LABELS[b],
                'strongShowPct': round(s_pct * 100, 1),
                'weakShowPct': round(w_pct * 100, 1),
                'diff': round((s_pct - w_pct) * 100, 1),
            })
        return out

    def _content_diff(self, strong: dict, weak: dict) -> Dict[str, Any]:
        return {
            'formats': {
                'strong': strong['formats'],
                'weak': weak['formats'],
                'missingInWeak': sorted(set(strong['formats']) - set(weak['formats'])),
            },
            'tones': {
                'strong': strong['tones'],
                'weak': weak['tones'],
                'missingInWeak': sorted(set(strong['tones']) - set(weak['tones'])),
            },
            'topics': {
                'strong': strong['topics'],
                'weak': weak['topics'],
                'missingInWeak': sorted(set(strong['topics']) - set(weak['topics'])),
            },
            'languageRegisters': {
                'strong': strong['languageRegisters'],
                'weak': weak['languageRegisters'],
            },
        }

    def _build_suggestions(self, strong: dict, weak: dict) -> List[dict]:
        """
        Rule-based suggestions derived from the differences.
        Each suggestion includes which attribute to change and why.
        """
        suggestions = []

        # 1. Age breadth
        if strong['concentration'] < 0.35 and weak['concentration'] > 0.5:
            suggestions.append({
                'attribute': 'audience breadth',
                'observation': (
                    f"{strong['show']} reaches all age groups "
                    f"(top group only {int(strong['concentration'] * 100)}%), "
                    f"while {weak['show']} concentrates {int(weak['concentration'] * 100)}% "
                    f"in one group."
                ),
                'action': 'Broaden topics toward universal themes and use a neutral language register.',
                'expectedEffect': 'Wider age distribution within 2–4 weeks.',
            })

        # 2. Format
        missing_formats = set(strong['formats']) - set(weak['formats'])
        if missing_formats:
            fmt = next(iter(missing_formats))
            if fmt in ('call_in', 'call_in_interview'):
                suggestions.append({
                    'attribute': 'format',
                    'observation': f"{strong['show']} uses {fmt.replace('_', ' ')}, {weak['show']} does not.",
                    'action': f'Introduce a listener call-in segment into {weak["show"]} for 2 weeks.',
                    'expectedEffect': 'Higher engagement and wider age representation.',
                })

        # 3. Language register
        strong_reg = set(strong['languageRegisters'])
        weak_reg = set(weak['languageRegisters'])
        if 'neutral' in strong_reg and 'neutral' not in weak_reg:
            suggestions.append({
                'attribute': 'language register',
                'observation': f"{strong['show']} uses neutral language; {weak['show']} uses {sorted(weak_reg)}.",
                'action': f'Shift {weak["show"]} toward neutral language in host scripts.',
                'expectedEffect': 'Broader listener comprehension across ages.',
            })

        # 4. Tone
        missing_tones = set(strong['tones']) - set(weak['tones'])
        if 'uplifting' in missing_tones or 'nostalgic' in missing_tones:
            tone = 'uplifting' if 'uplifting' in missing_tones else 'nostalgic'
            suggestions.append({
                'attribute': 'tone',
                'observation': f"{strong['show']} leans {tone}; {weak['show']} does not.",
                'action': f'Add a {tone} segment to {weak["show"]} weekly.',
                'expectedEffect': 'Positive sentiment drives repeat listening.',
            })

        return suggestions

    def _diagnose(self, show_perf: List[dict], sessions: List[dict]) -> List[dict]:
        """
        Per-show diagnostic card. Pure description, no prediction.
        """
        out = []
        for s in show_perf:
            out.append({
                'show': s['show'],
                'listeners': s['listeners'],
                'retention': s['retention'],
                'engagement': s['engagement'],
                'audienceSpread': {
                    'concentration': s['concentration'],
                    'topGroup': AGE_LABELS.get(s['topAgeGroup'], s['topAgeGroup']) if s['topAgeGroup'] else None,
                    'distribution': [
                        {'ageGroup': AGE_LABELS[b], 'pct': round(s['ageDistribution'].get(b, 0) * 100, 1)}
                        for b in AGE_BUCKETS
                    ],
                },
                'contentProfile': {
                    'formats': s['formats'],
                    'tones': s['tones'],
                    'topics': s['topics'],
                    'languageRegisters': s['languageRegisters'],
                },
                'verdict': self._verdict(s),
            })
        return out

    def _verdict(self, show: dict) -> str:
        if show['listeners'] >= 2000 and show['concentration'] < 0.35:
            return 'Broad-appeal anchor show. Protect this slot.'
        if show['listeners'] >= 1000 and show['concentration'] < 0.5:
            return 'Healthy show. Consider extending duration.'
        if show['concentration'] > 0.55:
            return 'Niche audience. Either embrace the niche or broaden topics.'
        if show['listeners'] < 300:
            return 'Underperforming. Compare with your top show for content gaps.'
        return 'Middle-tier show.'

    # ---------------- AUDIMAT / REVENUE / SCHEDULING ----------------

    def _audimat_insights(self, hourly: Dict[int, float]) -> dict:
        peak = sorted(hourly.items(), key=lambda x: x[1], reverse=True)[:3]
        low = [(h, v) for h, v in hourly.items() if v < 200 and 6 <= h <= 23][:4]
        return {
            'peak_hours': [{
                'hour': f'{h:02d}:00',
                'avg_listeners': int(v),
                'recommendation': f'Your audience peaks here ({int(v)} avg). '
                                  f'Schedule your strongest shows in this window.',
            } for h, v in peak],
            'declining_slots': [{
                'hour': f'{h:02d}:00',
                'avg_listeners': int(v),
                'recommendation': f'Only {int(v)} avg listeners. Consider shifting format or host.',
            } for h, v in low],
        }

    def _suggest_moves(self, show_perf: List[dict]) -> List[dict]:
        if len(show_perf) < 2:
            return []
        top, worst = show_perf[0], show_perf[-1]
        if top['listeners'] - worst['listeners'] < 500:
            return []
        return [{
            'current': f"{worst['show']} — current slot",
            'suggested': 'Move to the peak audience window (see audimat insights)',
            'reason': f"Gap of {top['listeners'] - worst['listeners']} listeners between top and bottom.",
        }]

    def _compute_revenue(self, transactions: List[dict], announcements: List[dict]) -> dict:
        ann = [t for t in transactions if t.get('type') == 'announcement' and t.get('status') == 'released']
        sub = [t for t in transactions if t.get('type') == 'subscription']
        return {
            'announcement_revenue': round(sum(t.get('baseAmount', 0) for t in ann), 2),
            'subscription_spend': round(sum(t.get('totalAmount', 0) for t in sub), 2),
            'projected_monthly': round(
                (sum(t.get('totalAmount', 0) for t in sub) * 2.5) +
                (sum(t.get('baseAmount', 0) for t in ann) * 2.0), 2),
            'recommended_categories': self._category_demand(announcements),
        }

    def _category_demand(self, announcements: List[dict]) -> List[dict]:
        counts: Dict[str, int] = defaultdict(int)
        for a in announcements:
            counts[a.get('category', 'other')] += 1
        return [
            {'category': c, 'requests': n, 'reason': f'{n} requests in period'}
            for c, n in sorted(counts.items(), key=lambda x: x[1], reverse=True)[:3]
        ]

    def _scheduling_insights(self, hourly: Dict[int, float], sessions: List[dict]) -> dict:
        scheduled_hours = {s['startTime'].hour for s in sessions if hasattr(s.get('startTime'), 'hour')}
        recommended = [{
            'day': 'Any', 'hour': f'{h:02d}:00',
            'reason': f'High demand ({int(hourly[h])} avg listeners) but no show scheduled.',
        } for h in range(6, 23) if hourly.get(h, 0) > 800 and h not in scheduled_hours][:5]
        avoid = [{
            'day': 'Any', 'hour': f'{h:02d}:00',
            'reason': f'Low engagement ({int(hourly.get(h, 0))} avg listeners).',
        } for h in range(6, 23) if hourly.get(h, 0) < 200][:5]
        return {'recommended_slots': recommended, 'avoid_slots': avoid}
