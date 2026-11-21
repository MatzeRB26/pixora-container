# ---------- Build-Stage: Angular bauen ----------
FROM node:22-alpine AS build

RUN npm install -g pnpm@10

WORKDIR /app

# Erst nur die Abhängigkeits-Dateien (besserer Layer-Cache)
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
RUN pnpm install --frozen-lockfile

# Dann den restlichen Code und Production-Build
COPY . .
RUN pnpm run build


# ---------- Runtime-Stage: nur nginx mit den fertigen Dateien ----------
FROM nginxinc/nginx-unprivileged:1.27-alpine AS runtime

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/dist/pixora-frontend/browser /usr/share/nginx/html

EXPOSE 8080
