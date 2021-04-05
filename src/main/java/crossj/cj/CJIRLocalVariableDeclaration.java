package crossj.cj;

import crossj.cj.ir.meta.CJIRType;

public interface CJIRLocalVariableDeclaration {
    boolean isMutable();
    CJMark getMark();
    String getName();
    CJIRType getVariableType();
}
