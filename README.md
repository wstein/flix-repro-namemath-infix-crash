# flix-repro-namemath-infix-crash

Minimal reproduction: **the Flix compiler crashes with an `InternalCompilerException` when a
user-defined operator whose name is a math symbol is applied infix.**

Built from [`wstein/flix-template`](https://github.com/wstein/flix-template), so it carries the
compiler it pins. A clone needs only a JDK.

```sh
./flixw run          # .\flixw.cmd run on Windows
```

Pinned to Flix **v0.77.0** (`.flixw/lock.toml`, digest-verified).

## What happens

```
#
# An unexpected error has been detected by the Flix compiler:
#
#   Expr.Binary operator not recognized (src/Main.flix:38:13)
#
# This is a bug in the Flix compiler. Please report it here:
#
# https://github.com/flix/flix/issues
#
```

## The control

`src/Main.flix` applies the operator **infix**. `test/TestMain.flix` applies the *same* definition
to the *same* arguments **prefix**, and that is accepted by every phase. Rewrite the call in
`src/Main.flix` as `Sets.⊆(true, false)` and the project compiles, runs and passes its tests.

The difference is the infix path alone.

## Why it happens

Nothing in the program is malformed — which is what separates this from
[flix/flix#13320](https://github.com/flix/flix/issues/13320), where the parser had already reported
an error and `Weeder2` merely failed to recover from it.

`Parser2` has a dedicated binary operator for math-symbol names:

- `peekBinaryOp` maps `TokenKind.NameMath` to `BinaryOp.NameMath` — `Parser2.scala:1675`
- `NameMath` is a member of `FIRST_BINARY_OP` — `Parser2.scala:1703`
- it carries its own precedence, alongside `BinaryOp.UserDefinedOperator`

So `true ⊆ false` parses cleanly into `Expr.Binary`, with the symbol closed as `Operator`.

`Weeder2.visitBinaryExpr` then matches the operator token against a fixed set — the keyword
operators, the literal cases, `ColonColon`, `ColonColonTight`, `Tick` and `GenericOperator`
(`Weeder2.scala:1244`) — which does not include `NameMath`, and falls through to:

```scala
case _ =>
  throw InternalCompilerException(s"Expr.Binary operator not recognized", tree.loc)
```

— `Weeder2.scala:1248`.

The two phases disagree about whether `NameMath` is an operator.

## Is infix use of a math name documented?

No — and that is probably why it has gone unnoticed.

[`identifiers.html`](https://doc.flix.dev/identifiers.html) defines a **math name** as "an
identifier consisting of any combination of math symbols (the unicode range U+2190 to U+22FF)",
offers `⊆`, `√` and `⊙` as its examples, and says math names may name functions and variables. It
says nothing about infix.

[`functions.html`](https://doc.flix.dev/functions.html) documents infix for the *other* category
only: "a function named with an **operator name** (some combination of `+`, `-`, `*`, `<`, `>`,
`=`, `!`, `&`, `|`, `^`, and `$`) can also be used infix", plus the backtick form. Math names are
not mentioned.

So this is not a documented feature that regressed. The case for it being intended rests on the
implementation, where it is unambiguous: a dedicated `BinaryOp.NameMath` (`Parser2.scala:1675`),
membership in `FIRST_BINARY_OP` (`Parser2.scala:1703`), and its own precedence — level 11, the
tightest binary level, shared with `BinaryOp.UserDefinedOperator` (`Parser2.scala:1765`).

It is also unexercised upstream: no math-symbol function is defined anywhere in `main/src/library`
or `main/test`, and no infix use of one appears outside pseudo-code in doc comments. That is the
survival explanation.

Either resolution is fine — support it in `Weeder2`, or reject it in `Parser2` with a real
diagnostic. What should not persist is a dedicated parser path ending in an
`InternalCompilerException`.

## Relation to #13320 / #13326

[#13326](https://github.com/flix/flix/pull/13326) fixed the same exception for a *different*
trigger, a keyword used as an infix function name, by adding a `Tick` case to this match. That
merge commit is an ancestor of the v0.77.0 tag this repository pins, so the fix is present and this
path survives it: it added one case and did not touch `NameMath`.

## Provenance

Found by [`flix-spec`](https://github.com/wstein/flix-spec), which runs `Weeder2` over its own
positive fixtures as an advisory check. Recorded there as `FLIX-0002` in `defects/ledger.json`,
with a declarative assertion that fails once upstream stops crashing.
