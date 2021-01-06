package crossj.cj;

public final class CJIRRunModeTest extends CJIRRunMode {
    @Override
    public <R, A> R accept(CJIRRunModeVisitor<R, A> visitor, A a) {
        return visitor.visitTest(this, a);
    }
}
