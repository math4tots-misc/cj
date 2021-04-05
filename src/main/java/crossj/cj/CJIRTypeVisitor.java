package crossj.cj;

import crossj.cj.ir.meta.CJIRClassType;
import crossj.cj.ir.meta.CJIRSelfType;

public abstract class CJIRTypeVisitor<R, A> {
    public abstract R visitClass(CJIRClassType t, A a);
    public abstract R visitVariable(CJIRVariableType t, A a);
    public abstract R visitSelf(CJIRSelfType t, A a);
}
