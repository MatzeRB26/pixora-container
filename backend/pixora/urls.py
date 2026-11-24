from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static

from .views import health

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/health/', health, name='health'),
    path('api/auth/', include('apps.authentication.urls')),
    path('api/users/', include('apps.users.urls', namespace='users')),
    path('api/posts/', include('apps.posts.urls', namespace='posts')),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
