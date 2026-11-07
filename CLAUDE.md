# static-site-template

Astro static site (starter for any static site), served by nginx in Docker, deployed to Dokploy.

## Layout

- `src/pages`, `src/layouts`, `src/components`, `src/styles`: site code
- `public/`: static files; `dist/`: build output (gitignored)
- `Dockerfile`, `nginx.conf`, `docker-compose.yml`: production image and local preview
- `.github/workflows`: `ci.yml` (lint, check, build, docker build), `deploy.yml` (push image + Dokploy webhook)

## Commands

`pnpm dev` | `pnpm build` | `pnpm check` (astro check) | `pnpm lint` (biome ci) | `pnpm format`

## Rules

- Single branch: `main`. No dev/test branches, no semantic-release.
- No tests by design; `lint`, `check` and `build` are the gate.
- `PUBLIC_*` env vars are build-time and baked into the output; changing them needs a rebuild.
- No backend, no database, no runtime secrets.
- Biome is the formatter/linter; follow `biome.json`.
- Edit the Umami host in the `nginx.conf` CSP when analytics is enabled.
- Do not run git commands unless asked.
- Cloudflare proxies the site; setup and cache rules are in README.md. CI purges the cache after deploy when the Cloudflare secrets exist.
