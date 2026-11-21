# ---------- Build-Stage: Abhängigkeiten installieren ----------
FROM python:3.12-slim-bookworm AS build

ENV PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt


# ---------- Runtime-Stage: nur was zum Ausführen nötig ist ----------
FROM python:3.12-slim-bookworm AS runtime

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/opt/venv/bin:$PATH"

# Benutzer ohne Root-Rechte
RUN groupadd --system pixora && useradd --system --gid pixora --no-create-home pixora

WORKDIR /app

# Fertige venv aus der Build-Stage übernehmen
COPY --from=build /opt/venv /opt/venv
COPY --chown=pixora:pixora . .

RUN mkdir -p /app/staticfiles /app/media \
    && chown -R pixora:pixora /app/staticfiles /app/media

USER pixora

EXPOSE 8000

# Beim Start: Migrationen, Static Files sammeln, dann gunicorn
CMD ["sh", "-c", "python manage.py migrate --noinput && python manage.py collectstatic --noinput && exec gunicorn pixora.wsgi:application --bind 0.0.0.0:8000 --workers 3"]
