# renovate-config

InterWorks's default Renovate config. Extend via `"extends": ["github>InterWorks/renovate-config"]` in your repo's `renovate.json`.

Sets a 7-day cooldown on new releases (supply-chain hardening) and applies Renovate's `config:best-practices` preset.

## Options

| Option | Value | Purpose |
|---|---|---|
| `minimumReleaseAge` | `7 days` | Supply-chain cooldown on all package types. |
| `npmrc` / `npmrcMerge` | `allow-remote=all` + `min-release-age=7` / `true` | Workaround for an npm 12 bug, and the 7-day cooldown for packages npm resolves itself (see below). |

### npm `min-release-age=7`

Renovate's `minimumReleaseAge` only applies to the dependency an update is for. Whenever npm resolves `package-lock.json` (lock file maintenance in particular, which re-resolves every transitive dependency), it picks the newest version in range, however new. `min-release-age=7` (npm 11.10+, in days) makes npm itself skip versions published less than 7 days ago, so lock file maintenance and transitive updates follow the same cooldown. Like the rest of `npmrc`, it applies during Renovate's lockfile updates only, not to CI or local installs.

**Trade-off:** an update whose package is old enough but needs a transitive release that isn't fails its lockfile update ("artifact update problem") until that release is 7 days old, instead of pulling it in.

**Different threshold for one repo:** set `npmrc` in the repo's `renovate.json`. It replaces this preset's value whole, so repeat `allow-remote=all` while that workaround is needed, and keep `minimumReleaseAge` in step:

```json
"minimumReleaseAge": "14 days",
"npmrc": "allow-remote=all\nmin-release-age=14"
```

A repo's own `.npmrc` is not a reliable override: `npmrcMerge` combines it with this value, and which one wins for the same key isn't defined.

### npm `allow-remote=all` workaround

Our self-hosted Renovate runs npm 12, which changed the `allow-remote` default to `none`. A bug ([npm/cli#9800](https://github.com/npm/cli/issues/9800), fix proposed in [npm/cli#9818](https://github.com/npm/cli/pull/9818)) causes npm to classify registry tarballs of packages that declare `bundleDependencies` as "remote" and refuse them. `@tailwindcss/oxide-wasm32-wasi` (Tailwind 4's optional wasm fallback) is one such package, so any repo using Tailwind 4 sees Renovate fail to update `package-lock.json` with `EALLOWREMOTE`.

Setting `allow-remote=all` in `npmrc` and `"npmrcMerge": true` tells npm to allow those fetches during Renovate's lockfile updates only. `npmrcMerge: true` preserves each repo's existing `.npmrc` rather than replacing it. This does **not** affect CI or local installs.

**Trade-off:** during Renovate lockfile updates, npm will also fetch dependencies declared as URL tarballs.

**Remove this workaround** (the `allow-remote=all` line from `npmrc` in `default.json`, and this note; keep `min-release-age` and `npmrcMerge`) once npm/cli#9800 is fixed and ships in the npm version our self-hosted Renovate uses. Track that in [issue #8](https://github.com/InterWorks/renovate-config/issues/8).

Maintainers: see [`.github/CODEOWNERS`](.github/CODEOWNERS).
