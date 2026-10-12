# renovate-config

InterWorks's default Renovate config. Extend via `"extends": ["github>InterWorks/renovate-config"]` in your repo's `renovate.json`.

Sets a 7-day cooldown on new releases (supply-chain hardening) and applies Renovate's `config:best-practices` preset.

## Options

| Option | Value | Purpose |
|---|---|---|
| `minimumReleaseAge` | `7 days` | Supply-chain cooldown on all package types. |
| `npmrc` / `npmrcMerge` | `allow-remote=all` / `true` | Workaround for an npm 12 bug (see below). |

### npm `allow-remote=all` workaround

Renovate's hosted runner uses npm 12, which changed the `allow-remote` default to `none`. A bug ([npm/cli#9800](https://github.com/npm/cli/issues/9800), fix proposed in [npm/cli#9818](https://github.com/npm/cli/pull/9818)) causes npm to classify registry tarballs of packages that declare `bundleDependencies` as "remote" and refuse them. `@tailwindcss/oxide-wasm32-wasi` (Tailwind 4's optional wasm fallback) is one such package, so any repo using Tailwind 4 sees Renovate fail to update `package-lock.json` with `EALLOWREMOTE`.

Setting `"npmrc": "allow-remote=all"` and `"npmrcMerge": true` tells npm to allow those fetches during Renovate's lockfile updates only. `npmrcMerge: true` preserves each repo's existing `.npmrc` rather than replacing it. This does **not** affect CI or local installs.

**Trade-off:** during Renovate lockfile updates, npm will also fetch dependencies declared as URL tarballs.

**Remove this workaround** (both keys from `default.json` and this note) once npm/cli#9800 is fixed and ships in the npm version Renovate's hosted runner uses. Track that in [issue #8](https://github.com/InterWorks/renovate-config/issues/8).

Maintainers: see [`.github/CODEOWNERS`](.github/CODEOWNERS).
