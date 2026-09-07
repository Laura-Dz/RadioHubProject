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
]
