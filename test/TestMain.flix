///
/// Prefix application is accepted by every phase.
///
/// This is the control: it is the same definition and the same arguments,
/// differing only in being applied prefix rather than infix. Replace the infix
/// call in `src/Main.flix` with the prefix form and this suite compiles and
/// passes; leave the infix call in and the compiler crashes before any test
/// runs.
///
mod TestMain {

    @Test
    def testSubsetPrefix(): Bool =
        Sets.⊆(true, false) == false

    @Test
    def testSubsetPrefixTrue(): Bool =
        Sets.⊆(false, true) == true

}
