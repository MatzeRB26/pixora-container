#!/usr/bin/env bash
# Runs ON the server. Called by .github/workflows/deploy.yaml via SSH.
# Usage: deploy.sh <git-tag> <public-host> <ghcr-user>
# The GHCR read-only token is read from stdin (never passed as an argument).
set -euo pipefail

TAG="${1:?missing git tag}"
PUBLIC_HOST="${2:?missing public host}"
GHCR_USER="${3:?missing GHCR user}"

APP_DIR="/opt/pixora"
REGISTRY="ghcr.io/matzerb26"
COMPOSE_IMAGE_TAG="1.0.0" # must match the image tags in the approved compose.yaml

cd "$APP_DIR"

echo "==> 1/5 Environment file"
if [ -f .env ]; then
  echo "Existing .env found - keeping it unchanged"
else
  echo "No .env found - creating one with generated secrets"
  umask 077
  cat > .env <<EOF
SECRET_KEY=$(openssl rand -base64 48 | tr -d '\n')
DEBUG=False
ALLOWED_HOSTS=${PUBLIC_HOST},localhost,127.0.0.1
CORS_ALLOWED_ORIGINS=http://${PUBLIC_HOST}:4200
MAX_IMAGE_SIZE_MB=5
DB_NAME=pixora
DB_USER=pixora
DB_PASSWORD=$(openssl rand -hex 24)
PIX_FRONTEND_PORT=4200
PIX_BACKEND_PORT=8001
EOF
fi

echo "==> 2/5 Log in to GHCR (read-only token)"
trap 'docker logout ghcr.io >/dev/null 2>&1 || true' EXIT
docker login ghcr.io --username "$GHCR_USER" --password-stdin

echo "==> 3/5 Pull images for ${TAG}"
for SERVICE in backend frontend; do
  docker pull "${REGISTRY}/pixora-${SERVICE}:${TAG}"
  docker tag "${REGISTRY}/pixora-${SERVICE}:${TAG}" "pixora-${SERVICE}:${COMPOSE_IMAGE_TAG}"
done

echo "==> 4/5 Start or update the stack"
docker compose up -d --no-build --wait --wait-timeout 180

echo "==> 5/5 Health check"
curl -fsS "http://127.0.0.1:8001/api/health/"
echo
echo "$TAG" > DEPLOYED_TAG
echo "Deployed ${TAG} successfully"
