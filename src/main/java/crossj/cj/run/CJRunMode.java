package crossj.cj.run;

public abstract class CJRunMode {
    public abstract <R, A> R accept(CJRunModeVisitor<R, A> visitor, A a);
}
