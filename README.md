# Pixora – Containerized

A full-stack Instagram-like app (Angular 21 + Django 6 + PostgreSQL), fully containerized with Docker Compose.

## Table of Contents

- [Quickstart](#quickstart)
- [Services](#services)
- [Environment variables](#environment-variables)
- [Usage](#usage)
- [Verify](#verify)
- [Troubleshooting](#troubleshooting)
- [CI/CD and Deployment](#cicd-and-deployment)
- [API Overview](#api-overview)

## Quickstart

Clone the repository:

```bash
git clone git@github.com:MatzeRB26/pixora-container.git
```

```bash
cd pixora-container
```

Create your `.env` from the example and replace the placeholders (`SECRET_KEY`, `DB_PASSWORD`):

```bash
cp example.env .env
```

Build and start all services:

```bash
docker compose up -d --build
```

Load sample data (optional):

```bash
docker compose exec backend python manage.py seed_db
```

Open **http://localhost:4200** and log in with `armin_admin` / `password123` (seed superuser with a publicly known password – local testing only, never run `seed_db` on a server).

## Services

| Service    | Image                                  | Host port | Container port | Purpose                                        |
|------------|----------------------------------------|-----------|----------------|------------------------------------------------|
| `frontend` | built from `frontend/Dockerfile`       | 4200      | 8080           | nginx serves Angular, proxies `/api` and `/admin` |
| `backend`  | built from `backend/Dockerfile`        | 8000 (localhost only)      | 8000 | Django REST API with gunicorn, healthcheck on `/api/health/` |
| `db`       | `postgres:17-alpine`                   | –         | 5432           | PostgreSQL (internal only, no host port)       |

**Networks**
- `frontend`: frontend ↔ backend
- `backend`: backend ↔ db (frontend has no access to the database)

**Volumes**

| Volume   | Mounted at                                          | Content                         |
|----------|-----------------------------------------------------|---------------------------------|
| `pgdata` | `/var/lib/postgresql/data` (db)                     | Database files                  |
| `media`  | `/app/media` (backend), `/var/www/media` (frontend, read-only) | Uploaded images, seed images |
| `static` | `/app/staticfiles` (backend), `/var/www/static` (frontend, read-only) | Django static files (admin) |

## Environment variables

All variables are read from `.env`. `SECRET_KEY` and `DB_PASSWORD` are **required**: without them `docker compose` refuses to start. All other values have safe defaults in `compose.yaml`.

| Variable               | Default                                         | Description                          |
|------------------------|-------------------------------------------------|--------------------------------------|
| `SECRET_KEY`           | **required**                                    | Django secret key (JWT signing)      |
| `DEBUG`                | `False`                                         | Django debug mode                    |
| `ALLOWED_HOSTS`        | `localhost,127.0.0.1`                           | Allowed host names                   |
| `CORS_ALLOWED_ORIGINS` | `http://localhost:4200,http://127.0.0.1:4200`   | Allowed CORS origins                 |
| `MAX_IMAGE_SIZE_MB`    | `5`                                             | Max upload size per image            |
| `DB_NAME`              | `pixora`                                        | PostgreSQL database name             |
| `DB_USER`              | `pixora`                                        | PostgreSQL user                      |
| `DB_PASSWORD`          | **required**                                    | PostgreSQL password                  |
| `PIX_FRONTEND_PORT`    | `4200`                                          | Host port for the frontend           |
| `PIX_BACKEND_PORT`     | `8000`                                          | Host port for the backend            |

The backend connects to PostgreSQL via the service name `db` (`DB_HOST=db`), not `localhost`.

## Usage

Build the images only:

```bash
docker compose build
```

Start:

```bash
docker compose up -d
```

Stop (containers are kept):

```bash
docker compose stop
```

Restart:

```bash
docker compose restart
```

Stop and remove containers (data in volumes is kept):

```bash
docker compose down
```

Remove everything **including all data**:

```bash
docker compose down -v
```

## Verify

All containers should be `healthy`:

```bash
docker compose ps
```

- **Frontend:** open http://localhost:4200
- **Backend via frontend:** log in – this calls `/api/auth/login/` through nginx
- **Django admin:** http://localhost:4200/admin
- **Backend directly:** `curl http://localhost:8000/api/health/` → `{"status":"ok"}` (port 8000 is bound to localhost only)

Check that all migrations ran against PostgreSQL:

```bash
docker compose exec backend python manage.py showmigrations
```

## Troubleshooting

Show the logs of a service:

```bash
docker compose logs -f backend
```

- **`required variable ... is missing a value`:** you have no `.env` yet – run `cp example.env .env` and set `SECRET_KEY` and `DB_PASSWORD`.
- **Backend not starting:** check `DB_PASSWORD` in `.env`. If you changed it after the first start, the old password is still stored in the `pgdata` volume – run `docker compose down -v` (deletes all data) and start again.
- **Port already in use:** change `PIX_FRONTEND_PORT` or `PIX_BACKEND_PORT` in `.env`.
- **Images not loading:** check the frontend logs with `docker compose logs frontend`.

## CI/CD and Deployment

### Workflows

| Workflow | File | Trigger | What it does |
|---|---|---|---|
| Testing | `.github/workflows/testing.yaml` | Pull request to `main`, new commits on the PR, called by the build workflow | Backend: ruff lint + Django tests. Frontend: lint, type check (`tsc --noEmit`), production build |
| Build and Publish | `.github/workflows/build.yaml` | Pull request to `main`, push/merge to `main`, push of a Git tag `v*` or `test-*` | Always runs the tests first. On PRs and `main`: builds both images (no push). On tags: builds and pushes both images to GHCR |
| Deploy | `.github/workflows/deploy.yaml` | Manual only (`workflow_dispatch`), Git tags only | Copies `compose.yaml` and `deploy/deploy.sh` to the VM over SSH, pulls the images for the selected tag, starts the stack and runs health checks |

If the tests fail, no image is built or published (`needs: tests`).

### Image name and tag format

```text
ghcr.io/matzerb26/pixora-backend:<git-tag>
ghcr.io/matzerb26/pixora-frontend:<git-tag>
```

- The image tag is always **exactly the Git tag** (e.g. `v1.0.0-rc`, `test-3`). The Git tag is the release identity.
- The tag is validated in the workflow before it is used (allowed: letters, digits, `.`, `_`, `-`).
- **No `latest` tag** is ever created or published.
- The packages are **private**. Pulling requires a token with `read:packages`.
- Note: The "Latest" badge on the GitHub package page only marks the newest upload. It is **not** a Docker tag.

## API Overview

| Method | Endpoint                          | Description              |
|--------|-----------------------------------|--------------------------|
| POST   | `/api/auth/register/`             | Register a new user      |
| POST   | `/api/auth/login/`                | Obtain JWT tokens        |
| POST   | `/api/auth/refresh/`              | Refresh access token     |
| GET    | `/api/users/me/`                  | Current user profile     |
| GET    | `/api/users/{id}/`                | User profile             |
| POST   | `/api/users/{id}/follow/`         | Follow a user            |
| POST   | `/api/users/{id}/unfollow/`       | Unfollow a user          |
| GET    | `/api/posts/`                     | Feed (followed users)    |
| POST   | `/api/posts/`                     | Create a post            |
| DELETE | `/api/posts/{id}/`                | Delete own post          |
| POST   | `/api/posts/{id}/like/`           | Like a post              |
| POST   | `/api/posts/{id}/unlike/`         | Unlike a post            |
| POST   | `/api/posts/{id}/comments/`       | Add a comment            |
| DELETE | `/api/posts/{id}/comments/{id}/`  | Delete own comment       |
