# syntax=docker/dockerfile:1

# Stage 1: build the static site
FROM node:25-alpine AS build
RUN corepack enable
WORKDIR /app

# Wildcards keep optional files from breaking the COPY
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml* .npmrc* ./
RUN --mount=type=cache,id=pnpm,target=/root/.local/share/pnpm/store \
    pnpm install --frozen-lockfile

COPY . .

# PUBLIC_* values are baked into the static output at build time
ARG PUBLIC_SITE_URL=""
ARG PUBLIC_UMAMI_SCRIPT_URL=""
ARG PUBLIC_UMAMI_WEBSITE_ID=""
ENV PUBLIC_SITE_URL=$PUBLIC_SITE_URL \
    PUBLIC_UMAMI_SCRIPT_URL=$PUBLIC_UMAMI_SCRIPT_URL \
    PUBLIC_UMAMI_WEBSITE_ID=$PUBLIC_UMAMI_WEBSITE_ID

RUN pnpm build

# Stage 2: serve with unprivileged nginx
FROM nginxinc/nginx-unprivileged:1.29-alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/dist /usr/share/nginx/html

EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -qO- http://127.0.0.1:8080/health >/dev/null || exit 1
