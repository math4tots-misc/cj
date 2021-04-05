package crossj.cj;

public final class CJRunModeMain extends CJRunMode {
    private final String mainClass;

    public CJRunModeMain(String mainClass) {
        this.mainClass = mainClass;
    }

    public String getMainClass() {
        return mainClass;
    }

    @Override
    public <R, A> R accept(CJRunModeVisitor<R, A> visitor, A a) {
        return visitor.visitMain(this, a);
    }
}
