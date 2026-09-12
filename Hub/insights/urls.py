from django.urls import path
from .views import RadioInsightsView

urlpatterns = [
    path('api/ai/recommendations/radio-insights', RadioInsightsView.as_view(), name='radio-insights-engine'),
    path('api/ai/recommendations/radio-insights/', RadioInsightsView.as_view(), name='radio-insights-engine-slash'),
]
