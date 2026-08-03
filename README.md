# mirror-golang

OCX mirror for [Go](https://go.dev). One repository, one spec directory per
package.

| Package | Spec | Publishes to | Announced as | Upstream SPDX |
|---|---|---|---|---|
| [go](https://go.dev) | [`go/mirror.yml`](go/mirror.yml) | `ghcr.io/ocx-contrib/golang/go` | `ocx.sh/golang/go` | `BSD-3-Clause` |

Each upstream release is discovered, re-bundled, smoke-tested per
`(version, platform)` and only then pushed with cascade tags, after which the
result is announced into the OCX index.

Go publishes **no binaries via GitHub Releases** — golang/go carries tags but
no release assets. The canonical download index lives at
`https://go.dev/dl/?mode=json&include=all`, so this mirror runs a small
[`go/scripts/generate.py`](go/scripts/generate.py) that emits a `url_index`
JSON document. The script uses
[`ocx-mirror-sdk`](https://pypi.org/project/ocx-mirror-sdk/) from PyPI, pinned
to a floating patch via PEP 723 inline metadata, and runs under the `uv`
pinned in [`ocx.toml`](ocx.toml).

## Layout

```
mirror-base.yml         repo-wide policy every spec inherits via `extends:`
go/
├── mirror.yml          the spec — never at the repo root
├── metadata.json       bundle interface
├── CATALOG.md          → ocx package describe
├── logo.svg / logo.png describe assets, 512px PNG
├── scripts/generate.py the url_index generator
└── tests/smoke.star    Starlark smoke test
```

`LICENSE` and `NOTICE.md` are shared at the root. Logos are **not** — each
package carries its own, because a repo-root `logo.*` sits in no workflow's
`paths:` filter, so replacing it would publish nothing until some unrelated
edit happened to fire. The generator lives under `go/` for the same reason:
that is what the mirror workflow's `go/**` path trigger watches.

⚠️ `extends:` is a **shallow** merge of top-level keys. A spec that restates
`platforms:` to change one runner drops every `containers:` entry with it, and
nothing reds — the legs simply stop existing, and every `os.features` claim
goes back to being asserted rather than verified. Restate a block in full or
not at all.

## Platforms

`go` publishes six platform entries: both Linux arches, both macOS arches and
both Windows arches. Go links its Linux release binaries **statically** —
byte-measured on `go` and `gofmt` from both Linux tarballs, none of the four
ELFs carries a `PT_INTERP`, and upstream publishes no musl/glibc split to
choose between. `os.features` states what an artifact requires *of the host*,
so both Linux keys are **bare**: tagging them `+libc.musl` would be a false
requirement that hid them from every glibc host. The `alpine:3.20` container
leg in `mirror-base.yml` is what turns that claim into evidence; the
measurement itself is recorded above the `assets:` block in
[`go/mirror.yml`](go/mirror.yml).

Filenames are uniform across the whole range (`go<ver>.<os>-<arch>.tar.gz` /
`.zip`). The version floor is `1.24.0` — one minor line beyond upstream's two
supported release lines; all 33 in-range versions carry all six published
platforms (windows/arm64 ships since go1.17).

## Editing

| File | Edit | Regenerate after |
|------|------|------------------|
| `mirror-base.yml`, `go/mirror.yml` | hand | yes — see below |
| `go/{metadata.json,CATALOG.md,logo.*}` | hand | — |
| `go/scripts/generate.py` | hand | — |
| `go/tests/smoke.star` | hand | — |
| `.github/workflows/*.yml` | **generated — never hand-edit** | re-run when a spec changes |

```bash
ocx-mirror package pipeline generate ci --spec go/mirror.yml
```

**Name every spec.** `--spec` *appends* rather than replaces, so a command
naming a subset silently stops rendering the rest while staying green — and the
drift guard reds on a generated workflow the current spec set no longer
produces.

`verify-generated.yml` exits 65 on drift. If a generated workflow is wrong, the
spec or the renderer template is wrong — fix it there and regenerate.

Run `direnv allow` once to put the pinned toolchain on `PATH`, and invoke
`ocx-mirror` directly — never `ocx run -- ocx-mirror`, which pins
`OCX_BINARY_PIN` to the bootstrap `ocx` and false-reds the nested push.

## The binaries claim

Every archive puts `go` and `gofmt` in `bin/` — identical on all six platforms
and at both ends of the version range — so `go/metadata.json` hand-lists
`binaries: ["go", "gofmt"]` and the spec sets `bin_scan: verify`, which turns
the list into a regression test: an upstream archive rearrangement reds the
run instead of drifting silently.

## Required secrets

| Secret | Use |
|--------|-----|
| `OCX_ANNOUNCE_TOKEN` | opens the index pull request from the `ocx-contrib/index` fork |
| `OCX_MIRROR_DISCORD_HOOK` | notify-stage Discord webhook URL |

(Inherited from the `ocx-contrib` org with visibility ALL. GHCR pushes use the
run's own `GITHUB_TOKEN` — no registry secret needed.)

## License

Apache-2.0 — see [`LICENSE`](LICENSE). Upstream assets are out of scope; each
package's redistribution license is recorded in [`NOTICE.md`](NOTICE.md).
