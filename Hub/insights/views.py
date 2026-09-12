from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import permissions, status
from .engine import RadioInsightsEngine

try:
    from firebase_admin_config import get_firestore_db
    _db = get_firestore_db()
except Exception:
    _db = None


class RadioInsightsView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        radio_id = request.data.get('radioId')
        time_range = request.data.get('timeRange', 'last_30_days')
        categories = request.data.get('includeCategories', [
            'audimat', 'shows', 'revenue', 'scheduling', 'comparisons', 'diagnostics',
        ])

        if not radio_id:
            return Response({'error': 'radioId is required'}, status=status.HTTP_400_BAD_REQUEST)

        import os
        llm = None
        if os.environ.get('OPENAI_API_KEY'):
            try:
                from .llm import LLMClient
                llm = LLMClient()
            except Exception:
                llm = None

        engine = RadioInsightsEngine(_db, llm=llm)
        insights = engine.generate(radio_id, time_range)

        filtered = {k: v for k, v in insights.items() if k in categories or k == 'meta'}
        return Response(filtered, status=status.HTTP_200_OK)
