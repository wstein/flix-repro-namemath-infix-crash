# flix-template

[![Build and Test](https://github.com/wstein/flix-template/actions/workflows/build-and-test.yaml/badge.svg)](https://github.com/wstein/flix-template/actions/workflows/build-and-test.yaml)
[![Flix](https://img.shields.io/badge/dynamic/toml?url=https%3A%2F%2Fraw.githubusercontent.com%2Fwstein%2Fflix-template%2Fmain%2F.flixw%2Flock.toml&query=%24.compiler.version&label=flix&color=blue)](.flixw/lock.toml)
[![flixw](https://img.shields.io/badge/dynamic/toml?url=https%3A%2F%2Fraw.githubusercontent.com%2Fwstein%2Fflix-template%2Fmain%2F.flixw%2Flock.toml&query=%24.wrapperVersion&label=flixw&color=blue)](https://github.com/wstein/flixw)
[![Java](https://img.shields.io/badge/java-21%2B-blue)](https://adoptium.net/temurin/releases/?version=21)
[![License](https://img.shields.io/github/license/wstein/flix-template?color=blue)](LICENSE)

A GitHub template for starting a [Flix](https://flix.dev) project, and a
worked example of [`flixw`](https://github.com/wstein/flixw) — a
repository-local bootstrap that fetches the compiler the project pins instead
of relying on whatever `flix` happens to be installed.

## Quick start

Click **Use this template**, clone your copy, and run it:

```sh
./flixw run          # .\flixw.cmd run on Windows
```

The only prerequisite is a JDK, Java 21 or newer. You do not need Flix
installed: the first command downloads `flix.jar` for the version pinned in
`.flixw/lock.toml`, checks it against the SHA-256 committed alongside it, caches
it outside the repository, and runs it. Later commands reuse the cache.

Run everything through the wrapper: `flix` is not expected to be on `PATH`,
and a `flix` that is may be a different version than this project pins. On
Windows use `.\flixw.cmd` wherever these say `./flixw`.

```sh
./flixw check        # type-check without generating code; the fast feedback loop
./flixw test         # run every @Test function under test/
./flixw build        # compile to build/class
./flixw doc          # write API documentation to build/doc/
./flixw format       # reformat sources in place
```

The wrapper adds verbs of its own, ahead of the compiler's:

```sh
./flixw validate     # the wrapper's own consistency checks; what CI runs first
./flixw doctor       # validate, plus the full picture, for bug reports (--fix repairs)
./flixw info         # project, compiler, java, and cache state
./flixw pin <version> # move to another compiler and rewrite the lock
./flixw local add <path> # override a declared GitHub dependency with a local checkout
./flixw local <verb> # run/check/build/test against local dependency overrides
./flixw examples <verb> <name> # run/check/build/test an isolated example in examples/<name>
```

## What is in here

```
.
├── src/
│   └── Main.flix                 mod Hello, and the main that prints its greeting
├── test/
│   └── TestMain.flix             @Test functions covering Hello.greeting
├── .flixw/
│   ├── flixw.java                the wrapper proper — one dependency-free Java file
│   └── lock.toml                 exact compiler and plugin versions and SHA-256 digests
├── .github/
│   ├── workflows/
│   │   ├── build-and-test.yaml   validate, check and test, on three platforms
│   │   ├── update-flix.yaml      weekly: re-pin the compiler, open a pull request
│   │   └── docs.yaml             build the API docs, publish them to Pages
│   └── dependabot.yml            keeps the workflows' pinned action digests current
├── flix.toml                     package metadata and the lowest Flix version accepted
├── flixw                         the POSIX shim
├── flixw.cmd                     the cmd.exe trampoline
├── AGENTS.md                     instructions for coding agents; CLAUDE.md and
│                                 .github/copilot-instructions.md point at it
└── LICENSE                       Apache-2.0, with the copyright line to replace
```

`flix.toml` states a *floor* and `.flixw/lock.toml` states the *pin*. They are
allowed to differ — any pin at or above the floor satisfies it — but
`./flixw validate` fails when the pin does not, so the two cannot drift apart
unnoticed.

## Naming what you add

A module has one declaration site in the whole program, dependencies included:
two packages that both declare `mod Cube` cannot be used together. What Flix
libraries do:

- one root namespace, named after the package: `flix-json` roots at `Json`,
  `flix-basicdb` at `BasicDB`
- directories mirror module paths: `Json.FromJson` lives in
  `src/Json/FromJson.flix`
- two or three levels; `Internal` for what is not API
- modules named for what you do there: `Json.Parse` holds `parse`
- names spelled out, and tests flat: one `TestX` per subject
- a library deletes `src/Main.flix`: Flix allows one `main` per program, so a
  package that ships one cannot be depended on

## What the wrapper is and is not

`flixw` never patches, forks or links against the Flix compiler. It fetches the
stock `flix.jar` by URL, verifies the digest before every use, and runs it as an
opaque process. Moving to another compiler is `./flixw pin <version>`, which
rewrites the lock; updating the wrapper itself is
`./flixw wrapper --upgrade`.

Two things are worth knowing before you adopt it. `flixw` is upstream-described
as experimental, and it is code your project executes on every build — which is
why it is committed in full and pinned by version and digest rather than curled
at run time. Read `.flixw/flixw.java` if that matters to you; it is deliberately
one file.

## Code metrics for contributors

[`flixw-metrics`](https://github.com/wstein/flixw-metrics) is a `flixw` plugin
that reports compiler-backed structure, rankings, and code-quality findings.
Besides line length, complexity, nesting, coupling, and documentation coverage,
it retains effect surfaces, handler shape, effect declarations and instantiated
effect arguments as typed context. Context-only measurements are not findings
and should not be treated as automatic refactoring instructions.

The repository declares the exact metrics version, artifact digest, command,
and source in `.flixw/lock.toml`. Plugin bytes live in a machine-wide cache and
are never fetched implicitly: run this once on each machine. If the declared
build is missing, `./flixw metrics` prints the same pinned command.

```console
./flixw plugin install metrics 0.3.0 \
  https://github.com/wstein/flixw-metrics/releases/download/v0.3.0/plugin.jar \
  --sha256 a8f961815bd6ecdd3c27d19eb1b1763f85207b7bf86265014ffc84529d96582e
```

```sh
./flixw metrics report --format md
./flixw metrics report --format json --view findings --severity warning
```

It is third-party, unaffiliated code that runs as you — see
[flixw-metrics' own Safety section](https://github.com/wstein/flixw-metrics#safety)
before installing anything. `AGENTS.md` asks agents to run the Markdown report
before every commit and recommends compact JSON views to avoid wasting model
context on data unrelated to the current task.

For an established project, `./flixw metrics init` creates a reviewed policy
and baseline, then prints a `--fail-on-new warning` command suitable for CI.
This template does not pre-create those project-specific policy files: their
thresholds and baseline should describe the codebase made from the template,
not the greeting example.

## Working with coding agents

`AGENTS.md` is the single instruction source used by Codex, Claude, and GitHub
Copilot. It requires test-driven changes, wrapper-only commands, compact metrics
views for machine consumption, and current Flix syntax. Its language guidance
tracks the official [Flix page for LLMs](https://doc.flix.dev/for-llms.html):
consult [api.flix.dev](https://api.flix.dev) instead of inspecting `flix.jar`,
prefer `Util.Json`, model side effects with effects and handlers, keep companions
inside their modules, and avoid obsolete Java-interop and Datalog syntax.

## Continuous integration

`.github/workflows/build-and-test.yaml` runs `validate`, `check` and `test`
through the wrapper on Linux, macOS and Windows — the Windows leg exercises
`flixw.cmd`, the others the POSIX shim. It installs a JDK and nothing else,
which is the same starting position a new contributor is in. The compiler is
restored from the runner cache, keyed on `.flixw/lock.toml`, and its digest is
re-verified whether it came from the cache or the network. Actions are pinned to
commit digests and kept current by Dependabot.

There is no formatting gate: the pinned compiler's `format` has no check-only
mode, so run `./flixw format` before you commit.

`.github/workflows/update-flix.yaml` runs weekly. Dependabot has no ecosystem
for a compiler pinned by URL and digest, so this is its counterpart: it resolves
the newest `flix/flix` release, re-pins, runs `validate`, `check` and `test`,
and opens a pull request if all three pass. It never pushes to the default
branch — the digest in a re-pinned lock is computed by the runner, and that is
the thing worth reading before merging.

`.github/workflows/docs.yaml` runs `./flixw doc` on every push to `main` and
publishes this project's own pages to GitHub Pages — for this repository, at
<https://wstein.github.io/flix-template/>.

`flix doc` renders the whole standard library alongside the project and has no
option to narrow that: `--Xlib` decides what is *compiled*, and without the
library nothing compiles at all. Its `index.html` is the stdlib's `Prelude`
page. So the workflow picks out the project's pages afterwards — by which ones
carry a source link into the workspace, which no library page does — writes its
own landing page listing them, and refuses to publish at all if that finds
nothing. A link check then fails the build if anything published points at a
page that was not.

One upstream quirk is worked around there too. `flix doc` builds each `Source`
link by appending the documented file's path to the standard library's own base
URL on `flix/flix`, which for this project's files yields a 404 with the build
machine's absolute path inside it. The workflow rewrites those into permalinks
at the published commit, and fails if any filesystem path survives.

Pages has to be enabled once, under **Settings → Pages** with source
**GitHub Actions**: the default `GITHUB_TOKEN` cannot create a Pages site even
with `pages: write`. Until it is, the documentation is still built and the run
warns rather than failing, so a fresh copy of this template does not start red.

## After you template this

1. `flix.toml` — set `name`, `description`, `version` and `authors`. The package
   name is yours to choose; nothing requires it to match the repository name.
2. `LICENSE` — replace the copyright line, or the whole license.
3. `src/` and `test/` — replace the greeting with your own code, minding
   [Naming what you add](#naming-what-you-add).
4. This README — the badge URLs and the documentation link. Until you point
   them at your own repository they report this one's state, not yours. CI
   fails on the first push until you do, and names every URL still pointing
   here.
5. **Settings → Pages**, source **GitHub Actions**, if you want the published
   documentation. Skip it and `docs.yaml` just warns.

The Flix and `flixw` badges read `.flixw/lock.toml` directly, so re-pinning with
`./flixw pin <version>` updates them without touching this file.

## License

Apache-2.0. See [LICENSE](LICENSE).
