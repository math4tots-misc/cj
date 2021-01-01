package crossj.cj;

public abstract class CJIRTypeVisitor<R, A> {
    public abstract R visitClass(CJIRClassType t, A a);
    public abstract R visitVariable(CJIRVariableType t, A a);
}
