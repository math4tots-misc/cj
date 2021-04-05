package crossj.cj;

public abstract class CJRunMode {
    public abstract <R, A> R accept(CJRunModeVisitor<R, A> visitor, A a);
}
