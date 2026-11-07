# Contributing

Thanks for helping improve this template.

## Setup

```bash
cp .env.example .env
pnpm install
pnpm dev
```

Requires Node 24 and pnpm (see `packageManager` in `package.json`).

## Workflow

1. Fork the repo and create a branch from `main`.
2. Make your change; keep it small and focused.
3. Run `pnpm lint && pnpm check && pnpm build` (these are the CI gate; there are no tests by design).
4. Open a PR against `main`. PRs are squash-merged.

## Commits

Use [Conventional Commits](https://www.conventionalcommits.org/), e.g. `feat: add tag pages` or `fix: correct RSS date`.

## Scope

This template stays minimal: static Astro, no backend, no database. Proposals that add runtime services or heavy dependencies will likely be declined; open an issue first.

## Reporting issues

Use the issue templates. For vulnerabilities, see [SECURITY.md](SECURITY.md).
