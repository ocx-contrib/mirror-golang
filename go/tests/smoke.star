# go/tests/smoke.star — stable across upstream Go releases.
# Asserts behavior/contract (exit codes, version digits, a real
# compile-and-run, env-var honoring), never upstream-controlled prose.
GO = "go.exe" if ocx.target_platform.os == ocx.os.Windows else "go"
GOFMT = "gofmt.exe" if ocx.target_platform.os == ocx.os.Windows else "gofmt"

# Tier 1 + 2: liveness on the composed PATH + version SHAPE.
# `go version` prints e.g. "go version go1.26.5 linux/amd64" to stdout.
r_version = ocx.run(GO, "version")
expect.ok(r_version)
expect.matches(r_version.stdout, r"go\d+\.\d+\.\d+")

# Tier 4 wiring (set up first; reused by the Tier-3 run below).
# Go refuses to build without a cache location, so point GOCACHE (and HOME —
# GOPATH and the env-config dir derive from it; USERPROFILE is its Windows
# spelling) at scratch. GOTOOLCHAIN=local pins the toolchain under test —
# 1.24+ would otherwise honor a toolchain directive and swap itself out.
# GOPROXY=off and CGO_ENABLED=0 make the compile hermetic: no module fetches,
# no host C toolchain — the container legs ship no gcc, and the stdlib-only
# program below needs none. `gocache` is left for go to CREATE — its
# appearance proves the env var was honored.
ocx.mkdir("home")
cache = ocx.scratch_root + "/gocache"
home = ocx.scratch_root + "/home"
go_env = {
    "GOCACHE": cache,
    "HOME": home,
    "USERPROFILE": home,
    "GOTOOLCHAIN": "local",
    "GOPROXY": "off",
    "CGO_ENABLED": "0",
}
expect.false(ocx.exists("gocache"))  # absent before the compile

# Tier 3: functional behavior on hermetic input — compile AND EXECUTE a real
# program, then assert on what it COMPUTED. `import "fmt"` only resolves if
# the bundle's src/ stdlib tree shipped alongside the binary and go found its
# GOROOT relative to its own executable, so a passing run proves the archive
# is whole, not merely that the compiler starts. The token embeds the sum of
# i² for i in 0..6 (0+1+4+9+16+25+36 = 91), computed at runtime — an echoed
# literal could not produce it.
ocx.write_file("hello.go", """
package main

import "fmt"

func main() {
    sum := 0
    for i := 0; i < 7; i++ {
        sum += i * i
    }
    fmt.Printf("ocx-go-smoke-%d\\n", sum)
}
""")
r_run = ocx.run(GO, "run", "hello.go", env=go_env)
expect.ok(r_run)
expect.contains(r_run.stdout, "ocx-go-smoke-91")

# Tier 4: behavioral honoring — the build above was told to cache under the
# scratch dir via GOCACHE. Go creates the cache directory (with its `trim.txt`
# bookkeeping) on any successful build, so its presence proves the binary read
# and honored the env var rather than falling back to the real user cache.
expect.true(ocx.exists("gocache"))

# gofmt: the second interface binary, on hermetic input — assert the computed
# formatting result, not prose. gofmt collapses the spaced-out header to
# canonical form and prints to stdout.
ocx.write_file("messy.go", "package main\n\nfunc   main()   {}\n")
r_fmt = ocx.run(GOFMT, "messy.go")
expect.ok(r_fmt)
expect.contains(r_fmt.stdout, "func main() {}")
