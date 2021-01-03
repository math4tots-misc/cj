package crossj.cj;

public final class CJIRRunModeMain extends CJIRRunMode {
    private final String mainClass;

    public CJIRRunModeMain(String mainClass) {
        this.mainClass = mainClass;
    }

    public String getMainClass() {
        return mainClass;
    }

    @Override
    public <R, A> R accept(CJIRRunModeVisitor<R, A> visitor, A a) {
        return visitor.visitMain(this, a);
    }
}
