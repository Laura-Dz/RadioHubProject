import os
import logging
from datetime import datetime, timedelta
from collections import defaultdict
from statistics import mean

from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import permissions, status
from .llm import LLMClient

logger = logging.getLogger(__name__)

try:
    from firebase_admin_config import get_firestore_db
    _db = get_firestore_db()
except Exception:
    _db = None

try:
    from google.cloud.firestore_v1.base_query import FieldFilter
except Exception:
    FieldFilter = None


def _filter_query(query, field, op, value):
    if FieldFilter is not None:
        return query.where(filter=FieldFilter(field, op, value))
    return query.where(field, op, value)


def _check_plan_eligibility(db, radio_id: str) -> tuple[bool, str]:
    """
    Check if the radio has an active subscription plan that includes AI Insights.
    Returns (is_eligible, plan_name).
    """
    if not db:
        return True, "Development"

    try:
        now = datetime.utcnow()
        query = db.collection('subscriptions')
        query = _filter_query(query, 'radioId', '==', radio_id)
        query = _filter_query(query, 'status', '==', 'active')
        subs = list(query.stream())

        for s in subs:
            data = s.to_dict()
            end_date = data.get('endDate')
            if end_date:
                if hasattr(end_date, 'replace') and end_date.tzinfo is not None:
                    end_dt = end_date.replace(tzinfo=None)
                elif hasattr(end_date, 'to_datetime'):
                    end_dt = end_date.to_datetime().replace(tzinfo=None)
                elif isinstance(end_date, datetime):
                    end_dt = end_date.replace(tzinfo=None)
                else:
                    end_dt = now + timedelta(days=30)
                
                if end_dt < now:
                    continue  # Expired

            plan_name = str(data.get('planName') or data.get('label') or '').lower()
            features = [str(f).lower() for f in (data.get('features') or [])]

            # Eligible if features explicitly mention AI or plan is Quarterly/Yearly/Enterprise/Pro
            has_ai_feature = any('ai' in f or 'insight' in f for f in features)
            is_premium_tier = any(tier in plan_name for tier in ['quarterly', 'yearly', 'annual', 'enterprise', 'pro'])

            if has_ai_feature or is_premium_tier:
                return True, data.get('planName', 'Premium')
            else:
                return False, data.get('planName', 'Monthly')

        # Also check radio document directly
        r_doc = db.collection('radios').document(radio_id).get()
        if r_doc.exists:
            r_data = r_doc.to_dict()
            tier = str(r_data.get('subscriptionTier') or r_data.get('planName') or '').lower()
            if any(t in tier for t in ['quarterly', 'yearly', 'enterprise', 'pro']):
                return True, tier.capitalize()

        return False, "Basic / Inactive"
    except Exception as e:
        logger.warning("Error checking subscription eligibility for %s: %s", radio_id, e)
        return True, "Unknown"


def _parse_iso_datetime(val) -> datetime | None:
    if not val:
        return None
    if isinstance(val, datetime):
        return val.replace(tzinfo=None) if val.tzinfo else val
    if hasattr(val, 'to_datetime'):
        dt = val.to_datetime()
        return dt.replace(tzinfo=None) if dt.tzinfo else dt
    if isinstance(val, str):
        try:
            dt = datetime.fromisoformat(val.replace('Z', '+00:00'))
            return dt.replace(tzinfo=None) if dt.tzinfo else dt
        except Exception:
            try:
                return datetime.strptime(val[:10], '%Y-%m-%d')
            except Exception:
                return None
    return None


