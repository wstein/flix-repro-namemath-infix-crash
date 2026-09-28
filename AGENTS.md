# Working on this project

A Flix project that carries its own compiler. `./flixw` downloads the exact
`flix.jar` pinned in `.flixw/lock.toml`, verifies it against a committed
SHA-256, and runs it. Nothing needs installing but a JDK — 21 or newer.

## Commands

Run everything through the wrapper: `flix` is not expected to be on `PATH`, and
a `flix` that is may be a different version than this project pins. On Windows
use `.\flixw.cmd` wherever these say `./flixw`.

- `./flixw check` — type-check without generating code; the fast feedback loop
- `./flixw test` — run every `@Test` function under `test/`
- `./flixw run` — run `main`
- `./flixw build` — compile to `build/class`
- `./flixw format` — reformat sources in place; the pinned compiler has no
  check-only mode, so CI does not gate on formatting
- `./flixw doc` — write API documentation for the standard library and this
  project to `build/doc/`
- `./flixw metrics report --format md` — review-ready code metrics and findings
- `./flixw metrics report --format json --view findings --severity warning` —
  compact, actionable input for an agent; use `--view summary` for a quick
  project snapshot

Run metrics after tests and before every commit. Fix genuine findings or document
why they are intentional; do not mechanically optimize rankings or contextual
handler/effect facts, which are measurements rather than policy. The exact plugin
version and digest are declared in `.flixw/lock.toml`. Installation is still
per-machine; if it is missing, `./flixw metrics` prints the pinned install command.

The wrapper adds verbs of its own, ahead of the compiler's:

- `./flixw validate` — the wrapper's own consistency checks, for CI
- `./flixw doctor` — those checks plus the full picture, for bug reports (`--fix` to repair)
- `./flixw pin <version>` — move to another compiler and rewrite the lock
- `./flixw info` — view project, compiler, Java, and cache state
- `./flixw local add <path>` / `./flixw local <verb>` — override declared GitHub dependencies with local checkouts for testing and development
- `./flixw examples <verb> <name>` — run, check, build, or test an isolated package in `examples/<name>`

## Layout

- `src/` — sources; `src/Main.flix` holds `main`
- `test/` — `@Test` functions
- `flix.toml` — package metadata, dependencies, and the *lowest* Flix version
  this project accepts
- `.flixw/lock.toml` — the exact compiler and its digest. `flix.toml` states a
  floor; this states the pin. Both are committed, and `validate` fails when
  they disagree
- `flixw`, `flixw.cmd`, `.flixw/flixw.java` — the wrapper itself. Generated;
  change it with `./flixw wrapper --upgrade`, never by hand
- `.github/workflows/` — `build-and-test.yaml` on three platforms,
  `update-flix.yaml` weekly, `docs.yaml` for the API documentation. All three
  drive the wrapper; none of them install Flix
- `build/`, `artifact/`, `lib/` — generated; do not edit and do not commit

`CLAUDE.md` and `.github/copilot-instructions.md` both point at this file
rather than repeating it, so that each tool finds the same instructions under
the name it looks for.

## Test-driven development (TDD)

Always follow a test-driven development workflow (Red-Green-Refactor):

1. **Red**: Write a failing test under `test/` first before adding or modifying code in `src/`. Run `./flixw test` to confirm it fails for the expected reason.
2. **Green**: Write the minimal implementation in `src/` to make the test pass. Run `./flixw test` to confirm it passes.
3. **Refactor**: Clean up the design while keeping all tests passing. Run
   `./flixw format` and `./flixw metrics report --format md` before committing.

Never write production code without a failing test first. Every bug fix must begin with a test reproducing the bug.

## Commits

Make commits atomic and focused: each commit should contain one coherent change
that can be reviewed and reverted independently. Keep its tests and implementation
together, and do not mix unrelated refactors, formatting, or cleanup into the same
commit. Before committing, run the relevant tests and the required metrics command.

Use Conventional Commits for commit messages, with an imperative, concise subject:
`<type>(<optional-scope>): <description>`. Prefer standard types such as `feat`,
`fix`, `test`, `refactor`, `docs`, `build`, and `ci`. Mark breaking changes with
`!` or a `BREAKING CHANGE:` footer.

## Writing Flix

Your training data is probably older than this compiler. Before writing Flix,
read the official [Flix guidance for LLMs](https://doc.flix.dev/for-llms.html)
and prefer the current book over research papers, talks, and old examples. Use
[api.flix.dev](https://api.flix.dev) for standard-library modules, types,
functions, and signatures. Do not unpack, decompile, or grep `flix.jar` to guess
at APIs. `./flixw doc` remains useful for this project's generated API pages.

The mistakes that show up most often:

- `def main(): Unit \ IO = ...` — arguments come from `Env.getArgs()`, not from
  parameters
- use built-in `Util.Json`, not the third-party `flix-json` package
- effects are written with `\`, not `&`
- effect operations are called like ordinary functions; there is no `do` keyword
- handlers are `run { ... } with handler E { ... }`; chain them rather than
  nesting `run`
- prefer standard-library effects and handle them near `main`; do not simulate
  effects with callback-based CPS
- annotations are uppercase: `@Test`, `@Lazy`, `@Parallel`, `@MustUse`
- companion enums, structs, effects, and traits go first inside their module
- Datalog `inject` names predicate arity (`Edge/2`); predicate symbols are
  inferred, so do not write old `rel` or `lat` declarations
- Java types need a top-level `import`; Java interop carries `IO`, and `unsafe`
  is only for calls known to be pure

Prefer effects and handlers to callbacks or hand-written CPS, and standard
library effects to Java interop.

## Naming modules

A module has one declaration site in the whole program, dependencies included,
so never take a common top-level name.

- one root namespace per package, named after it: `flix-json` roots at `Json`
- directories mirror module paths: `Json.FromJson` in `src/Json/FromJson.flix`
- two or three levels; `Internal` for what is not API
- name a module for what is done there: `Json.Parse` holds `parse`
- spell names out; tests flat, one `TestX` per subject
- a library deletes `src/Main.flix`: one `main` per program, so a package that
  ships one cannot be depended on
