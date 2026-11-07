# static-site-template

[![CI](https://github.com/morvenlabs/static-site-template/actions/workflows/ci.yml/badge.svg)](https://github.com/morvenlabs/static-site-template/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Node](https://img.shields.io/badge/node-%3E%3D24-339933)](package.json)

Minimal Astro static site (starter for any static site) served by nginx, built in Docker, deployed to Dokploy via GitHub Actions.

## Stack

Astro 7 (static output), Tailwind v4, sitemap, Biome, pnpm, Node 24, nginx (unprivileged), optional Umami analytics.

## Quick start

```bash
cp .env.example .env
pnpm install
pnpm dev        # http://localhost:4321
```

| Command             | Purpose               |
| ------------------- | --------------------- |
| `pnpm build`        | Build to `dist/`      |
| `pnpm preview`      | Serve `dist/` locally |
| `pnpm check`        | `astro check` (types) |
| `pnpm lint`         | `biome ci .`          |
| `pnpm format`       | Biome auto-fix        |
| `pnpm compose`      | Docker build + run    |
| `pnpm compose:down` | Stop the container    |

## Project structure

```
src/pages/            routes (index, about, projects, 404)
src/components/       Header, Footer, BaseHead, Umami
src/layouts/          BaseLayout
src/styles/           global.css (Tailwind)
public/               favicon (robots.txt is generated: src/pages/robots.txt.ts)
Dockerfile nginx.conf docker-compose.yml
.github/workflows/    ci.yml, deploy.yml
```

## Add a blog later

`pnpm add @astrojs/mdx @astrojs/rss`, add `mdx()` to `integrations` in `astro.config.mjs`, define a `blog` collection in `src/content.config.ts`, then add `src/pages/blog/` and `src/pages/rss.xml.ts`.

## Customize checklist

- [ ] Rename the project in `package.json` (and the repo)
- [ ] Set `PUBLIC_SITE_URL` (canonical URLs, sitemap)
- [ ] Replace the Umami placeholder host in the `nginx.conf` CSP (or remove it if unused)
- [ ] Replace `public/favicon.svg`
- [ ] Replace sample pages with your content

## Docker (local production preview)

```bash
pnpm compose        # build + start in background, http://localhost:8080 (override with WEB_HOST_PORT)
pnpm compose:down   # stop and remove
```

Build args are read from `.env`. Health endpoint: `/health`.

## Deploy with Dokploy

1. In Docker Hub, create an access token (read/write).
2. In Dokploy, create an **Application** and choose the **Docker** provider.
3. Image: `<namespace>/<repo>:latest`, plus registry credentials if the repo is private.
4. Port `8080`; add your domain and enable HTTPS.
5. Health check path: `/health`.
6. Copy the application's **Deploy webhook URL**: the base URL is `DOKPLOY_URL`, the last path segment (after `/api/deploy/`) is `DOKPLOY_DEPLOY_WEBHOOK`.
7. In GitHub, add the secrets and variables below, then set `ENABLE_DEPLOY=true`.

| Name                      | Type     | Value                                                |
| ------------------------- | -------- | ---------------------------------------------------- |
| `DOCKERHUB_USERNAME`      | secret   | Docker Hub user (also the image namespace)           |
| `DOCKERHUB_TOKEN`         | secret   | Docker Hub access token                              |
| `DOKPLOY_URL`             | secret   | Dokploy base URL, e.g. `https://dokploy.example.com` |
| `DOKPLOY_DEPLOY_WEBHOOK`  | secret   | Webhook token from step 6                            |
| `IMAGE_NAMESPACE`         | variable | Docker Hub org (optional, defaults to the username)  |
| `ENABLE_DEPLOY`           | variable | `true` to enable `deploy.yml`                        |
| `PUBLIC_SITE_URL`         | variable | Public site URL (also used by the smoke check)       |
| `PUBLIC_UMAMI_SCRIPT_URL` | variable | Umami script URL (optional)                          |
| `PUBLIC_UMAMI_WEBSITE_ID` | variable | Umami website ID (optional)                          |
| `CLOUDFLARE_ZONE_ID`      | secret   | Zone ID for cache purge after deploy (optional)      |
| `CLOUDFLARE_API_TOKEN`    | secret   | Token with "Cache Purge" permission (optional)       |

`PUBLIC_*` are variables, not secrets: they end up in the shipped HTML.

## CI/CD

- `ci.yml` (PRs, push to `main`): install, lint, check, build, then a Docker build without push.
- `deploy.yml` (push to `main`, gated by `ENABLE_DEPLOY`): build and push `:latest` and `:<sha>` to Docker Hub, trigger the Dokploy webhook, then poll `/health` for up to 3 minutes.

## Umami

Set `PUBLIC_UMAMI_SCRIPT_URL` (e.g. `https://umami.example.com/script.js`) and `PUBLIC_UMAMI_WEBSITE_ID`. The script is only rendered when both are set. Update the CSP host in `nginx.conf` to match, otherwise the browser blocks it.

## Cloudflare (CDN)

The site is fully static, so Cloudflare can cache nearly everything at the edge. Dokploy/nginx stays the origin.

### 1. Prerequisites

- **DNS → Records:** `@` and `www` pointing to the Dokploy server, **Proxied** (orange cloud). Gray cloud = no CDN, no rules, no WAF.
- **SSL/TLS → Overview:** mode **Full (strict)**. Dokploy's Let's Encrypt certificate satisfies it.
- **SSL/TLS → Edge Certificates:** enable **Always Use HTTPS**.
- **Speed → Optimization:** keep **Rocket Loader** and **Auto Minify** off (they rewrite scripts and clash with the CSP). Brotli on.
- **Scrape Shield:** turn **Email Address Obfuscation** off (it injects an inline script blocked by the CSP).
- **Web Analytics:** Umami replaces it. Disable Cloudflare's automatic beacon, otherwise add `https://static.cloudflareinsights.com` to `script-src` and `https://cloudflareinsights.com` to `connect-src` in `nginx.conf`.

### 2. Redirect Rule (www → apex)

**Rules → Redirect Rules → Create rule**, place it **First**.

- Name: `Redirect from WWW to Root`
- Match: wildcard pattern, request URL `https://www.*`
- Target URL: `https://${1}`, status `301`, preserve query string ✅

### 3. Cache Rules

**Caching → Cache Rules**, create in this order. nginx already sends the right `Cache-Control` (`/_astro/*` immutable 1 year, HTML `no-cache`, rest 1 hour).

| #   | Name                       | Expression                                                                                      | Settings                                                                                           |
| --- | -------------------------- | ----------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------- |
| 1   | `01 - Cache hashed assets` | `starts_with(http.request.uri.path, "/_astro/")`                                                | Eligible for cache · Edge TTL: use cache-control header · Browser TTL: respect origin              |
| 2   | `02 - Cache HTML`          | `not starts_with(http.request.uri.path, "/_astro/") and not http.request.uri.path eq "/health"` | Eligible for cache · Edge TTL: ignore origin, **1 day** · Browser TTL: respect origin (`no-cache`) |

Rule 2 caches pages at the edge (Cloudflare does not cache HTML by default). It is safe because every deploy purges the cache (next section) and the origin has no per-user content.

### 4. Purge after deploy

`deploy.yml` purges the whole zone when both `CLOUDFLARE_ZONE_ID` and `CLOUDFLARE_API_TOKEN` are set; otherwise the step is skipped.

- `CLOUDFLARE_ZONE_ID`: Dashboard → domain **Overview** → right sidebar → **API**.
- `CLOUDFLARE_API_TOKEN`: **My Profile → API Tokens → Create Token** → template _Edit zone cache purge_, scoped to your zone.
- The purge runs after the `/health` smoke check. That check also passes on the old container, so if a page looks stale right after a deploy, purge manually: **Caching → Configuration → Purge Cache → Custom Purge → Hostname**.

### 5. Updating the CSP

After changing Cloudflare features (Turnstile, Web Analytics, etc.), update the CSP in `nginx.conf` and purge the cache so the new headers reach visitors.

## Workflow

Single branch: `main`. Open PRs against `main`; merging deploys.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) and the [Code of Conduct](CODE_OF_CONDUCT.md).

## License

MIT
