package crossj.cj;

public interface CJIRLocalVariableDeclaration {
    boolean isMutable();
    CJMark getMark();
    String getName();
    CJIRType getVariableType();
}
