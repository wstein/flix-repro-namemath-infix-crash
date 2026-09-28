///
/// Minimal reproduction: the compiler crashes with an `InternalCompilerException`
/// on a user-defined operator whose name is a math symbol, used infix.
///
/// Nothing here is malformed. `Parser2` has a dedicated binary operator for
/// math-symbol names: `peekBinaryOp` maps `TokenKind.NameMath` to
/// `BinaryOp.NameMath`, `NameMath` is a member of `FIRST_BINARY_OP`, and it
/// carries its own precedence. So `x ⊆ y` parses cleanly into `Expr.Binary`
/// with the symbol closed as `Operator`.
///
/// `Weeder2.visitBinaryExpr` then matches the operator token against a fixed
/// set which does not include `NameMath`, and falls through to
/// `throw InternalCompilerException("Expr.Binary operator not recognized")`.
///
/// The two phases disagree about whether `NameMath` is an operator.
///
mod Sets {

    ///
    /// Subset, written with the usual math symbol.
    ///
    /// The *declaration* is accepted by every phase. Flix allows math symbols
    /// as definition names, and nothing about this line is unusual.
    ///
    pub def ⊆(x: Bool, y: Bool): Bool = (not x) or y

}

///
/// The entry point.
///
/// The infix *call* is what crashes. Rewrite it as `Sets.⊆(true, false)` and
/// the whole project compiles and runs, which is what isolates the defect to
/// the infix path in `Weeder2.visitBinaryExpr`.
///
def main(): Unit \ IO =
    use Sets.⊆;
    println(true ⊆ false)
