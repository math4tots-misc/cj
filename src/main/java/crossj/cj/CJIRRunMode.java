package crossj.cj;

public abstract class CJIRRunMode {
    public abstract <R, A> R accept(CJIRRunModeVisitor<R, A> visitor, A a);
}
