from django.urls import path, include
from rest_framework.routers import DefaultRouter
from listener_api import views

router = DefaultRouter()
router.register(r"shows", views.ShowScheduleViewSet, basename="show-schedule")
router.register(r"episodes", views.EpisodeListViewSet, basename="episode-list")

urlpatterns = [
    path("", include(router.urls)),
    path("live-stream/", views.ActiveLiveStreamView.as_view(), name="active-live-stream"),
    path("announcements/", views.ActiveAnnouncementsView.as_view(), name="active-announcements"),
    path("ai/recommendations/radio-insights", views.RadioInsightsView.as_view(), name="radio-insights"),
    path("ai/recommendations/radio-insights/", views.RadioInsightsView.as_view(), name="radio-insights-slash"),
    path("announcement/suggest-text", views.SuggestAnnouncementTextView.as_view(), name="announcement-suggest-text"),
    path("announcement/suggest-text/", views.SuggestAnnouncementTextView.as_view(), name="announcement-suggest-text-slash"),
    path("announcement/calculate-price", views.CalculateAnnouncementPriceView.as_view(), name="announcement-calculate-price"),
    path("announcement/calculate-price/", views.CalculateAnnouncementPriceView.as_view(), name="announcement-calculate-price-slash"),
]