def _collect_segmented_data(db, radio_id: str, start_dt: datetime, end_dt: datetime) -> dict:
    """
    Collects real broadcast, listener, and business data from Firestore
    strictly for the given radioId within [start_dt, end_dt], segmented by datatype.
    """
    if not db:
        return {}

    segmented = {
        'station_profile': {},
        'audimat_and_sessions': {},
        'show_performance': [],
        'revenue_and_transactions': {},
        'announcements': {},
    }

    try:
        # 1. Station Profile
        r_doc = db.collection('radios').document(radio_id).get()
        if r_doc.exists:
            rd = r_doc.to_dict()
            segmented['station_profile'] = {
                'id': radio_id,
                'name': rd.get('name', 'Radio Station'),
                'description': rd.get('description', ''),
                'category': rd.get('category', 'General'),
                'tags': rd.get('tags', []),
                'language': rd.get('language', 'French/English'),
            }

        # 2. Audimat & Listener Activity Logs
        activity_query = list(
            _filter_query(db.collection('listener_activity'), 'radioId', '==', radio_id).stream()
        )
        if not activity_query:
            activity_query = list(
                db.collection('radios')
                .document(radio_id)
                .collection('activity_logs')
                .stream()
            )

        all_activities = []
        for a in activity_query:
            ad = a.to_dict()
            ts = ad.get('timestamp') or ad.get('clientTime') or ad.get('createdAt')
            a_dt = _parse_iso_datetime(ts) or datetime.utcnow()

            if start_dt <= a_dt <= end_dt:
                all_activities.append({**ad, '_dt': a_dt})

        # Calculate Audimat metrics from play/pause activity logs
        play_events = [a for a in all_activities if (a.get('action') or 'play') == 'play']
        pause_events = [a for a in all_activities if a.get('action') in ('pause', 'stop')]
        unique_listener_ids = set(str(a.get('userId')) for a in all_activities if a.get('userId'))

        durations = [int(a.get('durationSeconds') or 0) for a in pause_events if a.get('durationSeconds')]
        avg_listening_duration_mins = round(mean(durations) / 60.0, 1) if durations else 0.0
        total_listening_hours = round(sum(durations) / 3600.0, 1) if durations else 0.0

        activity_hourly_plays = defaultdict(int)
        for a in play_events:
            h = a['_dt'].hour
            activity_hourly_plays[h] += 1

        # Sessions for this radio
        sessions_query = list(
            _filter_query(db.collection('sessions'), 'radioId', '==', radio_id).stream()
        )

        all_sessions = []
        for s in sessions_query:
            sd = s.to_dict()
            start_time = sd.get('actualStart') or sd.get('scheduledStart') or sd.get('startTime') or sd.get('createdAt')
            session_start_dt = _parse_iso_datetime(start_time) or datetime.utcnow()

            if start_dt <= session_start_dt <= end_dt:
                all_sessions.append({**sd, '_dt': session_start_dt})

        total_listeners = len(unique_listener_ids) if unique_listener_ids else sum(int(s.get('listenerCount') or s.get('listeners') or 0) for s in all_sessions)
        peak_listeners = max(activity_hourly_plays.values()) if activity_hourly_plays else max([int(s.get('listenerCount') or s.get('listeners') or 0) for s in all_sessions] or [0])
        avg_completion = mean([float(s.get('completionRate') or s.get('retention') or 0.0) for s in all_sessions]) if all_sessions else 0.0

        hourly_listeners = defaultdict(list)
        for s in all_sessions:
            h = s['_dt'].hour
            count = int(s.get('listenerCount') or s.get('listeners') or 0)
            hourly_listeners[h].append(count)

        hourly_dist = {f"{h:02d}:00": count for h, count in sorted(activity_hourly_plays.items())} if activity_hourly_plays else {f"{h:02d}:00": int(mean(counts)) for h, counts in sorted(hourly_listeners.items())}

        segmented['audimat_and_sessions'] = {
            'total_sessions_in_period': len(all_sessions),
            'unique_listeners': total_listeners,
            'total_tune_ins_plays': len(play_events),
            'total_pauses_drop_offs': len(pause_events),
            'average_listening_duration_minutes': avg_listening_duration_mins,
            'total_listening_hours': total_listening_hours,
            'peak_listeners': peak_listeners,
            'average_retention_rate': round(avg_completion, 2),
            'hourly_distribution': hourly_dist,
        }

        # 3. Show Performance
        shows_map = defaultdict(list)
        for s in all_sessions:
            show_name = s.get('programName') or s.get('title') or 'General Show'
            shows_map[show_name].append(s)

        show_perf = []
        for show_name, s_list in shows_map.items():
            listeners = [int(i.get('listenerCount') or i.get('listeners') or 0) for i in s_list]
            retentions = [float(i.get('completionRate') or i.get('retention') or 0.0) for i in s_list]
            show_perf.append({
                'show_name': show_name,
                'sessions_count': len(s_list),
                'avg_listeners': int(mean(listeners)) if listeners else 0,
                'peak_listeners': max(listeners) if listeners else 0,
                'avg_retention': round(mean(retentions), 2) if retentions else 0.0,
                'category': s_list[0].get('programCategory') or (s_list[0].get('theme') or {}).get('category') or 'Music',
                'host': s_list[0].get('hostName') or 'Station Host',
            })
        show_perf.sort(key=lambda x: x['avg_listeners'], reverse=True)
        segmented['show_performance'] = show_perf[:10]

        # 4. Revenue & Transactions
        tx_query = list(
            _filter_query(db.collection('transactions'), 'radioId', '==', radio_id).stream()
        )
        tx_list = []
        for t in tx_query:
            td = t.to_dict()
            tts = td.get('createdAt') or td.get('timestamp') or td.get('date')
            t_dt = _parse_iso_datetime(tts)
            if t_dt is None or (start_dt <= t_dt <= end_dt):
                tx_list.append(td)

        announcement_revenue = sum(float(t.get('baseAmount') or 0.0) for t in tx_list if t.get('type') == 'announcement')
        subscription_spend = sum(float(t.get('totalAmount') or 0.0) for t in tx_list if t.get('type') == 'subscription')

        segmented['revenue_and_transactions'] = {
            'total_transactions': len(tx_list),
            'announcement_revenue_xaf': announcement_revenue,
            'subscription_spend_xaf': subscription_spend,
            'net_balance_xaf': announcement_revenue - subscription_spend,
        }

        # 5. Announcements
        ann_query = list(
            _filter_query(db.collection('announcements'), 'radioId', '==', radio_id).stream()
        )
        ann_list = []
        for a in ann_query:
            ad = a.to_dict()
            ats = ad.get('createdAt') or ad.get('scheduledFor') or ad.get('date')
            a_dt = _parse_iso_datetime(ats)
            if a_dt is None or (start_dt <= a_dt <= end_dt):
                ann_list.append(ad)

        categories_count = defaultdict(int)
        for a in ann_list:
            categories_count[a.get('category', 'general')] += 1

        segmented['announcements'] = {
            'total_announcements_requested': len(ann_list),
            'categories_demand': dict(categories_count),
        }

    except Exception as e:
        logger.exception("Error collecting segmented data for radio %s: %s", radio_id, e)

    return segmented


