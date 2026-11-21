# ---------- Build stage: build Angular app ----------
FROM node:22-alpine AS build

RUN npm install -g pnpm@10

WORKDIR /app

# Copy dependency files first (better layer caching)
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
RUN pnpm install --frozen-lockfile

# Copy the source code and create the production build
COPY . .
RUN pnpm run build


# ---------- Runtime stage: nginx serving the built files ----------
FROM nginxinc/nginx-unprivileged:1.27-alpine AS runtime

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/dist/pixora-frontend/browser /usr/share/nginx/html

EXPOSE 8080
