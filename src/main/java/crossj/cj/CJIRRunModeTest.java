package crossj.cj;

public final class CJIRRunModeTest extends CJIRRunMode {
    private final boolean runSlowTests;

    @Override
    public <R, A> R accept(CJIRRunModeVisitor<R, A> visitor, A a) {
        return visitor.visitTest(this, a);
    }

    public boolean slowTestsEnabled() {
        return runSlowTests;
    }

    public CJIRRunModeTest(boolean runSlowTests) {
        this.runSlowTests = runSlowTests;
    }
}
