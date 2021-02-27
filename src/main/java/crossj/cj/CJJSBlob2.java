package crossj.cj;

import crossj.base.Func1;
import crossj.base.Optional;

public final class CJJSBlob2 {
    private final Optional<Func1<Void, CJJSSink>> prep;
    private final Func1<Void, CJJSSink> main;
    private final boolean pure;

    static CJJSBlob2 simple(Func1<Void, CJJSSink> main) {
        return new CJJSBlob2(Optional.empty(), main, false);
    }

    static CJJSBlob2 simplestr(String js) {
        return new CJJSBlob2(Optional.empty(), out -> {
            out.append(js);
            return null;
        }, false);
    }

    static CJJSBlob2 pure(String js) {
        return new CJJSBlob2(Optional.empty(), out -> {
            out.append(js);
            return null;
        }, true);
    }

    static CJJSBlob2 markedPure(String js, CJMark mark) {
        return new CJJSBlob2(Optional.empty(), out -> {
            out.addMark(mark);
            out.append(js);
            return null;
        }, true);
    }

    static CJJSBlob2 withPrep(Func1<Void, CJJSSink> prep, Func1<Void, CJJSSink> main, boolean pure) {
        return new CJJSBlob2(Optional.of(prep), main, pure);
    }

    public Optional<Func1<Void, CJJSSink>> getPrep() {
        return prep;
    }

    public Func1<Void, CJJSSink> getMain() {
        return main;
    }

    public CJJSBlob2(Optional<Func1<Void, CJJSSink>> prep, Func1<Void, CJJSSink> main, boolean pure) {
        this.prep = prep;
        this.main = main;
        this.pure = pure;
    }

    void emitPrep(CJJSSink out) {
        if (prep.isPresent()) {
            prep.get().apply(out);
        }
    }

    void emitMain(CJJSSink out) {
        main.apply(out);
    }

    void emitDrop(CJJSSink out) {
        emitPrep(out);
        if (!pure) {
            emitMain(out);
            out.append(";\n");
        }
    }

    void emitSet(CJJSSink out, String target) {
        emitPrep(out);
        out.append(target);
        emitMain(out);
        out.append(";\n");
    }

    /**
     * Indicates whether the given blob has no prep
     */
    boolean isSimple() {
        return prep.isEmpty();
    }

    /**
     * Indicates whether the blob's associated expression has any side effects.
     */
    boolean isPure() {
        return pure;
    }

    boolean isSimpleAndPure() {
        return isSimple() && isPure();
    }

    CJJSBlob2 toPure(CJJSContext ctx) {
        if (pure) {
            return this;
        } else {
            var tmpvar = ctx.newTempVarName();
            return new CJJSBlob2(Optional.of(out -> {
                if (prep.isPresent()) {
                    prep.get().apply(out);
                }
                out.append("const " + tmpvar + "=");
                main.apply(out);
                out.append(";\n");
                return null;
            }), out -> {
                out.append(tmpvar);
                return null;
            }, true);
        }
    }
}
