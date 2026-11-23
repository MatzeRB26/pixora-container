# ---------- Build stage: install dependencies ----------
FROM python:3.12-slim-bookworm AS build

ENV PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt


# ---------- Runtime stage: only what is needed to run ----------
FROM python:3.12-slim-bookworm AS runtime

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/opt/venv/bin:$PATH"

# Non-root user
RUN groupadd --system pixora && useradd --system --gid pixora --create-home pixora

WORKDIR /app

# Copy the prepared venv from the build stage
COPY --from=build /opt/venv /opt/venv
COPY --chown=pixora:pixora . .

RUN mkdir -p /app/staticfiles /app/media \
    && chown -R pixora:pixora /app/staticfiles /app/media

USER pixora

EXPOSE 8000

ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["gunicorn", "pixora.wsgi:application", "--bind", "0.0.0.0:8000", "--workers", "3"]
