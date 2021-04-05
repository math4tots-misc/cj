package crossj.cj;

public final class CJRunModeTest extends CJRunMode {
    private final boolean runSlowTests;

    @Override
    public <R, A> R accept(CJRunModeVisitor<R, A> visitor, A a) {
        return visitor.visitTest(this, a);
    }

    public boolean slowTestsEnabled() {
        return runSlowTests;
    }

    public CJRunModeTest(boolean runSlowTests) {
        this.runSlowTests = runSlowTests;
    }
}
