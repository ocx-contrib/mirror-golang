# /// script
# requires-python = ">=3.13"
# dependencies = ["ocx-mirror-sdk~=0.6.0"]
# ///
# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 The OCX Authors

"""Generate url_index JSON for Go releases.

Go publishes its binaries on go.dev/dl, not GitHub Releases (golang/go carries
tags but no release assets). The canonical download index is
`https://go.dev/dl/?mode=json&include=all`, shaped as:

    [
      {
        "version": "go1.26.5",         # also "go1.27rc2", "go1.9.2rc2", "go1.9"
        "stable": true,
        "files": [
          {"filename": "go1.26.5.linux-amd64.tar.gz", "os": "linux",
           "arch": "amd64", "kind": "archive", "sha256": "...", "size": ...},
          ...
        ]
      },
      ...
    ]

Only entries whose version is a full `go<maj>.<min>.<patch>` are emitted — the
regex drops rc/beta tags (`go1.27rc2`) and the pre-1.21 two-part versions
(`go1.20`), all of which sit below the mirror's floor anyway. `kind` filters
out the `installer`/`source` files; the os/arch set keeps the six platforms the
mirror publishes out of upstream's ~40 per release.

Download URLs are constructed against dl.google.com/go/ — the CDN every
go.dev/dl link resolves to, with no redirect in between.
"""

import re

from ocx_mirror_sdk import IndexBuilder
from ocx_mirror_sdk.http import fetch_json

INDEX_URL = "https://go.dev/dl/?mode=json&include=all"
DOWNLOAD_BASE = "https://dl.google.com/go/"

VERSION_RE = re.compile(r"^go(?P<version>\d+\.\d+\.\d+)$")

# (os, arch) pairs as the go.dev index spells them -> the six OCX platforms.
PLATFORMS = {
    ("linux", "amd64"),
    ("linux", "arm64"),
    ("darwin", "amd64"),
    ("darwin", "arm64"),
    ("windows", "amd64"),
    ("windows", "arm64"),
}


def main() -> None:
    index = IndexBuilder()
    for entry in fetch_json(INDEX_URL):
        m = VERSION_RE.match(entry["version"])
        if not m:
            continue
        assets = {
            f["filename"]: DOWNLOAD_BASE + f["filename"]
            for f in entry["files"]
            if f["kind"] == "archive" and (f["os"], f["arch"]) in PLATFORMS
        }
        if assets:
            # Belt and braces: the regex already excludes rc/beta tags, and no
            # three-part version has ever been stable=false in the live index.
            index.add_version(
                m.group("version"), assets=assets, prerelease=not entry.get("stable", False)
            )
    index.emit()


if __name__ == "__main__":
    main()
