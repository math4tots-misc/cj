package crossj.cj;

public abstract class CJIRRunModeVisitor<R, A> {
    public abstract R visitMain(CJIRRunModeMain m, A a);
}
