# NOTICE

This repository packages and redistributes upstream software published by the
[Go project](https://go.dev) (Google LLC). The Apache-2.0 license in
[`LICENSE`](LICENSE) covers the OCX pipeline files authored here. It does
**not** cover any upstream-derived asset — each package's redistributed bytes
carry their own license, recorded below.

| Package | GHCR path | Upstream SPDX |
|---|---|---|
| `go` | `ghcr.io/ocx-contrib/golang/go` | `BSD-3-Clause` |

---

## `go`

Upstream: <https://go.dev> (source: <https://github.com/golang/go>)
Published to `ghcr.io/ocx-contrib/golang/go`.

| Component | SPDX | Holder |
|---|---|---|
| Go toolchain (`bin/go`, `bin/gofmt`, `src/`, `pkg/`, `lib/`) | **BSD-3-Clause** | Copyright 2009 The Go Authors |

Permissive; redistribution in binary form is granted provided the copyright
notice, the conditions list, and the disclaimer are reproduced. Upstream ships
its `LICENSE` file inside every release archive and it is republished
untouched as part of the bundle; the terms are those of
<https://github.com/golang/go/blob/master/LICENSE>. The distribution
additionally vendors third-party sources under their own permissive licenses,
enumerated in upstream's `PATENTS` file and per-directory `LICENSE` files.

The Go name and logo are trademarks of Google LLC, used for catalog
identification under nominative fair use. The logo shipped with this package
is the Go wordmark from the [go.dev brand assets](https://go.dev/blog/go-brand),
reproduced for catalog identification only. The marks remain the property of
their respective owners and no endorsement is implied.

No modifications are made to any upstream artifact in this repository; they
are republished byte-for-byte inside an OCX bundle.
