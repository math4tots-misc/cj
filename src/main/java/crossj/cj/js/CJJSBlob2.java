package crossj.cj.js;

import java.util.function.Consumer;

import crossj.base.Func0;
import crossj.base.Optional;
import crossj.cj.CJJSSink;

public final class CJJSBlob2 {
    private final Optional<Consumer<CJJSSink>> prep;
    private final Consumer<CJJSSink> body;
    private final boolean pure;

    public static CJJSBlob2 pure(String expr) {
        return simplestr(expr, true);
    }

    public static CJJSBlob2 simple(Consumer<CJJSSink> body, boolean pure) {
        return new CJJSBlob2(Optional.empty(), body, pure);
    }

    public static CJJSBlob2 simplestr(String expr, boolean pure) {
        return simple(out -> out.append(expr), pure);
    }

    public static CJJSBlob2 withPrep(Consumer<CJJSSink> prep, Consumer<CJJSSink> body, boolean pure) {
        return new CJJSBlob2(Optional.of(prep), body, pure);
    }

    public static CJJSBlob2 unit(Consumer<CJJSSink> prep) {
        return withPrep(prep, out -> out.append("undefined"), true);
    }

    public CJJSBlob2(Optional<Consumer<CJJSSink>> prep, Consumer<CJJSSink> body, boolean pure) {
        this.prep = prep;
        this.body = body;
        this.pure = pure;
    }

    public Optional<Consumer<CJJSSink>> getPrep() {
        return prep;
    }

    public Consumer<CJJSSink> getBody() {
        return body;
    }

    public boolean isPure() {
        return pure;
    }

    public boolean isSimple() {
        return prep.isEmpty();
    }

    public boolean isPureAndSimple() {
        return isPure() && isSimple();
    }

    public CJJSBlob2 toPure(Func0<String> newTempVar) {
        if (pure) {
            return this;
        } else {
            var tempvar = newTempVar.apply();
            return withPrep(out -> {
                emitPrep(out);
                out.append("const " + tempvar + "=");
                body.accept(out);
                out.append(";");
            }, out -> out.append(tempvar), true);
        }
    }

    public void emitPrep(CJJSSink out) {
        if (prep.isPresent()) {
            prep.get().accept(out);
        }
    }

    public void emitBody(CJJSSink out) {
        body.accept(out);
    }

    public void emitDrop(CJJSSink out) {
        emitPrep(out);
        if (!pure) {
            emitBody(out);
            out.append(";");
        }
    }

    public void emitSet(CJJSSink out, String target) {
        emitPrep(out);
        out.append(target);
        emitBody(out);
        out.append(";");
    }
}
