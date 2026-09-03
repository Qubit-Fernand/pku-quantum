# Introduction to Quantum Computing

![pku-quantum.tech homepage](./public/readme-preview.png)

This repository hosts the Next.js + Notion mirror for the Peking University
Introduction to Quantum Computing course site.

## Branch Mapping

The `main` branch is connected to the shared Notion page for the live course
site. Changes made in that shared Notion interface are ultimately rendered as
the course homepage at <https://pku-quantum.tech>.

Branches named `20xx` are connected to private Notion pages and are used to
archive historical course records.

Archive deployments:

- [Quantum Computing 2025](https://pku-quantum-2025.vercel.app/)
- [Quantum Computing 2024](https://pku-quantum-2024.vercel.app/)
- [Quantum Computing 2023](https://pku-quantum-2023.vercel.app/)
- [Quantum Computing 2022](https://pku-quantum-2022.vercel.app/)

## Vercel Deployment Model

This repository is connected to multiple Vercel projects. Each Vercel project
uses the same GitHub repository, but has a different production branch:

| Vercel project | Production branch | Role |
| --- | --- | --- |
| `pku-quantum` | `main` | Live course homepage |
| `pku-quantum-2022` | `2022` | 2022 course archive |
| `pku-quantum-2023` | `2023` | 2023 course archive |
| `pku-quantum-2024` | `2024` | 2024 course archive |
| `pku-quantum-2025` | `2025` | 2025 course archive |

Pushing to GitHub notifies all linked Vercel projects. The project whose
production branch matches the pushed branch runs the production deployment. The
other projects receive preview deployment events and skip them through this
Ignored Build Step:

```bash
if [ "$VERCEL_ENV" == "production" ]; then exit 1; else exit 0; fi
```

As a result, `Canceled by Ignored Build Step` is expected for those cross-project
preview deployments.

The `2026` branch exists in Git, but there is currently no `pku-quantum-2026`
Vercel project configured.

When this README should stay fully synchronized across branches, edit it on
`main` first and copy it to archive branches:

```bash
for branch in 2022 2023 2024 2025 2026; do
  git switch "$branch"
  git checkout main -- readme.md public/readme-preview.png
  git commit -m "docs: sync readme"
done
```

## Upstream

Forked from
[transitive-bullshit/nextjs-notion-starter-kit](https://github.com/transitive-bullshit/nextjs-notion-starter-kit).
For the original starter-kit documentation, see the
[upstream README](https://github.com/transitive-bullshit/nextjs-notion-starter-kit/blob/main/readme.md).
