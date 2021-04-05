package crossj.cj.ir;

import crossj.cj.CJMark;
import crossj.cj.ir.meta.CJIRType;

public interface CJIRLocalVariableDeclaration {
    boolean isMutable();
    CJMark getMark();
    String getName();
    CJIRType getVariableType();
}