class RadioInsightsView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        radio_id = request.data.get('radioId')
        start_date_raw = request.data.get('startDate')
        end_date_raw = request.data.get('endDate')
        time_range = request.data.get('timeRange')

        if not radio_id:
            return Response(
                {'error': 'radioId is required', 'eligible': False},
                status=status.HTTP_400_BAD_REQUEST,
            )

        now = datetime.utcnow()
        if start_date_raw or end_date_raw:
            start_dt = _parse_iso_datetime(start_date_raw)
            end_dt = _parse_iso_datetime(end_date_raw)
            if not start_dt:
                return Response(
                    {'error': 'Invalid startDate format. Use YYYY-MM-DD or ISO 8601.', 'eligible': False},
                    status=status.HTTP_400_BAD_REQUEST,
                )
            if not end_dt:
                end_dt = now

            if start_dt > end_dt:
                return Response(
                    {'error': 'startDate must be before or equal to endDate.', 'eligible': False},
                    status=status.HTTP_400_BAD_REQUEST,
                )

            # Strict 5-year maximum interval constraint (1,826 days)
            delta_days = (end_dt - start_dt).days
            if delta_days > 1826:
                return Response(
                    {
                        'error': f'The selected date interval ({delta_days} days) exceeds the 5-year maximum limit (1,826 days).',
                        'eligible': False,
                        'interval_days': delta_days,
                        'max_allowed_days': 1826,
                    },
                    status=status.HTTP_400_BAD_REQUEST,
                )

            resolved_range = f"{start_dt.strftime('%Y-%m-%d')} to {end_dt.strftime('%Y-%m-%d')}"
        else:
            time_range = time_range or 'last_30_days'
            days = {'today': 1, 'last_7_days': 7, 'last_30_days': 30, 'last_90_days': 90}.get(time_range, 30)
            end_dt = now
            start_dt = end_dt - timedelta(days=days)
            resolved_range = time_range

        # 1. Check Plan Eligibility
        is_eligible, plan_name = _check_plan_eligibility(_db, radio_id)
        if not is_eligible:
            return Response({
                'eligible': False,
                'error': 'not_eligible',
                'plan_name': plan_name,
                'message': f'Your current subscription plan ({plan_name}) is not eligible for AI Strategic Insights. Please upgrade to a Quarterly or Yearly plan to unlock Gemini-powered intelligence.',
            }, status=status.HTTP_200_OK)

        # 2. Collect Data Segmented by Datatype strictly for this Radio within [start_dt, end_dt]
        segmented_data = _collect_segmented_data(_db, radio_id, start_dt, end_dt)

        # 3. Direct Gemini API call
        llm = LLMClient()
        if not llm.api_key:
            return Response({
                'eligible': True,
                'error': 'gemini_not_configured',
                'message': 'Gemini API is not configured on the server.',
            }, status=status.HTTP_200_OK)

        report = llm.generate_strategic_report(segmented_data)

        # 4. Construct Final Response
        report['eligible'] = True
        report['radioId'] = radio_id
        report['timeRange'] = resolved_range
        report['startDate'] = start_dt.isoformat()
        report['endDate'] = end_dt.isoformat()
        report['meta'] = {
            'generated_at': datetime.utcnow().isoformat(),
            'model': getattr(llm, 'active_model', 'gemini-3.6-flash'),
            'time_range': resolved_range,
            'start_date': start_dt.isoformat(),
            'end_date': end_dt.isoformat(),
            'radio_id': radio_id,
            'sessions_analyzed': segmented_data.get('audimat_and_sessions', {}).get('total_sessions_in_period', 0),
        }

        # Backwards compatibility for fields expected by UI widgets
        if 'executive_summary' in report and 'ai_summary' not in report:
            report['ai_summary'] = report['executive_summary']

        return Response(report, status=status.HTTP_200_OK)
